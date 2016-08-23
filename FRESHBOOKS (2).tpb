/* Formatted on 12/1/2011 1:18:12 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE TYPE BODY EUROSTAT.freshbooks
AS
   CONSTRUCTOR FUNCTION freshbooks (id                      IN VARCHAR2 DEFAULT 'test',
                                    oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                    oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                    oauth_callback          IN VARCHAR2 DEFAULT 'oob')
      RETURN SELF AS RESULT
   IS
      http_method               CONSTANT VARCHAR2 (5) := 'POST';
      http_req                           UTL_HTTP.req;
      http_resp                          UTL_HTTP.resp;
      var_http_header_name               VARCHAR2 (255);
      var_http_header_value              VARCHAR2 (1023);
      var_http_resp_value                VARCHAR2 (32767);
      con_str_wallet_path       CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;
      con_str_wallet_pass       CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;
      con_str_freshbooks_site   CONSTANT VARCHAR2 (100) := 'moraschi';
   BEGIN
      self.id := id;
      self.con_num_timestamp_tz_diff := pq_constants.con_num_timestamp_tz_diff;
      self.oauth_consumer_key := oauth_consumer_key;
      self.oauth_consumer_secret := oauth_consumer_secret;
      self.oauth_api_version := 0;
      self.oauth_callback := oauth_callback;
      self.oauth_api_request_token_url := 'https://' || con_str_freshbooks_site || '.freshbooks.com/oauth/oauth_request.php';
      self.oauth_api_authorization_url := 'https://' || con_str_freshbooks_site || '.freshbooks.com/oauth/oauth_authorize.php';
      self.oauth_api_access_token_url := 'https://' || con_str_freshbooks_site || '.freshbooks.com/oauth/oauth_access.php';
      self.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      self.oauth_nonce := self.urlencode (SUBSTR (oauth_timestamp, 6));
      self.oauth_signature := (urlencode (self.oauth_consumer_secret) || '&');
      self.var_http_authorization_header :=
         self.authorization_header (p_callback_url   => self.oauth_callback,
                                    p_consumer_key   => self.oauth_consumer_key,
                                    p_timestamp      => self.oauth_timestamp,
                                    p_nonce          => self.oauth_nonce,
                                    p_signature      => self.oauth_signature);

      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, password => con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (self.oauth_api_request_token_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => self.var_http_authorization_header);
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

            --DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);

            IF INSTR (var_http_resp_value, 'oauth_token=') > 0
            THEN
               self.oauth_request_token_secret := self.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token_secret');
               self.oauth_request_token := self.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token');
               --DBMS_OUTPUT.put_line ('oauth_token          : ' || self.oauth_request_token);
               --DBMS_OUTPUT.put_line ('oauth_token_secret   : ' || self.oauth_request_token_secret);
               self.id := self.oauth_request_token;
               self.oauth_api_authorization_url := self.oauth_api_authorization_url || '?oauth_token=' || self.oauth_request_token;
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
      UPDATE objs_freshbooks c
         SET c.obj_freshbooks = self
       WHERE account = self.id;

      IF SQL%ROWCOUNT = 0
      THEN
         INSERT INTO objs_freshbooks
              VALUES (self.id, SYSTIMESTAMP, self);
      END IF;
   END;

   MEMBER PROCEDURE upgrade_token
   IS
      http_method           CONSTANT VARCHAR2 (5) := 'POST';
      http_req                       UTL_HTTP.req;
      http_resp                      UTL_HTTP.resp;
      var_http_header_name           VARCHAR2 (255);
      var_http_header_value          VARCHAR2 (1023);
      var_http_resp_value            VARCHAR2 (32767);
      con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;
      con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;
   BEGIN
      self.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      self.oauth_nonce := self.urlencode (SUBSTR (oauth_timestamp, 6));

      self.oauth_signature := (urlencode (self.oauth_consumer_secret) || '&');
      self.var_http_authorization_header :=
            'OAuth'
         || ' oauth_nonce="'
         || self.oauth_nonce
         || '", oauth_signature_method="PLAINTEXT", oauth_timestamp="'
         || self.oauth_timestamp
         || '", oauth_consumer_key="'
         || self.oauth_consumer_key
         || '", oauth_token="'
         || self.oauth_request_token
         || '", oauth_verifier="'
         || self.oauth_verifier
         || '", oauth_signature="'
         || self.urlencode (oauth_signature)
         || '", oauth_version="1.0"';
      --

      self.oauth_api_access_token_url :=
            self.oauth_api_access_token_url
         || '?'
         || 'oauth_consumer_key='
         || self.oauth_consumer_key
         || '&oauth_token='
         || self.oauth_request_token;

      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, password => con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (self.oauth_api_access_token_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => self.var_http_authorization_header);
      http_resp := UTL_HTTP.get_response (http_req);

      -- reads the Headers
      FOR i IN 1 .. UTL_HTTP.get_header_count (http_resp)
      LOOP
         UTL_HTTP.get_header (http_resp,
                              i,
                              var_http_header_name,
                              var_http_header_value);
      --      DBMS_OUTPUT.put_line (var_http_header_name || ': ' || var_http_header_value);
      END LOOP;

      -- reads the Content
      BEGIN
         WHILE TRUE
         LOOP
            UTL_HTTP.read_line (http_resp, var_http_resp_value, TRUE);

            --            DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);

            IF INSTR (var_http_resp_value, 'oauth_token=') > 0
            THEN
               self.oauth_access_token := self.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token');
               self.oauth_access_token_secret := self.token_extract (p_str => var_http_resp_value, p_pat => 'oauth_token_secret');
            --               DBMS_OUTPUT.put_line ('oauth_token          : ' || self.oauth_access_token);
            --               DBMS_OUTPUT.put_line ('oauth_token_secret   : ' || self.oauth_access_token_secret);
            END IF;
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      UTL_HTTP.end_response (http_resp);
   END upgrade_token;

   MEMBER PROCEDURE system_current (p_callback IN VARCHAR2 DEFAULT NULL, p_credentials_in_response OUT XMLTYPE)
   IS
      http_method           CONSTANT VARCHAR2 (5) := 'POST';
      oauth_api_url                  VARCHAR2 (1000) := 'https://moraschi.freshbooks.com/api/2.1/xml-in';
      http_req                       UTL_HTTP.req;
      http_resp                      UTL_HTTP.resp;
      var_http_header_name           VARCHAR2 (255);
      var_http_header_value          VARCHAR2 (1023);
      var_http_resp_value            VARCHAR2 (32767);
      con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;
      con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;
      l_clob                         CLOB;
      l_xml                          XMLTYPE;
      l_xml_request                  XMLTYPE
         := XMLTYPE ('<!--?xml version="1.0" encoding="utf-8"?--><request method="system.current"></request>');
      l_html                         VARCHAR2 (32767);
   BEGIN
      self.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      self.oauth_nonce := self.urlencode (SUBSTR (oauth_timestamp, 6));

      self.oauth_signature := (urlencode (self.oauth_consumer_secret) || '&' || urlencode (self.oauth_access_token_secret));
      self.var_http_authorization_header :=
            'OAuth'
         || ' oauth_consumer_key="'
         || self.oauth_consumer_key
         || '", oauth_nonce="'
         || self.oauth_nonce
         || '", oauth_signature="'
         || self.urlencode (oauth_signature)
         || '", oauth_signature_method="PLAINTEXT", oauth_timestamp="'
         || self.oauth_timestamp
         || '", oauth_token="'
         || self.oauth_access_token
         || '", oauth_version="1.0"';

      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, password => con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => var_http_authorization_header);
      UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/atom+xml;charset=iso-8859-1');
      UTL_HTTP.set_header (r => http_req, NAME => 'Content-Length', VALUE => LENGTH (l_xml_request.getclobval ()));

      UTL_HTTP.set_cookie_support (r => http_req, ENABLE => TRUE);
      UTL_HTTP.write_text (http_req, l_xml_request.getclobval ());

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
      --HTP.p (l_clob);
      DBMS_LOB.freetemporary (l_clob);
   END system_current;

   MEMBER PROCEDURE project_list (p_callback IN VARCHAR2 DEFAULT NULL, p_projects_in_response OUT XMLTYPE)
   IS
      http_method           CONSTANT VARCHAR2 (5) := 'POST';
      oauth_api_url                  VARCHAR2 (1000) := 'https://moraschi.freshbooks.com/api/2.1/xml-in';
      http_req                       UTL_HTTP.req;
      http_resp                      UTL_HTTP.resp;
      var_http_header_name           VARCHAR2 (255);
      var_http_header_value          VARCHAR2 (1023);
      var_http_resp_value            VARCHAR2 (32767);
      con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;
      con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;
      l_clob                         CLOB;
      l_xml                          XMLTYPE;
      l_xml_request                  XMLTYPE
         := XMLTYPE ('<?xml version="1.0" encoding="utf-8"?><request method="project.list"></request>');
      --      l_xml_request                  XMLTYPE
      --         := XMLTYPE ('<!--?xml version="1.0" encoding="utf-8"?--><request method="task.list"><project_id>5</project_id></request>');
      l_html                         VARCHAR2 (32767);
   BEGIN
      self.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      self.oauth_nonce := self.urlencode (SUBSTR (oauth_timestamp, 6));

      self.oauth_signature := (urlencode (self.oauth_consumer_secret) || '&' || urlencode (self.oauth_access_token_secret));
      self.var_http_authorization_header :=
            'OAuth'
         || ' oauth_consumer_key="'
         || self.oauth_consumer_key
         || '", oauth_nonce="'
         || self.oauth_nonce
         || '", oauth_signature="'
         || self.urlencode (oauth_signature)
         || '", oauth_signature_method="PLAINTEXT", oauth_timestamp="'
         || self.oauth_timestamp
         || '", oauth_token="'
         || self.oauth_access_token
         || '", oauth_version="1.0"';

      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, password => con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => var_http_authorization_header);
      UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/atom+xml;charset=iso-8859-1');
      UTL_HTTP.set_header (r => http_req, NAME => 'Content-Length', VALUE => LENGTH (l_xml_request.getclobval ()));

      UTL_HTTP.set_cookie_support (r => http_req, ENABLE => TRUE);
      UTL_HTTP.write_text (http_req, l_xml_request.getclobval ());

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

      p_projects_in_response := xmltype (l_clob);

      UTL_HTTP.end_response (http_resp);
      --HTP.p (l_clob);
      DBMS_LOB.freetemporary (l_clob);
   END project_list;

   MEMBER PROCEDURE time_entry_create (p_callback   IN     VARCHAR2 DEFAULT NULL,
                                       p_response      OUT XMLTYPE,
                                       p_date       IN     VARCHAR2 := TO_CHAR (SYSDATE, 'yyyy-mm-dd'),
                                       p_hours      IN     VARCHAR2 := 1,
                                       p_notes      IN     VARCHAR2 := 'Report Execution')
   IS
      http_method           CONSTANT VARCHAR2 (5) := 'POST';
      oauth_api_url                  VARCHAR2 (1000) := 'https://moraschi.freshbooks.com/api/2.1/xml-in';
      http_req                       UTL_HTTP.req;
      http_resp                      UTL_HTTP.resp;
      var_http_header_name           VARCHAR2 (255);
      var_http_header_value          VARCHAR2 (1023);
      var_http_resp_value            VARCHAR2 (32767);
      con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;
      con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;
      l_clob                         CLOB;
      l_xml                          XMLTYPE;
      l_xml_request                  XMLTYPE
         := XMLTYPE (
               '<?xml version="1.0" encoding="utf-8"?><request method="time_entry.create"><time_entry><project_id>5</project_id><task_id>11</task_id><hours>'
               || p_hours
               || '</hours><notes>'
               || p_notes
               || '</notes><date>'
               || p_date
               || '</date></time_entry></request>');
      l_html                         VARCHAR2 (32767);
   BEGIN
      self.oauth_timestamp :=
         TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - con_num_timestamp_tz_diff));
      self.oauth_nonce := self.urlencode (SUBSTR (oauth_timestamp, 6));

      self.oauth_signature := (urlencode (self.oauth_consumer_secret) || '&' || urlencode (self.oauth_access_token_secret));
      self.var_http_authorization_header :=
            'OAuth'
         || ' oauth_consumer_key="'
         || self.oauth_consumer_key
         || '", oauth_nonce="'
         || self.oauth_nonce
         || '", oauth_signature="'
         || self.urlencode (oauth_signature)
         || '", oauth_signature_method="PLAINTEXT", oauth_timestamp="'
         || self.oauth_timestamp
         || '", oauth_token="'
         || self.oauth_access_token
         || '", oauth_version="1.0"';

      UTL_HTTP.set_wallet (PATH => con_str_wallet_path, password => con_str_wallet_pass);
      UTL_HTTP.set_response_error_check (FALSE);
      UTL_HTTP.set_detailed_excp_support (FALSE);
      http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);
      UTL_HTTP.set_header (r => http_req, name => 'Authorization', VALUE => var_http_authorization_header);
      UTL_HTTP.set_header (r => http_req, NAME => 'Content-Type', VALUE => 'application/atom+xml;charset=iso-8859-1');
      UTL_HTTP.set_header (r => http_req, NAME => 'Content-Length', VALUE => LENGTH (l_xml_request.getclobval ()));

      UTL_HTTP.set_cookie_support (r => http_req, ENABLE => TRUE);
      UTL_HTTP.write_text (http_req, l_xml_request.getclobval ());

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
            DBMS_OUTPUT.put_line ('Resp : ' || var_http_resp_value);
            DBMS_LOB.writeappend (l_clob, LENGTH (var_http_resp_value), var_http_resp_value);
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      p_response := xmltype (l_clob);

      UTL_HTTP.end_response (http_resp);
      --HTP.p (l_clob);
      DBMS_LOB.freetemporary (l_clob);
   END time_entry_create;

   OVERRIDING MEMBER FUNCTION authorization_header (p_callback_url   IN VARCHAR2 DEFAULT NULL,
                                                    p_consumer_key   IN VARCHAR2,
                                                    p_timestamp      IN VARCHAR2,
                                                    p_nonce          IN VARCHAR2,
                                                    p_signature      IN VARCHAR2,
                                                    p_token          IN VARCHAR2 DEFAULT NULL,
                                                    p_verifier       IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      v_authorization_header   VARCHAR2 (4000);
   BEGIN
      v_authorization_header :=
            'OAuth realm="",oauth_callback="'
         || p_callback_url
         || '",oauth_version="1.0",oauth_consumer_key="'
         || p_consumer_key
         || '",oauth_timestamp="'
         || p_timestamp
         || '",oauth_nonce="'
         || p_nonce
         || '",oauth_signature_method="PLAINTEXT",oauth_signature="'
         || urlencode (p_signature)
         || '"';
      RETURN v_authorization_header;
   END authorization_header;
END;
/