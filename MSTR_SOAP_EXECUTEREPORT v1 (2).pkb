CREATE OR REPLACE PACKAGE BODY          mstr_soap_executereport
AS
   PROCEDURE html (preportid IN VARCHAR2)
   IS
      l_clob                    CLOB;
      l_raw                     RAW (32767);
      http_request              UTL_HTTP.req;
      http_response             UTL_HTTP.resp;
      con_xml_result_starttag   CONSTANT VARCHAR2 (20) := '<ns2:ResultXML>';
      con_xml_result_endtag     CONSTANT VARCHAR2 (20) := '</ns2:ResultXML>';
      xml_report                XMLTYPE;
      v_clob                    CLOB;
      var_http_resp_value       VARCHAR2 (32767);
      soap_startp               NUMBER;
      soap_length               NUMBER;
   BEGIN
      soap_request :=
         XMLTYPE (
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://microstrategy.com/webservices/v1_0">
   <soapenv:Header>
   </soapenv:Header>
   <soapenv:Body>
      <v1:ExecuteReport>
         <!--Optional:-->
         <v1:cInfo>
            <!--Optional:-->
            <v1:Login>'
            || con_str_mstrwsj_user
            || '</v1:Login>
            <!--Optional:-->
            <v1:Password>'
            || con_str_mstrwsj_password
            || '</v1:Password>
            <!--Optional:-->
            <v1:ProjectName>'
            || con_str_mstrwsj_project
            || '</v1:ProjectName>
            <!--Optional:-->
            <v1:ProjectSource>'
            || con_str_mstrwsj_server
            || '</v1:ProjectSource>
            <!--Optional:-->
            <v1:AuthMode>MWSStandard</v1:AuthMode>
            <v1:HasHeuristics>false</v1:HasHeuristics>
            <v1:PortNumber>0</v1:PortNumber>
            <!--Optional:-->
            <v1:ClientIPAddress></v1:ClientIPAddress>
         </v1:cInfo>
         <!--Optional:-->
         <v1:sReportName></v1:sReportName>
         <!--Optional:-->
         <v1:sReportID>'
            || preportid
            || '</v1:sReportID>
         <!--Optional:-->
         <v1:sAnswerPrompt>
         </v1:sAnswerPrompt>
         <v1:eFlags>MWSUseDefaultPrompts</v1:eFlags>
         <!--Optional:-->
         <v1:ResultsWindow>
            <v1:MaxRows>1000</v1:MaxRows>
            <v1:MaxCols>100</v1:MaxCols>
            <v1:StartRow>0</v1:StartRow>
            <v1:StartCol>0</v1:StartCol>
            <v1:PopulatePageBy>true</v1:PopulatePageBy>
         </v1:ResultsWindow>
         <!--Optional:-->
         <v1:sStyle></v1:sStyle>
         <v1:eResults>MWSReturnAsXML</v1:eResults>
      </v1:ExecuteReport>
   </soapenv:Body>
</soapenv:Envelope>
');

      http_request := UTL_HTTP.begin_request (con_str_ws_url, con_http_ws_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (http_request, 'Content-Type', 'text/xml; charset=utf-8');
      UTL_HTTP.set_header (http_request, 'Content-Length', LENGTH (soap_request.getstringval ()));
      UTL_HTTP.set_header (http_request, 'SOAPAction', con_str_ws_action);
      UTL_HTTP.write_text (http_request, soap_request.getstringval ());
      http_response := UTL_HTTP.get_response (http_request);

      DBMS_LOB.createtemporary (l_clob, FALSE);

      BEGIN
         LOOP
            UTL_HTTP.read_raw (http_response, l_raw, 32767);
            DBMS_LOB.
            writeappend (l_clob,
                         LENGTH (UTL_RAW.cast_to_varchar2 (l_raw)),
                         SUBSTR (UTL_RAW.cast_to_varchar2 (l_raw), 1, LENGTH (UTL_RAW.cast_to_varchar2 (l_raw))));
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      UTL_HTTP.end_response (http_response);

      soap_startp := DBMS_LOB.INSTR (l_clob, con_xml_result_starttag) + LENGTH (con_xml_result_starttag);
      soap_length := DBMS_LOB.INSTR (l_clob, con_xml_result_endtag) - soap_startp;
      xml_report := xmltype (DBMS_XMLGEN.CONVERT (SUBSTR (l_clob, soap_startp, soap_length), DBMS_XMLGEN.ENTITY_DECODE));
      DBMS_LOB.freetemporary (l_clob);
      v_clob := urifactory.geturi (con_http_xsl_uri).getclob ();
      xml_report :=
         xml_report.transform (xmltype (v_clob,
                                        NULL,
                                        1,
                                        1));
      streamhtml (xml_report);
   EXCEPTION
      WHEN OTHERS
      THEN
         utl_linkedin.senderroroutput (SQLERRM, DBMS_UTILITY.format_error_backtrace);
   END html;

   PROCEDURE streamhtml (p_data_set XMLTYPE := NULL)
   IS
      v_data_blob    BLOB := NULL;
      v_doc_clob     CLOB := p_data_set.getclobval ();
      l_blob         BLOB;
      l_clob         CLOB;
      l_len          NUMBER;
      l_offset       NUMBER := 1;
      l_amount       NUMBER := 16000;
      l_buffer       VARCHAR2 (32767);
      l_buffer_raw   RAW (32767);
   BEGIN
      DBMS_LOB.createtemporary (v_data_blob, FALSE, DBMS_LOB.CALL);
      l_len := DBMS_LOB.getlength (v_doc_clob);
      l_offset := 1;

      WHILE l_offset < l_len
      LOOP
         DBMS_LOB.READ (v_doc_clob,
                        l_amount,
                        l_offset,
                        l_buffer);
         l_buffer_raw := UTL_RAW.cast_to_raw (l_buffer);
         DBMS_LOB.writeappend (v_data_blob, UTL_RAW.LENGTH (l_buffer_raw), l_buffer_raw);
         l_offset := l_offset + l_amount;

         IF l_len - l_offset < 16000
         THEN
            l_amount := l_len - l_offset;
         END IF;
      END LOOP;

      OWA_UTIL.mime_header ('text/html', FALSE, 'utf-8');
      HTP.p ('Content-Length: ' || (DBMS_LOB.getlength (v_data_blob)) || crlf);
      OWA_UTIL.http_header_close;
      WPG_DOCLOAD.download_file (v_data_blob);
   END streamhtml;
END mstr_soap_executereport;
/

