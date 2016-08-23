CREATE OR REPLACE TYPE     GOOGLE
                     UNDER OAUTH
                  (oauth_callback VARCHAR2 (1000),
                   oauth_version NUMBER,
                   oauth_token_expires TIMESTAMP (6) WITH TIME ZONE,
                   oauth_token_type VARCHAR2 (50),
                   oauth_refresh_token VARCHAR2 (2000),
                   CONSTRUCTOR FUNCTION GOOGLE (id                      IN VARCHAR2 DEFAULT 'test',
                                                oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                                oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                                oauth_callback          IN VARCHAR2 DEFAULT 'oob',
                                                oauth_version           IN NUMBER DEFAULT 1,
                                                google_scope            IN VARCHAR2 DEFAULT 'http://www.google.com/base/feeds/')
                      RETURN SELF AS RESULT,
                   MEMBER PROCEDURE save,
                   MEMBER PROCEDURE remove,
                   MEMBER PROCEDURE upgrade_token,
                   MEMBER PROCEDURE refresh_token,
                   MEMBER PROCEDURE get_profile (p_fields IN VARCHAR2 DEFAULT '(id,first-name,last-name,headline)'),
                   MEMBER PROCEDURE gcal_create_event (p_start   IN DATE DEFAULT SYSDATE,
                                                       p_end     IN DATE DEFAULT (SYSDATE + 1),
                                                       p_title   IN VARCHAR2 DEFAULT 'title',
                                                       p_note    IN VARCHAR2 DEFAULT 'dummy event'));
/


