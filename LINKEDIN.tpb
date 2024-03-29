/* Formatted on 8/20/2012 2:09:37 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE TYPE BODY SSO.LINKEDIN
AS
   CONSTRUCTOR FUNCTION LINKEDIN (id                      IN VARCHAR2 DEFAULT 'test',
                                  oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                  oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                  oauth_callback          IN VARCHAR2 DEFAULT 'oob')
      RETURN SELF AS RESULT
   IS
      http_method    CONSTANT VARCHAR2 (5) := 'POST';
      http_req                UTL_HTTP.req;
      http_resp               UTL_HTTP.resp;
      var_http_header_name    VARCHAR2 (255);
      var_http_header_value   VARCHAR2 (1023);
      var_http_resp_value     VARCHAR2 (32767);
   BEGIN
      SELF.id := id;
      SELF.con_num_timestamp_tz_diff := global_constants.con_num_timestamp_tz_diff;
      SELF.oauth_consumer_key := oauth_consumer_key;
      SELF.oauth_consumer_secret := oauth_consumer_secret;
      SELF.oauth_api_request_token_url := 'https://api.linkedin.com/uas/oauth/requestToken';
      SELF.oauth_api_authorization_url := 'https://www.linkedin.com/uas/oauth/authenticate';
      SELF.oauth_api_access_token_url := 'https://api.linkedin.com/uas/oauth/accessToken';
      SELF.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - SELF.con_num_timestamp_tz_diff));
      SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));
      SELF.oauth_callback := oauth_callback;
      SELF.oauth_base_string :=
         SELF.base_string2 (p_http_method         => http_method,
                            p_request_token_url   => SELF.oauth_api_request_token_url,
                            p_callback_url        => SELF.oauth_callback,
                            p_consumer_key        => SELF.oauth_consumer_key,
                            p_timestamp           => SELF.oauth_timestamp,
                            p_nonce               => SELF.oauth_nonce,
                            p_token               => NULL,
                            p_token_verifier      => NULL);
      SELF.oauth_signature :=
         SELF.signature (p_oauth_base_string   => SELF.oauth_base_string,
                         p_oauth_key           => SELF.key_token (SELF.oauth_consumer_secret, NULL));
      SELF.var_http_authorization_header :=
         SELF.authorization_header (p_callback_url   => SELF.oauth_callback,
                                    p_consumer_key   => SELF.oauth_consumer_key,
                                    p_timestamp      => SELF.oauth_timestamp,
                                    p_nonce          => SELF.oauth_nonce,
                                    p_signature      => SELF.oauth_signature,
                                    p_token          => NULL,
                                    p_verifier       => NULL);
      --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
      UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (SELF.oauth_api_request_token_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => SELF.var_http_authorization_header);
      http_resp := UTL_HTTP.get_response (http_req);

      -- reads the Headers
      FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
      LOOP
         UTL_HTTP.get_header (http_resp,
                              i,
                              var_http_header_name,
                              var_http_header_value);
      --DBMS_OUTPUT.put_line (var_http_header_name || ': ' || var_http_header_value);
      END LOOP;

      -- reads the Content
      BEGIN
         WHILE TRUE
         LOOP
            UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);

            IF INSTR (var_http_resp_value, 'oauth_token=') > 0
            THEN
               SELF.oauth_request_token := SELF.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token');
               SELF.oauth_request_token_secret := SELF.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token_secret');
               DBMS_OUTPUT.put_line ('oauth_token          : ' || SELF.oauth_request_token);
               DBMS_OUTPUT.put_line ('oauth_token_secret   : ' || SELF.oauth_request_token_secret);
               SELF.ID := SELF.oauth_request_token;
               SELF.oauth_api_authorization_url := SELF.oauth_api_authorization_url || '?oauth_token=' || SELF.oauth_request_token;
            END IF;
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      UTL_HTTP.end_response (http_resp);

      RETURN;
   END;

   MEMBER PROCEDURE SAVE
   IS
   BEGIN
      UPDATE objs_linkedin C
         SET c.obj_linkedin = SELF
       WHERE ACCOUNT = SELF.ID;

      IF SQL%ROWCOUNT = 0
      THEN
         INSERT INTO objs_linkedin
              VALUES (SELF.ID, SYSTIMESTAMP, SELF);
      END IF;
   END;

   MEMBER PROCEDURE remove
   IS
   BEGIN
      DELETE objs_linkedin
       --SET c.obj_linkedin = SELF
       WHERE ACCOUNT = SELF.ID;
   --      IF SQL%ROWCOUNT = 0
   --      THEN
   --         INSERT INTO objs_linkedin
   --              VALUES (SELF.ID, SYSTIMESTAMP, SELF);
   --      END IF;
   END;

   MEMBER PROCEDURE upgrade_token
   IS
      http_method    CONSTANT VARCHAR2 (5) := 'POST';
      http_req                UTL_HTTP.req;
      http_resp               UTL_HTTP.resp;
      var_http_header_name    VARCHAR2 (255);
      var_http_header_value   VARCHAR2 (1023);
      var_http_resp_value     VARCHAR2 (32767);
   --con_str_wallet_path   CONSTANT VARCHAR2 (500) := 'file:C:\INyDIA\wallet';
   --con_str_wallet_pass   CONSTANT VARCHAR2 (100) := 'Lepanto1571';
   BEGIN
      SELF.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));

      SELF.oauth_base_string :=
         SELF.base_string2 (p_http_method         => http_method,
                            p_request_token_url   => SELF.oauth_api_access_token_url,
                            p_consumer_key        => SELF.oauth_consumer_key,
                            p_timestamp           => SELF.oauth_timestamp,
                            p_nonce               => SELF.oauth_nonce,
                            p_token               => SELF.oauth_request_token,
                            p_token_verifier      => SELF.oauth_verifier);
      SELF.oauth_signature :=
         SELF.signature (p_oauth_base_string   => SELF.oauth_base_string,
                         p_oauth_key           => SELF.key_token (SELF.oauth_consumer_secret, SELF.oauth_request_token_secret));
      SELF.var_http_authorization_header :=
         SELF.authorization_header (p_consumer_key   => SELF.oauth_consumer_key,
                                    p_timestamp      => SELF.oauth_timestamp,
                                    p_nonce          => SELF.oauth_nonce,
                                    p_signature      => SELF.oauth_signature,
                                    p_token          => SELF.oauth_request_token,
                                    p_verifier       => SELF.oauth_verifier);
      --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);

      UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);

      http_req := UTL_HTTP.begin_request (SELF.oauth_api_access_token_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => SELF.var_http_authorization_header);
      UTL_HTTP.set_header (r => http_req, name => 'Content-Type', VALUE => 'text/xml');
      http_resp := UTL_HTTP.get_response (http_req);

      -- reads the Headers
      FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
      LOOP
         UTL_HTTP.get_header (http_resp,
                              i,
                              var_http_header_name,
                              var_http_header_value);
      --DBMS_OUTPUT.put_line (var_http_header_name || ': ' || var_http_header_value);
      END LOOP;

      -- reads the Content
      BEGIN
         WHILE TRUE
         LOOP
            UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);

            IF INSTR (var_http_resp_value, 'oauth_token=') > 0
            THEN
               SELF.oauth_access_token := SELF.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token');
               SELF.oauth_access_token_secret := SELF.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token_secret');
               DBMS_OUTPUT.put_line ('oauth_token          : ' || SELF.oauth_access_token);
               DBMS_OUTPUT.put_line ('oauth_token_secret   : ' || SELF.oauth_access_token_secret);
            END IF;
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      UTL_HTTP.end_response (http_resp);
   END upgrade_token;

   MEMBER PROCEDURE get_profile (p_fields IN VARCHAR2 DEFAULT '(id,first-name,last-name,headline)')
   IS
      http_method    CONSTANT VARCHAR2 (5) := 'GET';
      oauth_api_url           VARCHAR2 (1000) := 'http://api.linkedin.com/v1/people/~:' || p_fields;
      http_req                UTL_HTTP.req;
      http_resp               UTL_HTTP.resp;
      var_http_header_name    VARCHAR2 (255);
      var_http_header_value   VARCHAR2 (1023);
      var_http_resp_value     VARCHAR2 (32767);
      l_clob                  CLOB;
      l_xml                   XMLTYPE;
   BEGIN
      SELF.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));
      SELF.oauth_base_string :=
         SELF.base_string2 (p_http_method         => http_method,
                            p_request_token_url   => oauth_api_url,
                            p_callback_url        => NULL,
                            p_consumer_key        => SELF.oauth_consumer_key,
                            p_timestamp           => SELF.oauth_timestamp,
                            p_nonce               => SELF.oauth_nonce,
                            p_token               => SELF.oauth_access_token,
                            p_token_verifier      => NULL);
      SELF.oauth_signature :=
         SELF.signature (p_oauth_base_string   => SELF.oauth_base_string,
                         p_oauth_key           => SELF.key_token (SELF.oauth_consumer_secret, SELF.oauth_access_token_secret));

      SELF.var_http_authorization_header :=
         SELF.authorization_header (p_consumer_key   => SELF.oauth_consumer_key,
                                    p_timestamp      => SELF.oauth_timestamp,
                                    p_nonce          => SELF.oauth_nonce,
                                    p_signature      => SELF.oauth_signature,
                                    p_token          => SELF.oauth_access_token,
                                    p_verifier       => NULL);
      --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
      UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => var_http_authorization_header);
      http_resp := UTL_HTTP.get_response (http_req);

      -- reads the Headers
      FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
      LOOP
         UTL_HTTP.get_header (http_resp,
                              i,
                              var_http_header_name,
                              var_http_header_value);
      --DBMS_OUTPUT.put_line (var_http_header_name || ': ' || var_http_header_value);
      END LOOP;

      DBMS_LOB.createtemporary (l_clob, FALSE);

      -- reads the Content
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
      DBMS_LOB.freetemporary (l_clob);

      UTL_HTTP.end_response (http_resp);
      SELF.remove;
      SELF.ID := 'LNKD_' || l_xml.EXTRACT ('/person/id/text()').getstringval ();
      SELF.descr :=
            l_xml.EXTRACT ('/person/first-name/text()').getstringval ()
         || ' '
         || l_xml.EXTRACT ('/person/last-name/text()').getstringval ();
      SELF.save;
   END get_profile;

   MEMBER PROCEDURE get_connections (p_fields IN VARCHAR2 DEFAULT '(id,first-name,last-name)', p_response OUT XMLTYPE)
   --RETURN XMLTYPE
   IS
      http_method    CONSTANT VARCHAR2 (5) := 'GET';
      oauth_api_url           VARCHAR2 (1000) := 'http://api.linkedin.com/v1/people/~/connections:' || p_fields;
      --http://api.linkedin.com/v1/people/~/connections:(headline,first-name,last-name)
      http_req                UTL_HTTP.req;
      http_resp               UTL_HTTP.resp;
      var_http_header_name    VARCHAR2 (255);
      var_http_header_value   VARCHAR2 (1023);
      var_http_resp_value     VARCHAR2 (32767);
      --l_clob                  CLOB;
      --l_xml                   XMLTYPE;
      l_uncompressed_blob     BLOB;
      l_gzcompressed_blob     BLOB;
      l_raw                   RAW (32767);
   BEGIN
      SELF.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));
      SELF.oauth_base_string :=
         SELF.base_string2 (p_http_method         => http_method,
                            p_request_token_url   => oauth_api_url,
                            p_callback_url        => NULL,
                            p_consumer_key        => SELF.oauth_consumer_key,
                            p_timestamp           => SELF.oauth_timestamp,
                            p_nonce               => SELF.oauth_nonce,
                            p_token               => SELF.oauth_access_token,
                            p_token_verifier      => NULL);
      SELF.oauth_signature :=
         SELF.signature (p_oauth_base_string   => SELF.oauth_base_string,
                         p_oauth_key           => SELF.key_token (SELF.oauth_consumer_secret, SELF.oauth_access_token_secret));

      SELF.var_http_authorization_header :=
         SELF.authorization_header (p_consumer_key   => SELF.oauth_consumer_key,
                                    p_timestamp      => SELF.oauth_timestamp,
                                    p_nonce          => SELF.oauth_nonce,
                                    p_signature      => SELF.oauth_signature,
                                    p_token          => SELF.oauth_access_token,
                                    p_verifier       => NULL);
      --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
      UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => var_http_authorization_header);
      UTL_HTTP.set_header (r => http_req, name => 'Accept-Encoding', VALUE => 'gzip,deflate');
      http_resp := UTL_HTTP.get_response (http_req);

      -- reads the Headers
      FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
      LOOP
         UTL_HTTP.get_header (http_resp,
                              i,
                              var_http_header_name,
                              var_http_header_value);
         --DBMS_OUTPUT.put_line (var_http_header_name || ': ' || var_http_header_value);
      END LOOP;

      --DBMS_LOB.createtemporary (l_clob, FALSE);
      DBMS_LOB.createtemporary (l_gzcompressed_blob, FALSE);

      -- reads the Content
      BEGIN
         WHILE TRUE
         LOOP
            --UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            UTL_HTTP.read_raw (http_resp, l_raw, 32766);
            DBMS_LOB.writeappend (l_gzcompressed_blob, UTL_RAW.LENGTH (l_raw), l_raw);
         --DBMS_OUTPUT.put_line (var_http_resp_value);
         --DBMS_LOB.writeappend (l_clob, LENGTH (var_http_resp_value), var_http_resp_value);
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      --l_xml := xmltype (l_clob);
      --DBMS_LOB.freetemporary (l_clob);
      DBMS_LOB.createtemporary (l_uncompressed_blob, FALSE);

      UTL_COMPRESS.lz_uncompress (src => l_gzcompressed_blob, dst => l_uncompressed_blob);
      --DBMS_OUTPUT.put_line ('Uncompressed Data: ' || UTL_RAW.CAST_TO_VARCHAR2 (l_uncompressed_blob));
      DBMS_LOB.freetemporary (l_gzcompressed_blob);
      p_response := XMLTYPE (UTL_RAW.CAST_TO_VARCHAR2 (l_uncompressed_blob));
      DBMS_LOB.freetemporary (l_uncompressed_blob);


      UTL_HTTP.end_response (http_resp);
   --SELF.remove;
   --SELF.ID := 'LNKD_' || l_xml.EXTRACT ('/person/id/text()').getstringval ();
   --      SELF.descr :=
   --            l_xml.EXTRACT ('/person/first-name/text()').getstringval ()
   --         || ' '
   --         || l_xml.EXTRACT ('/person/last-name/text()').getstringval ();
   --SELF.save;

   -- RETURN xmltype('<ok />');
   END get_connections;
END;
/