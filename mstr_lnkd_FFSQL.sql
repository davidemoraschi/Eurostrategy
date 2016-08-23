/* Formatted on 22/09/2011 12:17:32 (QP5 v5.139.911.3011) */
CREATE OR REPLACE PACKAGE BODY EUROSTAT.mstr_lnkd_FFSQL
AS
   PROCEDURE connections (lnkd_id IN VARCHAR2, cursor_connections IN OUT SYS_REFCURSOR)
   IS
      oauth_api_url                   VARCHAR2 (1000) := 'http://api.linkedin.com/v1/people/~/connections';
      http_method                     CONSTANT VARCHAR2 (5) := 'GET';
      http_req                        UTL_HTTP.req;
      http_resp                       UTL_HTTP.resp;
      oauth_consumer_key              VARCHAR2 (500);
      oauth_consumer_secret           VARCHAR2 (500);
      oauth_timestamp                 VARCHAR2 (50);
      oauth_nonce                     VARCHAR2 (50);
      oauth_base_string               VARCHAR2 (1000);
      oauth_signature                 VARCHAR2 (100);
      --oauth_callback                  VARCHAR2 (1000) := 'http://moraschi.eu/sso/request_token_callback';
      oauth_access_token              VARCHAR2 (500);
      oauth_access_token_secret       VARCHAR2 (500);
      var_http_authorization_header   VARCHAR2 (4096);
      var_http_resp_value             VARCHAR2 (32767);
      var_http_header_name            VARCHAR2 (255);
      var_http_header_value           VARCHAR2 (1023);
      l_clob                          CLOB;
      l_xml                           XMLTYPE;
      l_xml_from_cursor               VARCHAR2 (32767);
      l_xsl                           XMLTYPE;
      l_html                          VARCHAR2 (32767);
      b_debug                         BOOLEAN := FALSE;
   BEGIN
      NULL;

      BEGIN
         SELECT oauth_consumer_key,
                oauth_consumer_secret,
                oauth_access_token,
                oauth_access_token_secret
           INTO oauth_consumer_key,
                oauth_consumer_secret,
                oauth_access_token,
                oauth_access_token_secret
           FROM oauth_linkedin_parameters
          WHERE account = SUBSTR (lnkd_id, 6);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF b_debug
            THEN
               HTP.p ('ERROR: Account unknown');
               RETURN;
            ELSE
               RAISE;
            END IF;
      END;

      SELECT utl_linkedin.urlencode (oauth_nonce_seq.NEXTVAL) INTO oauth_nonce FROM DUAL;

      SELECT TO_CHAR (
                (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - pq_constants.con_num_timestamp_tz_diff)
        INTO oauth_timestamp
        FROM DUAL;

      oauth_base_string :=
         utl_linkedin.base_string_access_token (http_method,
                                                oauth_api_url,
                                                oauth_consumer_key,
                                                oauth_timestamp,
                                                oauth_nonce,
                                                oauth_access_token);

      oauth_signature :=
         utl_linkedin.
         signature (oauth_base_string, utl_linkedin.key_token (oauth_consumer_secret, oauth_access_token_secret));
      var_http_authorization_header :=
         utl_linkedin.authorization_header (oauth_consumer_key,
                                            oauth_access_token,
                                            oauth_timestamp,
                                            oauth_nonce,
                                            oauth_signature);

      UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
      UTL_HTTP.set_wallet (PATH => pq_constants.con_str_wallet_path, password => pq_constants.con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);

      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => var_http_authorization_header);

      http_resp := UTL_HTTP.get_response (http_req);

      IF b_debug
      THEN
         DBMS_OUTPUT.put_line ('<table border="1">');
         DBMS_OUTPUT.put_line ('<tr><td><b>status code: </b>' || http_resp.status_code || '</td></tr>');
         DBMS_OUTPUT.put_line ('<tr><td><b>reason phrase: </b>' || http_resp.reason_phrase || '</td></tr>');

         FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
         LOOP
            UTL_HTTP.get_header (http_resp,
                                 i,
                                 var_http_header_name,
                                 var_http_header_value);
            DBMS_OUTPUT.
            put_line ('<tr><td><b>' || var_http_header_name || ': </b>' || var_http_header_value || '</td></tr>');
         END LOOP;

         DBMS_OUTPUT.put_line ('<tr><td>&nbsp;</td></tr>');
      END IF;

      DBMS_LOB.createtemporary (l_clob, FALSE);

      BEGIN
         WHILE TRUE
         LOOP
            UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            DBMS_LOB.writeappend (l_clob, LENGTH (var_http_resp_value), var_http_resp_value);
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      l_xml := xmltype (l_clob);
      UTL_HTTP.end_response (http_resp);

      IF b_debug
      THEN
         INSERT INTO log_http (result, last_execution)
              VALUES (l_xml, SYSTIMESTAMP);

         COMMIT;
      END IF;

      IF b_debug
      THEN
         FOR c1 IN (SELECT EXTRACTVALUE (VALUE (p), '/person/id') "id",
                           EXTRACTVALUE (VALUE (p), '/person/first-name') "first-name",
                           EXTRACTVALUE (VALUE (p), '/person/last-name') "last-name",
                           EXTRACTVALUE (VALUE (p), '/person/headline') "headline",
                           EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
                           EXTRACTVALUE (VALUE (p), '/person/location/name') "location",
                           EXTRACTVALUE (VALUE (p), '/person/industry') "industry"
                      FROM TABLE (XMLSEQUENCE (EXTRACT (l_xml, '/connections/person'))) p)
         LOOP
            DBMS_OUTPUT.put_line ('<tr><td>' || c1."first-name" || '</td></tr>');
         END LOOP;
      ELSE
         OPEN cursor_connections FOR
            SELECT EXTRACTVALUE (VALUE (p), '/person/id') "id",
                   EXTRACTVALUE (VALUE (p), '/person/first-name') "first-name",
                   EXTRACTVALUE (VALUE (p), '/person/last-name') "last-name",
                   EXTRACTVALUE (VALUE (p), '/person/headline') "headline",
                   EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
                   EXTRACTVALUE (VALUE (p), '/person/location/name') "location",
                   EXTRACTVALUE (VALUE (p), '/person/industry') "industry"
              FROM TABLE (XMLSEQUENCE (EXTRACT (l_xml, '/connections/person'))) p;
      END IF;


      DBMS_LOB.freetemporary (l_clob);
   EXCEPTION
      WHEN OTHERS
      THEN
         utl_linkedin.senderroroutput (SQLERRM, DBMS_UTILITY.format_error_backtrace);
   END connections;

   FUNCTION connections_table (lnkd_id IN VARCHAR2)
      RETURN mstr_lnkd_connections_type
   IS
      v_tab                mstr_lnkd_connections_type := mstr_lnkd_connections_type ();
      cursor_connections   SYS_REFCURSOR;
      v_id                 VARCHAR2 (50);
      v_first_name         VARCHAR2 (250);
      v_last_name          VARCHAR2 (250);
      v_headline           VARCHAR2 (250);
      v_link               VARCHAR2 (2500);
      v_location           VARCHAR2 (250);
      v_industry           VARCHAR2 (250);
   BEGIN
      connections (lnkd_id, cursor_connections);

      LOOP
         FETCH cursor_connections
         INTO v_id, v_first_name, v_last_name, v_headline, v_link, v_location, v_industry;

         EXIT WHEN cursor_connections%NOTFOUND;

         v_tab.EXTEND;
         v_tab (v_tab.LAST) :=
            mstr_lnkd_connection_row_type (v_id,
                                           v_first_name,
                                           v_last_name,
                                           v_headline);
      END LOOP;



      RETURN v_tab;
   END;

   PROCEDURE groups (lnkd_id IN VARCHAR2, cursor_groups IN OUT SYS_REFCURSOR)
   IS
      oauth_api_url               VARCHAR2 (1000)
                                     := 'http://api.linkedin.com/v1/people/~/group-memberships:(group:(id,name,counts-by-category))';
      oauth_api_url_parameters    VARCHAR2 (1000) := 'count=500&membership-state=member';
      http_method                 CONSTANT VARCHAR2 (5) := 'GET';
      http_req                    UTL_HTTP.req;
      http_resp                   UTL_HTTP.resp;
      oauth_consumer_key          VARCHAR2 (500);
      oauth_consumer_secret       VARCHAR2 (500);
      oauth_access_token          VARCHAR2 (500);
      oauth_access_token_secret   VARCHAR2 (500);
      oauth_timestamp             VARCHAR2 (50);
      oauth_nonce                 VARCHAR2 (50);
      oauth_base_string           VARCHAR2 (1000);
      oauth_signature             VARCHAR2 (100);
      var_http_resp_value         VARCHAR2 (32767);
      var_http_header_name        VARCHAR2 (255);
      var_http_header_value       VARCHAR2 (1023);
      l_clob                      CLOB;
      l_xml                       XMLTYPE;
      b_debug                     BOOLEAN := FALSE;
   BEGIN
      IF lnkd_id IS NULL
      THEN
         HTP.p ('ERROR: Null ID');
         RETURN;
      END IF;

      BEGIN
         SELECT oauth_consumer_key,
                oauth_consumer_secret,
                oauth_access_token,
                oauth_access_token_secret
           INTO oauth_consumer_key,
                oauth_consumer_secret,
                oauth_access_token,
                oauth_access_token_secret
           FROM oauth_linkedin_parameters
          WHERE account = SUBSTR (lnkd_id, 6);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF b_debug
            THEN
               HTP.p ('ERROR: Account unknown');
               RETURN;
            ELSE
               RAISE;
            END IF;
      END;

      SELECT utl_linkedin.urlencode (oauth_nonce_seq.NEXTVAL) INTO oauth_nonce FROM DUAL;

      SELECT TO_CHAR (
                (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - pq_constants.con_num_timestamp_tz_diff)
        INTO oauth_timestamp
        FROM DUAL;

      oauth_base_string :=
         utl_linkedin.base_string_access_token_par (http_method,
                                                    oauth_api_url,
                                                    oauth_consumer_key,
                                                    oauth_timestamp,
                                                    oauth_nonce,
                                                    oauth_access_token,
                                                    oauth_api_url_parameters);
      oauth_signature :=
         utl_linkedin.
         signature (oauth_base_string, utl_linkedin.key_token (oauth_consumer_secret, oauth_access_token_secret));
      oauth_api_url :=
            oauth_api_url
         || '?'
         || oauth_api_url_parameters
         || '&oauth_consumer_key='
         || oauth_consumer_key
         || '&oauth_nonce='
         || oauth_nonce
         || '&oauth_signature='
         || urlencode (oauth_signature)
         || '&oauth_signature_method=HMAC-SHA1&oauth_timestamp='
         || oauth_timestamp
         || '&oauth_token='
         || oauth_access_token
         || '&oauth_version=1.0';
      UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
      UTL_HTTP.set_wallet (PATH => pq_constants.con_str_wallet_path, password => pq_constants.con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);

      IF b_debug
      THEN
         HTP.p ('<table border="1">');
         HTP.p ('<tr><td><b>oauth_consumer_key: </b>' || oauth_consumer_key || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_consumer_secret: </b>' || oauth_consumer_secret || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_nonce: </b>' || oauth_nonce || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_timestamp: </b>' || oauth_timestamp || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_token: </b>' || oauth_access_token || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_access_token_secret: </b>' || oauth_access_token_secret || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_base_string: </b>' || oauth_base_string || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_signature: </b>' || oauth_signature || '</td></tr>');
         HTP.p ('<tr><td><b>oauth_api_url: </b>' || oauth_api_url || '</td></tr>');
         HTP.p ('<tr><td>&nbsp;</td></tr>');
      END IF;

      http_resp := UTL_HTTP.get_response (http_req);

      IF b_debug
      THEN
         HTP.p ('<tr><td><b>status code: </b>' || http_resp.status_code || '</td></tr>');
         HTP.p ('<tr><td><b>reason phrase: </b>' || http_resp.reason_phrase || '</td></tr>');

         FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
         LOOP
            UTL_HTTP.get_header (http_resp,
                                 i,
                                 var_http_header_name,
                                 var_http_header_value);
            HTP.p ('<tr><td><b>' || var_http_header_name || ': </b>' || var_http_header_value || '</td></tr>');
         END LOOP;

         HTP.p ('<tr><td>&nbsp;</td></tr>');
         HTP.p ('</table>');
      END IF;

      DBMS_LOB.createtemporary (l_clob, FALSE);

      BEGIN
         WHILE TRUE
         LOOP
            UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            DBMS_LOB.writeappend (l_clob, LENGTH (var_http_resp_value), var_http_resp_value);

            IF b_debug
            THEN
               HTP.p (var_http_resp_value);
            END IF;
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      l_xml := xmltype (l_clob);
      UTL_HTTP.end_response (http_resp);

      INSERT INTO log_http (result, last_execution)
           VALUES (l_xml, SYSTIMESTAMP);

      OPEN cursor_groups FOR
         SELECT EXTRACTVALUE (VALUE (p), '/group/id') "id", EXTRACTVALUE (VALUE (p), '/group/name') "name"           --,
           --                EXTRACTVALUE (VALUE (p), '/person/last-name') "last-name",
           --                EXTRACTVALUE (VALUE (p), '/person/headline') "headline",
           --                EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
           --                EXTRACTVALUE (VALUE (p), '/person/location/name') "location",
           --                EXTRACTVALUE (VALUE (p), '/person/industry') "industry"
           FROM TABLE (XMLSEQUENCE (EXTRACT (l_xml, '/group-memberships/group-membership'))) p;

      DBMS_LOB.freetemporary (l_clob);
   EXCEPTION
      WHEN OTHERS
      THEN
         utl_linkedin.senderroroutput (SQLERRM, DBMS_UTILITY.format_error_backtrace);
   END groups;
END mstr_lnkd_FFSQL;
/