CREATE OR REPLACE TYPE BODY     GOOGLE
AS
   CONSTRUCTOR FUNCTION GOOGLE (id                      IN VARCHAR2 DEFAULT 'test',
                                oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                oauth_callback          IN VARCHAR2 DEFAULT 'oob',
                                oauth_version           IN NUMBER DEFAULT 1,
                                google_scope            IN VARCHAR2 DEFAULT 'http://www.google.com/base/feeds/')
      RETURN SELF AS RESULT
   IS
      http_method    CONSTANT VARCHAR2 (5) := 'GET';
      http_req                UTL_HTTP.req;
      http_resp               UTL_HTTP.resp;
      var_http_header_name    VARCHAR2 (255);
      var_http_header_value   VARCHAR2 (1023);
      var_http_resp_value     VARCHAR2 (32767);
   BEGIN
      SELF.id := id;
      SELF.oauth_version := oauth_version;
      SELF.oauth_consumer_key := oauth_consumer_key;
      SELF.oauth_consumer_secret := oauth_consumer_secret;
      SELF.oauth_callback := oauth_callback;

      IF oauth_version = 2
      THEN
         --SELF.oauth_api_request_token_url := 'https://www.google.com/accounts/OAuthGetRequestToken';
         SELF.oauth_api_authorization_url := 'https://accounts.google.com/o/oauth2/auth';
         SELF.oauth_api_access_token_url := 'https://accounts.google.com/o/oauth2/token';
      --SELF.oauth_api_access_token_url := 'https://www.google.com/accounts/OAuthGetAccessToken';
      ELSE
         SELF.con_num_timestamp_tz_diff := global_constants.con_num_timestamp_tz_diff;
         -- SELF.oauth_consumer_key := oauth_consumer_key;
         -- SELF.oauth_consumer_secret := oauth_consumer_secret;
         --      SELF.oauth_api_request_token_url := 'https://accounts.google.com/o/oauth2/auth';
         SELF.oauth_api_request_token_url := 'https://www.google.com/accounts/OAuthGetRequestToken';
         SELF.oauth_api_authorization_url := 'https://www.google.com/accounts/OAuthAuthorizeToken';
         SELF.oauth_api_access_token_url := 'https://www.google.com/accounts/OAuthGetAccessToken';
         SELF.oauth_timestamp := TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
         SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));

         SELF.oauth_base_string :=
            SELF.base_string (p_http_method         => http_method,
                              p_request_token_url   => SELF.oauth_api_request_token_url,
                              p_callback_url        => SELF.oauth_callback,
                              p_consumer_key        => SELF.oauth_consumer_key,
                              p_timestamp           => SELF.oauth_timestamp,
                              p_nonce               => SELF.oauth_nonce,
                              p_token               => NULL,
                              p_token_verifier      => NULL)                                                                                                                     --;
            || SELF.urlencode ('&scope=' || SELF.urlencode (google_scope));
         SELF.oauth_signature := SELF.signature (p_oauth_base_string => SELF.oauth_base_string, p_oauth_key => SELF.key_token (SELF.oauth_consumer_secret, NULL));
         SELF.var_http_authorization_header :=
            SELF.authorization_header (p_callback_url   => SELF.oauth_callback,
                                       p_consumer_key   => SELF.oauth_consumer_key,
                                       p_timestamp      => SELF.oauth_timestamp,
                                       p_nonce          => SELF.oauth_nonce,
                                       p_signature      => SELF.oauth_signature,
                                       p_token          => NULL,
                                       p_verifier       => NULL);
         --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
         SELF.oauth_api_request_token_url :=
               SELF.oauth_api_request_token_url
            || '?'
            || 'oauth_callback='
            || SELF.urlencode (SELF.oauth_callback)
            || '&oauth_consumer_key='
            || SELF.oauth_consumer_key
            || '&oauth_nonce='
            || SELF.oauth_nonce
            || '&oauth_signature='
            || SELF.urlencode (SELF.oauth_signature)
            || '&oauth_signature_method=HMAC-SHA1'
            || '&oauth_timestamp='
            || SELF.oauth_timestamp
            --         || '&oauth_token='
            --         || SELF.oauth_access_token
            || '&oauth_version=1.0'
            || '&scope='
            || SELF.urlencode (google_scope)                                                                                                      --         ||'&response_type=code'
                                            --         ||'&redirect_uri='||(SELF.oauth_callback)
         ;

         UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
         UTL_HTTP.set_response_error_check (FALSE);
         UTL_HTTP.set_detailed_excp_support (FALSE);

         DBMS_OUTPUT.put_line ('oauth_consumer_key : ' || SELF.oauth_consumer_key);
         DBMS_OUTPUT.put_line ('oauth_consumer_secret : ' || SELF.oauth_consumer_secret);
         DBMS_OUTPUT.put_line ('oauth_access_token : ' || SELF.oauth_access_token);
         DBMS_OUTPUT.put_line ('oauth_access_token_secret : ' || SELF.oauth_access_token_secret);
         DBMS_OUTPUT.put_line ('oauth_nonce : ' || SELF.oauth_nonce);
         DBMS_OUTPUT.put_line ('oauth_timestamp : ' || SELF.oauth_timestamp);
         DBMS_OUTPUT.put_line ('oauth_base_string : ' || SELF.oauth_base_string);
         DBMS_OUTPUT.put_line ('oauth_signature : ' || SELF.oauth_signature);
         DBMS_OUTPUT.put_line ('var_http_authorization_header : ' || SELF.var_http_authorization_header);
         DBMS_OUTPUT.put_line ('oauth_api_url : ' || SELF.oauth_api_request_token_url);

         http_req := UTL_HTTP.begin_request (SELF.oauth_api_request_token_url, http_method, UTL_HTTP.http_version_1_1);
         --UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
         --UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => SELF.var_http_authorization_header);
         --UTL_HTTP.set_header (r => http_req, name => 'Content-Length', VALUE => LENGTH ('scope=' || google_scope));
         --UTL_HTTP.write_text (http_req, 'scope=' || google_scope);

         http_resp := UTL_HTTP.get_response (http_req);

         -- reads the Headers
         FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
         LOOP
            UTL_HTTP.get_header (http_resp,
                                 i,
                                 var_http_header_name,
                                 var_http_header_value);
            DBMS_OUTPUT.put_line (var_http_header_name || ': ' || var_http_header_value);
         END LOOP;

         -- reads the Content
         BEGIN
            WHILE TRUE
            LOOP
               UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
               DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);

               IF INSTR (var_http_resp_value, 'oauth_token=') > 0
               THEN
                  SELF.oauth_request_token := util.urldecode (SELF.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token'));
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
      END IF;

      RETURN;
   END;

   MEMBER PROCEDURE SAVE
   IS
   BEGIN
      UPDATE objs_google C
         SET c.obj_google = SELF
       WHERE ACCOUNT = SELF.ID;

      IF SQL%ROWCOUNT = 0
      THEN
         INSERT INTO objs_google
              VALUES (SELF.ID, SYSTIMESTAMP, SELF);
      END IF;
   END;

   MEMBER PROCEDURE remove
   IS
   BEGIN
      DELETE objs_google
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
      var_http_post_params    VARCHAR2 (2048);
      h_name                  VARCHAR2 (255);
      h_value                 VARCHAR2 (1023);
      --      res_value                       VARCHAR2 (32767);
      l_clob                  CLOB;
      l_text                  VARCHAR2 (32767);
      l_xml                   XMLTYPE;
      obj                     json;
   BEGIN
      IF SELF.oauth_version = 2
      THEN
         var_http_post_params :=
               'code='
            || SELF.oauth_request_token
            || '&client_secret='
            || SELF.oauth_consumer_secret
            || '&redirect_uri='
            || SELF.oauth_callback
            || '&grant_type=authorization_code'
            || '&client_id='
            || (SELF.oauth_consumer_key);
         UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
         UTL_HTTP.set_response_error_check (FALSE);
         UTL_HTTP.set_detailed_excp_support (FALSE);

         http_req := UTL_HTTP.begin_request (SELF.oauth_api_access_token_url, http_method, UTL_HTTP.http_version_1_1);
         UTL_HTTP.set_body_charset (http_req, 'UTF-8');
         UTL_HTTP.set_header (http_req, 'User-Agent', 'Mozilla/4.0');
         --UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => SELF.var_http_authorization_header);
         UTL_HTTP.set_header (r => http_req, name => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
         --UTL_HTTP.set_header (r => http_req, name => 'Content-length', VALUE => 0);
         --UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
         UTL_HTTP.set_header (r => http_req, NAME => 'Content-Length', VALUE => LENGTH (var_http_post_params));
         UTL_HTTP.write_text (http_req, var_http_post_params);
         http_resp := UTL_HTTP.get_response (http_req);
         DBMS_OUTPUT.put_line ('var_http_post_params: ' || var_http_post_params);

         FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
         LOOP
            UTL_HTTP.get_header (http_resp,
                                 i,
                                 h_name,
                                 h_value);
            DBMS_OUTPUT.put_line (h_name || ': ' || h_value);
         END LOOP;

         DBMS_LOB.createtemporary (l_clob, FALSE);

         BEGIN
            WHILE 1 = 1
            LOOP
               UTL_HTTP.read_text (http_resp, l_text, 32766);
               DBMS_LOB.writeappend (l_clob, LENGTH (l_text), l_text);
            --UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            --DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);
            --HTP.p (var_http_resp_value);
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
         --OWA_UTIL.mime_header ('text/xml', TRUE, 'utf-8');
         --HTP.p (l_xml.getstringval ());

         BEGIN
            SELF.oauth_refresh_token := REPLACE (l_xml.EXTRACT ('/root/refresh_token/text()').getstringval (), '&quot;', '');
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         SELF.oauth_access_token := REPLACE (l_xml.EXTRACT ('/root/access_token/text()').getstringval (), '&quot;', '');
         SELF.oauth_token_expires := SYSTIMESTAMP + TO_NUMBER (REPLACE (l_xml.EXTRACT ('/root/expires_in/text()').getstringval (), '&quot;', '')) / 3600 / 24;
         SELF.oauth_token_type := REPLACE (l_xml.EXTRACT ('/root/token_type/text()').getstringval (), '&quot;', '');
      ELSE
         SELF.oauth_timestamp := TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
         SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));

         SELF.oauth_base_string :=
            SELF.base_string (p_http_method         => http_method,
                              p_request_token_url   => SELF.oauth_api_access_token_url,
                              --p_callback_url        => SELF.oauth_callback,
                              p_consumer_key        => SELF.oauth_consumer_key,
                              p_timestamp           => SELF.oauth_timestamp,
                              p_nonce               => SELF.oauth_nonce,
                              p_token               => SELF.oauth_request_token,
                              p_token_verifier      => SELF.oauth_verifier);
         SELF.oauth_signature :=
            SELF.signature (p_oauth_base_string => SELF.oauth_base_string, p_oauth_key => SELF.key_token (SELF.oauth_consumer_secret, SELF.oauth_request_token_secret));
         SELF.var_http_authorization_header :=
            SELF.authorization_header (                                                                                                   --p_callback_url   => SELF.oauth_callback,
                                       p_consumer_key    => SELF.oauth_consumer_key,
                                       p_timestamp       => SELF.oauth_timestamp,
                                       p_nonce           => SELF.oauth_nonce,
                                       p_signature       => SELF.oauth_signature,
                                       p_token           => SELF.oauth_request_token,
                                       p_verifier        => SELF.oauth_verifier);
         --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);

         UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
         UTL_HTTP.set_response_error_check (FALSE);
         UTL_HTTP.set_detailed_excp_support (FALSE);

         http_req := UTL_HTTP.begin_request (SELF.oauth_api_access_token_url, http_method, UTL_HTTP.http_version_1_1);
         UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => SELF.var_http_authorization_header);
         UTL_HTTP.set_header (r => http_req, name => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
         UTL_HTTP.set_header (r => http_req, name => 'Content-length', VALUE => 0);

         DBMS_OUTPUT.put_line ('oauth_consumer_key : ' || SELF.oauth_consumer_key);
         DBMS_OUTPUT.put_line ('oauth_consumer_secret : ' || SELF.oauth_consumer_secret);
         DBMS_OUTPUT.put_line ('oauth_access_token : ' || SELF.oauth_access_token);
         DBMS_OUTPUT.put_line ('oauth_access_token_secret : ' || SELF.oauth_access_token_secret);
         DBMS_OUTPUT.put_line ('oauth_nonce : ' || SELF.oauth_nonce);
         DBMS_OUTPUT.put_line ('oauth_timestamp : ' || SELF.oauth_timestamp);
         DBMS_OUTPUT.put_line ('oauth_base_string : ' || SELF.oauth_base_string);
         DBMS_OUTPUT.put_line ('oauth_signature : ' || SELF.oauth_signature);
         DBMS_OUTPUT.put_line ('var_http_authorization_header : ' || SELF.var_http_authorization_header);
         DBMS_OUTPUT.put_line ('oauth_api_url : ' || SELF.oauth_api_request_token_url);

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
      END IF;
   END upgrade_token;

   MEMBER PROCEDURE refresh_token
   IS
      http_method    CONSTANT VARCHAR2 (5) := 'POST';
      http_req                UTL_HTTP.req;
      http_resp               UTL_HTTP.resp;
      var_http_header_name    VARCHAR2 (255);
      var_http_header_value   VARCHAR2 (1023);
      var_http_resp_value     VARCHAR2 (32767);
      var_http_post_params    VARCHAR2 (2048);
      h_name                  VARCHAR2 (255);
      h_value                 VARCHAR2 (1023);
      --      res_value                       VARCHAR2 (32767);
      l_clob                  CLOB;
      l_text                  VARCHAR2 (32767);
      l_xml                   XMLTYPE;
      obj                     json;
   BEGIN
      --IF SYSTIMESTAMP >= SELF.oauth_token_expires
      --THEN
         var_http_post_params :=
               'refresh_token='
            || SELF.oauth_refresh_token
            || '&client_secret='
            || SELF.oauth_consumer_secret
            || '&grant_type=refresh_token'
            || '&client_id='
            || (SELF.oauth_consumer_key);
         UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
         UTL_HTTP.set_response_error_check (FALSE);
         UTL_HTTP.set_detailed_excp_support (FALSE);

         http_req := UTL_HTTP.begin_request (SELF.oauth_api_access_token_url, http_method, UTL_HTTP.http_version_1_1);
         UTL_HTTP.set_body_charset (http_req, 'UTF-8');
         UTL_HTTP.set_header (http_req, 'User-Agent', 'Mozilla/4.0');
         --UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => SELF.var_http_authorization_header);
         UTL_HTTP.set_header (r => http_req, name => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
         --UTL_HTTP.set_header (r => http_req, name => 'Content-length', VALUE => 0);
         --UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
         UTL_HTTP.set_header (r => http_req, NAME => 'Content-Length', VALUE => LENGTH (var_http_post_params));
         UTL_HTTP.write_text (http_req, var_http_post_params);
         http_resp := UTL_HTTP.get_response (http_req);
         DBMS_OUTPUT.put_line ('var_http_post_params: ' || var_http_post_params);

         FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
         LOOP
            UTL_HTTP.get_header (http_resp,
                                 i,
                                 h_name,
                                 h_value);
            --HTP.p (h_name || ': ' || h_value);
         END LOOP;

         DBMS_LOB.createtemporary (l_clob, FALSE);

         BEGIN
            WHILE 1 = 1
            LOOP
               UTL_HTTP.read_text (http_resp, l_text, 32766);
               DBMS_LOB.writeappend (l_clob, LENGTH (l_text), l_text);
            --UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            --DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);
            --HTP.p (var_http_resp_value);
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
         --OWA_UTIL.mime_header ('text/xml', TRUE, 'utf-8');
         --HTP.p (l_xml.getstringval ());

         BEGIN
            SELF.oauth_refresh_token := REPLACE (l_xml.EXTRACT ('/root/refresh_token/text()').getstringval (), '&quot;', '');
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         SELF.oauth_access_token := REPLACE (l_xml.EXTRACT ('/root/access_token/text()').getstringval (), '&quot;', '');
         SELF.oauth_token_expires := SYSTIMESTAMP + TO_NUMBER (REPLACE (l_xml.EXTRACT ('/root/expires_in/text()').getstringval (), '&quot;', '')) / 3600 / 24;
         SELF.oauth_token_type := REPLACE (l_xml.EXTRACT ('/root/token_type/text()').getstringval (), '&quot;', '');
         SELF.save;
      --ELSE
      --OWA_UTIL.mime_header ('text/xml', TRUE, 'utf-8');
      --HTP.p ('token valid');
      --END IF;
   END refresh_token;

   MEMBER PROCEDURE get_profile (p_fields IN VARCHAR2 DEFAULT '(id,first-name,last-name,headline)')
   IS
      http_method            CONSTANT VARCHAR2 (5) := 'GET';
      oauth_api_url                   VARCHAR2 (1000) := 'https://www.googleapis.com/oauth2/v1/userinfo';
      var_http_authorization_header   VARCHAR2 (4096) := SELF.oauth_token_type || ' ' || SELF.oauth_access_token;

      http_req                        UTL_HTTP.req;
      http_resp                       UTL_HTTP.resp;
      var_http_header_name            VARCHAR2 (255);
      var_http_header_value           VARCHAR2 (1023);
      var_http_resp_value             VARCHAR2 (32767);
      l_clob                          CLOB;
      l_xml                           XMLTYPE;
      --l_html                          VARCHAR2 (32767);
      l_text                          VARCHAR2 (32767);
      h_name                          VARCHAR2 (255);
      h_value                         VARCHAR2 (1023);
      obj                             json;
   BEGIN
      IF SELF.oauth_version = 2
      THEN
         UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, password => global_constants.con_str_wallet_pass);
         UTL_HTTP.set_response_error_check (FALSE);
         UTL_HTTP.set_detailed_excp_support (FALSE);
         http_req := UTL_HTTP.begin_request (oauth_api_url                                                                         /*|| 'access_token=' || SELF.oauth_access_token*/
                                                          , http_method, UTL_HTTP.http_version_1_1);

         UTL_HTTP.set_body_charset (http_req, 'UTF-8');
         UTL_HTTP.set_header (http_req, 'User-Agent', 'Mozilla/4.0');
         UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => var_http_authorization_header);
         --HTP.p ('<hr>' || oauth_api_url);
         --HTP.p ('<hr>' || var_http_authorization_header);
         http_resp := UTL_HTTP.get_response (http_req);

         FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
         LOOP
            UTL_HTTP.get_header (http_resp,
                                 i,
                                 h_name,
                                 h_value);
         --HTP.p ('<hr>' || h_name || ':' || h_value);
         END LOOP;

         DBMS_LOB.createtemporary (l_clob, FALSE);

         BEGIN
            WHILE 1 = 1
            LOOP
               UTL_HTTP.read_text (http_resp, l_text, 32766);
               DBMS_LOB.writeappend (l_clob, LENGTH (l_text), l_text);
            --UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            --HTP.p (var_http_resp_value);
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

         SELF.id := 'GOOG_' || REPLACE (l_xml.EXTRACT ('/root/id/text()').getstringval (), '&quot;', '');
         SELF.descr :=
               REPLACE (l_xml.EXTRACT ('/root/given_name/text()').getstringval (), '&quot;', '')
            || ' '
            || REPLACE (l_xml.EXTRACT ('/root/family_name/text()').getstringval (), '&quot;', '');
         SELF.remove;
         SELF.save;
      /*        SELECT    '<return_code><pass userid="GOOG_'
                     || REPLACE(EXTRACTVALUE (l_xml, '/root/id'),'"','')
                     || '" username="'
                     || REPLACE(EXTRACTVALUE (l_xml, '/root/given_name'),'"','')
                     || ' '
                     || REPLACE(EXTRACTVALUE (l_xml, '/root/family_name'),'"','')
                     || '" /></return_code>'
                INTO l_html
                FROM DUAL;

              OWA_UTIL.mime_header ('text/xml', TRUE, 'utf-8');
              HTP.p (l_html);*/
      --      END IF;
      ELSE
         SELF.oauth_timestamp := TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
         SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));
         SELF.oauth_base_string :=
            SELF.base_string (p_http_method         => http_method,
                              p_request_token_url   => oauth_api_url,
                              p_callback_url        => NULL,
                              p_consumer_key        => SELF.oauth_consumer_key,
                              p_timestamp           => SELF.oauth_timestamp,
                              p_nonce               => SELF.oauth_nonce,
                              p_token               => SELF.oauth_access_token,
                              p_token_verifier      => NULL);
         SELF.oauth_signature :=
            SELF.signature (p_oauth_base_string => SELF.oauth_base_string, p_oauth_key => SELF.key_token (SELF.oauth_consumer_secret, SELF.oauth_access_token_secret));

         SELF.var_http_authorization_header :=
            SELF.authorization_header (                                                                                                   --p_callback_url   => SELF.oauth_callback,
                                       p_consumer_key    => SELF.oauth_consumer_key,
                                       p_timestamp       => SELF.oauth_timestamp,
                                       p_nonce           => SELF.oauth_nonce,
                                       p_signature       => SELF.oauth_signature,
                                       p_token           => SELF.oauth_access_token,
                                       p_verifier        => NULL);
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
      /*
               SELECT    '<return_code><pass userid="LNKD_'
                      || EXTRACTVALUE (l_xml, '/person/id')
                      || '" username="'
                      || EXTRACTVALUE (l_xml, '/person/first-name')
                      || ' '
                      || EXTRACTVALUE (l_xml, '/person/last-name')
                      || '" /></return_code>'
                 INTO l_html
                 FROM DUAL;

               OWA_UTIL.mime_header ('text/xml', TRUE, 'utf-8');
               HTP.p (l_html);*/
      END IF;
   END get_profile;

   MEMBER PROCEDURE gcal_create_event (p_start   IN DATE DEFAULT SYSDATE,
                                                       p_end     IN DATE DEFAULT (SYSDATE + 1),
                                                       p_title   IN VARCHAR2 DEFAULT 'title',
                                                       p_note    IN VARCHAR2 DEFAULT 'dummy event')
   IS
      http_method   CONSTANT VARCHAR2 (5) := 'POST';
      http_req               UTL_HTTP.req;
      http_resp              UTL_HTTP.resp;                                                                        --https://www.googleapis.com/calendar/v3/calendars/primary/events
      h_name                 VARCHAR2 (255);
      h_value                VARCHAR2 (1023);
      oauth_api_url          VARCHAR2 (1000) := 'https://www.googleapis.com/calendar/v3/calendars/kd14ahr5mr2c2lcq1dfg9mghs4@group.calendar.google.com/events';
      var_http_post_params   VARCHAR2 (2048);
      l_clob                 CLOB;
      l_text                 VARCHAR2 (32767);
      var_http_resp_value    VARCHAR2 (32767);
   BEGIN
      var_http_post_params :=
            '{
                 "summary": "'
         || p_title
         || '",
                 "description": "'||p_note||'",
                 "location": "EuroStrategy.net",
                 "start": {
                  "dateTime": "'
         || TO_CHAR (p_start, 'YYYY-MM-DD"T"HH24:MI:SS')
         || '.000'
         || '",
                  "timeZone": "UTC"
                 },
                 "end": {
                  "dateTime": "'
         || TO_CHAR (p_end, 'YYYY-MM-DD"T"HH24:MI:SS')
         || '.000'
         || '",
                  "timeZone": "UTC"
                 }
                }';
      /*
     {
    "summary": "Appointment",
    "location": "Somewhere",
    "start": {
      "dateTime": "2012-02-23T10:00:00.000-07:00"
    },
    "end": {
      "dateTime": "2012-02-23T10:25:00.000-07:00"
    },
   }
     */
      UTL_HTTP.set_wallet (PATH => global_constants.con_str_wallet_path, PASSWORD => global_constants.con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);

      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_body_charset (http_req, 'UTF-8');
      UTL_HTTP.set_header (http_req, 'User-Agent', 'Mozilla/4.0');
      UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => 'OAuth ' || SELF.oauth_access_token);
      UTL_HTTP.set_header (r => http_req, name => 'Content-Type', VALUE => 'application/json');
      --UTL_HTTP.set_header (r => http_req, name => 'Content-length', VALUE => 0);
      --UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/x-www-form-urlencoded');
      UTL_HTTP.set_header (r => http_req, NAME => 'Content-Length', VALUE => LENGTH (var_http_post_params));
      UTL_HTTP.write_text (http_req, var_http_post_params);
      http_resp := UTL_HTTP.get_response (http_req);

      FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
      LOOP
         UTL_HTTP.get_header (http_resp,
                              i,
                              h_name,
                              h_value);
      --DBMS_OUTPUT.put_line (h_name || ': ' || h_value);
      END LOOP;

      DBMS_LOB.createtemporary (l_clob, FALSE);

      BEGIN
         WHILE 1 = 1
         LOOP
            --UTL_HTTP.read_text (http_resp, l_text, 32766);
            --DBMS_LOB.writeappend (l_clob, LENGTH (l_text), l_text);
            UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);
            --DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);
            --HTP.p (var_http_resp_value);
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      UTL_HTTP.end_response (http_resp);
   END;
END;
/
