/* Formatted on 11/18/2011 12:15:19 PM (QP5 v5.163.1008.3004) */
DROP TABLE objs_dropbox;

SET DEFINE OFF

DECLARE
   n   NUMBER;
BEGIN
   SELECT COUNT (*)
     INTO n
     FROM user_objects
    WHERE object_NAME = 'DROPBOX';

   IF n > 0
   THEN
      EXECUTE IMMEDIATE 'DROP TYPE DROPBOX';
   END IF;
--   SELECT COUNT (*)
--     INTO n
--     FROM user_objects
--    WHERE object_NAME = 'OAUTH';
--
--   IF n > 0
--   THEN
--      EXECUTE IMMEDIATE 'DROP TYPE OAUTH';
--   END IF;
END;

CREATE TYPE DROPBOX
          UNDER OAUTH
       (oauth_callback VARCHAR2 (1000),
        oauth_api_version NUMBER,
        CONSTRUCTOR FUNCTION DROPBOX (id                      IN VARCHAR2 DEFAULT 'test',
                                      oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                      oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                      oauth_callback          IN VARCHAR2 DEFAULT 'oob')
           RETURN SELF AS RESULT,
        MEMBER PROCEDURE save,
        MEMBER PROCEDURE upgrade_token,
        MEMBER PROCEDURE get_account_info (p_callback IN VARCHAR2 DEFAULT NULL, p_credentials_in_response OUT XMLTYPE));

