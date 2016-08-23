/* Formatted on 1/5/2012 2:48:39 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY EUROSTAT.obj_goog_oauth2_auth_cb
AS
   PROCEDURE jsp (state IN VARCHAR2 := NULL, code IN VARCHAR2 := NULL, error IN VARCHAR2 := NULL)
   IS
      http_method            CONSTANT VARCHAR2 (5) := 'POST';
      http_req                        UTL_HTTP.req;
      http_resp                       UTL_HTTP.resp;
      google_analytics_oauth2_url     VARCHAR2 (2000) := 'https://accounts.google.com/o/oauth2/token';
      var_http_authorization_header   VARCHAR2 (4096);
      v_user_params                   VARCHAR2 (2048)
         := 'code=' || code
            || '&client_id=560216110065.apps.googleusercontent.com&client_secret=50sQBHAsM76cVPuMNH6xaE2Z&redirect_uri=http://moraschi.eu:8081/sso/obj_goog_oauth2_auth_cb.jsp&grant_type=authorization_code';
      h_name                          VARCHAR2 (255);
      h_value                         VARCHAR2 (1023);
      res_value                       VARCHAR2 (32767);
      l_clob                          CLOB;
      l_text                          VARCHAR2 (32767);
      l_xml                           XMLTYPE;
      obj                             json;                                                 -- := json ('{a:1,b:[2,3,4],c:true}');
   BEGIN
      IF error = 'access_denied'
      THEN
         HTP.p ('[access_denied] under construction...');
      ELSE
         UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
         UTL_HTTP.set_wallet (PATH => pq_constants.con_str_wallet_path, password => pq_constants.con_str_wallet_pass);
         UTL_HTTP.set_response_error_check (FALSE);
         UTL_HTTP.set_detailed_excp_support (FALSE);
         http_req := UTL_HTTP.begin_request (google_analytics_oauth2_url, http_method, UTL_HTTP.http_version_1_1);

         UTL_HTTP.set_body_charset (http_req, 'UTF-8');
         UTL_HTTP.set_header (http_req, 'User-Agent', 'Mozilla/4.0');
         UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
         UTL_HTTP.set_header (r => http_req, NAME => 'Content-Length', VALUE => LENGTH (v_user_params));
         UTL_HTTP.write_text (http_req, v_user_params);
         http_resp := UTL_HTTP.get_response (http_req);

         FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
         LOOP
            UTL_HTTP.get_header (http_resp,
                                 i,
                                 h_name,
                                 h_value);
         END LOOP;

         DBMS_LOB.createtemporary (l_clob, FALSE);

         BEGIN
            WHILE 1 = 1
            LOOP
               UTL_HTTP.read_text (http_resp, l_text, 32766);
               DBMS_LOB.writeappend (l_clob, LENGTH (l_text), l_text);
            END LOOP;
         EXCEPTION
            WHEN UTL_HTTP.end_of_body
            THEN
               NULL;
         END;

         UTL_HTTP.end_response (http_resp);
         obj := json (l_clob);
         l_xml := json_xml.json_to_xml (obj);
         DBMS_LOB.freetemporary (l_clob);
         HTP.p (l_xml.getclobval ());
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         utl_linkedin.senderroroutput (SQLERRM, DBMS_UTILITY.format_error_backtrace);
   END jsp;
END obj_goog_oauth2_auth_cb;
/