CREATE OR REPLACE TYPE BODY dropbox
AS
   CONSTRUCTOR FUNCTION dropbox (id                      IN VARCHAR2 DEFAULT 'test',
                                 oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                 oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                 oauth_callback          IN VARCHAR2 DEFAULT 'oob')
      RETURN SELF AS RESULT
   IS
      http_method           CONSTANT VARCHAR2 (5) := 'POST';
      http_req                       UTL_HTTP.req;
      http_resp                      UTL_HTTP.resp;
      var_http_header_name           VARCHAR2 (255);
      var_http_header_value          VARCHAR2 (1023);
      var_http_resp_value            VARCHAR2 (32767);
      con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;                --'file:C:\INyDIA\wallet';
      con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;                          --'Lepanto1571';
   BEGIN
      SELF.id := id;
      SELF.con_num_timestamp_tz_diff := pq_constants.con_num_timestamp_tz_diff;
      SELF.oauth_consumer_key := oauth_consumer_key;
      SELF.oauth_consumer_secret := oauth_consumer_secret;
      SELF.oauth_api_version := 1;
      SELF.oauth_callback := oauth_callback;
      SELF.oauth_api_request_token_url := 'https://api.dropbox.com/' || SELF.oauth_api_version || '/oauth/request_token';
      SELF.oauth_api_authorization_url :=
         'https://www.dropbox.com/' || SELF.oauth_api_version || '/oauth/authorize?oauth_callback=' || SELF.oauth_callback;
      SELF.oauth_api_access_token_url := 'https://api.dropbox.com/' || SELF.oauth_api_version || '/oauth/access_token';
      SELF.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));
      SELF.oauth_base_string :=
         SELF.base_string (p_http_method         => http_method,
                           p_request_token_url   => SELF.oauth_api_request_token_url,
                           p_callback_url        => SELF.oauth_callback,
                           p_consumer_key        => SELF.oauth_consumer_key,
                           p_timestamp           => SELF.oauth_timestamp,
                           p_nonce               => SELF.oauth_nonce);
      SELF.oauth_signature :=
         SELF.signature (p_oauth_base_string   => SELF.oauth_base_string,
                         p_oauth_key           => SELF.key_token (SELF.oauth_consumer_secret, NULL));
      SELF.var_http_authorization_header :=
         SELF.authorization_header (p_callback_url   => SELF.oauth_callback,
                                    p_consumer_key   => SELF.oauth_consumer_key,
                                    p_timestamp      => SELF.oauth_timestamp,
                                    p_nonce          => SELF.oauth_nonce,
                                    p_signature      => SELF.oauth_signature);
      --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, password => con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (SELF.oauth_api_request_token_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => SELF.var_http_authorization_header);
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
               SELF.oauth_request_token_secret := SELF.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token_secret');
               SELF.oauth_request_token := SELF.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token');
               DBMS_OUTPUT.put_line ('oauth_token          : ' || SELF.oauth_request_token);
               DBMS_OUTPUT.put_line ('oauth_token_secret   : ' || SELF.oauth_request_token_secret);
               SELF.id := SELF.oauth_request_token;
               SELF.oauth_api_authorization_url := SELF.oauth_api_authorization_url || '&oauth_token=' || SELF.oauth_request_token;
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

   MEMBER PROCEDURE save
   IS
   BEGIN
      UPDATE objs_dropbox c
         SET c.obj_dropbox = SELF
       WHERE account = SELF.id;

      IF SQL%ROWCOUNT = 0
      THEN
         INSERT INTO objs_dropbox
              VALUES (SELF.id, SYSTIMESTAMP, SELF);
      END IF;
   END;

   MEMBER PROCEDURE upgrade_token
   IS
      http_method           CONSTANT VARCHAR2 (5) := 'GET';
      http_req                       UTL_HTTP.req;
      http_resp                      UTL_HTTP.resp;
      var_http_header_name           VARCHAR2 (255);
      var_http_header_value          VARCHAR2 (1023);
      var_http_resp_value            VARCHAR2 (32767);
      con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;                --'file:C:\INyDIA\wallet';
      con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;                          --'Lepanto1571';
   BEGIN
      SELF.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      SELF.oauth_nonce := SELF.urlencode (SUBSTR (oauth_timestamp, 6));

      SELF.oauth_base_string :=
         SELF.base_string (p_http_method         => http_method,
                           p_request_token_url   => SELF.oauth_api_access_token_url,
                           --p_callback_url        => SELF.oauth_callback,
                           p_consumer_key        => SELF.oauth_consumer_key,
                           p_timestamp           => SELF.oauth_timestamp,
                           p_nonce               => SELF.oauth_nonce,
                           p_token               => SELF.oauth_request_token,
                           p_token_verifier      => NULL);
      SELF.oauth_signature :=
         SELF.signature (p_oauth_base_string   => SELF.oauth_base_string,
                         p_oauth_key           => SELF.key_token (SELF.oauth_consumer_secret, SELF.oauth_request_token_secret));
      SELF.var_http_authorization_header :=
            'OAuth'
         || ' oauth_nonce="'
         || SELF.oauth_nonce
         || '" oauth_timestamp="'
         || SELF.oauth_timestamp
         || '" oauth_version="1.0" oauth_signature_method="HMAC-SHA1"'
         || ' oauth_consumer_key="'
         || SELF.oauth_consumer_key
         || '" oauth_token="'
         || SELF.oauth_request_token
         || '" oauth_signature="'
         || SELF.urlencode (oauth_signature)
         || '"';
      SELF.oauth_api_access_token_url :=
            SELF.oauth_api_access_token_url
         || '?'
         || 'oauth_consumer_key='
         || SELF.oauth_consumer_key
         || '&oauth_nonce='
         || SELF.oauth_nonce
         || '&oauth_signature='
         || SELF.urlencode (oauth_signature)
         || '&oauth_signature_method=HMAC-SHA1&oauth_timestamp='
         || SELF.oauth_timestamp
         || '&oauth_token='
         || SELF.oauth_request_token
         || '&oauth_version=1.0';
      --UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);

      DBMS_OUTPUT.put_line ('oauth_consumer_key : ' || SELF.oauth_consumer_key);
      DBMS_OUTPUT.put_line ('oauth_consumer_secret : ' || SELF.oauth_consumer_secret);
      DBMS_OUTPUT.put_line ('oauth_request_token : ' || SELF.oauth_request_token);
      DBMS_OUTPUT.put_line ('oauth_request_token_secret : ' || SELF.oauth_request_token_secret);
      DBMS_OUTPUT.put_line ('oauth_nonce : ' || SELF.oauth_nonce);
      DBMS_OUTPUT.put_line ('oauth_timestamp : ' || SELF.oauth_timestamp);
      DBMS_OUTPUT.put_line ('oauth_base_string : ' || SELF.oauth_base_string);
      DBMS_OUTPUT.put_line ('oauth_signature : ' || SELF.oauth_signature);
      DBMS_OUTPUT.put_line ('var_http_authorization_header : ' || SELF.var_http_authorization_header);
      DBMS_OUTPUT.put_line ('oauth_api_access_token_url : ' || SELF.oauth_api_access_token_url);

      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, PASSWORD => con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (SELF.oauth_api_access_token_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, NAME => 'Authorization', VALUE => SELF.var_http_authorization_header);
      --UTL_HTTP.set_header (r => http_req, name => 'Content-Type', VALUE => 'text/xml');
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

   MEMBER PROCEDURE get_account_info (p_callback IN VARCHAR2 DEFAULT NULL, p_credentials_in_response OUT XMLTYPE)
   IS
      http_method           CONSTANT VARCHAR2 (5) := 'GET';
      oauth_api_url                  VARCHAR2 (1000) := 'https://api.dropbox.com/' || SELF.oauth_api_version || '/account/info';
      http_req                       UTL_HTTP.req;
      http_resp                      UTL_HTTP.resp;
      var_http_header_name           VARCHAR2 (255);
      var_http_header_value          VARCHAR2 (1023);
      var_http_resp_value            VARCHAR2 (32767);
      con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;                --'file:C:\INyDIA\wallet';
      con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;                          --'Lepanto1571';
      l_clob                         CLOB;
      l_xml                          XMLTYPE;
      l_html                         VARCHAR2 (32767);
   BEGIN
      SELF.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
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
         SELF.signature (p_oauth_base_string   => SELF.oauth_base_string,
                         p_oauth_key           => SELF.key_token (SELF.oauth_consumer_secret, SELF.oauth_access_token_secret));
      SELF.var_http_authorization_header :=
            'OAuth'
         || ' oauth_nonce="'
         || SELF.oauth_nonce
         || '" oauth_timestamp="'
         || SELF.oauth_timestamp
         || '" oauth_version="1.0" oauth_signature_method="HMAC-SHA1'
         || '" oauth_consumer_key="'
         || SELF.oauth_consumer_key
         || '" oauth_token="'
         || SELF.oauth_access_token
         || '" oauth_signature="'
         || SELF.urlencode (oauth_signature)
         || '"';

      oauth_api_url :=
            oauth_api_url
         || '?'
         || 'oauth_consumer_key='
         || SELF.oauth_consumer_key
         || '&oauth_nonce='
         || SELF.oauth_nonce
         || '&oauth_signature='
         || SELF.urlencode (oauth_signature)
         || '&oauth_signature_method=HMAC-SHA1'
         || '&oauth_timestamp='
         || SELF.oauth_timestamp
         || '&oauth_token='
         || SELF.oauth_access_token
         || '&oauth_version=1.0';

      --      DBMS_OUTPUT.put_line ('oauth_consumer_key : ' || SELF.oauth_consumer_key);
      --      DBMS_OUTPUT.put_line ('oauth_consumer_secret : ' || SELF.oauth_consumer_secret);
      --      DBMS_OUTPUT.put_line ('oauth_access_token : ' || SELF.oauth_access_token);
      --      DBMS_OUTPUT.put_line ('oauth_access_token_secret : ' || SELF.oauth_access_token_secret);
      --      DBMS_OUTPUT.put_line ('oauth_nonce : ' || SELF.oauth_nonce);
      --      DBMS_OUTPUT.put_line ('oauth_timestamp : ' || SELF.oauth_timestamp);
      --      DBMS_OUTPUT.put_line ('oauth_base_string : ' || SELF.oauth_base_string);
      --      DBMS_OUTPUT.put_line ('oauth_signature : ' || SELF.oauth_signature);
      --      DBMS_OUTPUT.put_line ('var_http_authorization_header : ' || SELF.var_http_authorization_header);
      --      DBMS_OUTPUT.put_line ('oauth_api_url : ' || oauth_api_url);

      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, PASSWORD => con_str_wallet_pass);
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
            --DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);
            DBMS_LOB.writeappend (l_clob, LENGTH (var_http_resp_value), var_http_resp_value);
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      p_credentials_in_response := xmltype (l_clob);

      UTL_HTTP.end_response (http_resp);
      -- HTP.p (l_clob);
      DBMS_LOB.freetemporary (l_clob);
   END get_account_info;
END;
/

SHOW ERR;

CREATE TABLE objs_dropbox
(
   account         VARCHAR2 (50),
   creation_date   TIMESTAMP WITH TIME ZONE,
   obj_dropbox     dropbox,
   CONSTRAINT objects_dropbox_pk PRIMARY KEY (account)
);

/