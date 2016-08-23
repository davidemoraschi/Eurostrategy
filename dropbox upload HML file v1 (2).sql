/* Formatted on 11/18/2011 1:38:05 PM (QP5 v5.163.1008.3004) */
SET DEFINE OFF

DECLARE
   con_str_wallet_path   CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;                   --'file:C:\INyDIA\wallet';
   con_str_wallet_pass   CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;                             --'Lepanto1571';
   v_obj_dropbox                  dropbox;
   http_method           CONSTANT VARCHAR2 (5) := 'POST';
   oauth_api_url                  VARCHAR2 (1000);
   http_req                       UTL_HTTP.req;
   http_resp                      UTL_HTTP.resp;
   var_http_header_name           VARCHAR2 (255);
   var_http_header_value          VARCHAR2 (1023);
   var_http_resp_value            VARCHAR2 (32767);
   l_clob                         CLOB;
   msg_multipart                  VARCHAR2 (32767) := NULL;
   l_multipart                    NUMBER;
   crlf                  CONSTANT VARCHAR2 (2) := CHR (13) || CHR (10);
BEGIN
   SELECT (obj_dropbox)
     INTO v_obj_dropbox
     FROM objs_dropbox
    WHERE ACCOUNT = '35291135';

   oauth_api_url := 'https://api-content.dropbox.com/' || v_obj_dropbox.oauth_api_version || '/files/dropbox/Public';

   v_obj_dropbox.oauth_timestamp :=
      TO_CHAR (TRUNC ( (SYSDATE - TO_DATE ('01-01-1970', 'DD-MM-YYYY')) * (86400) - pq_constants.con_num_timestamp_tz_diff));
   v_obj_dropbox.oauth_nonce := v_obj_dropbox.urlencode (SUBSTR (v_obj_dropbox.oauth_timestamp, 6));
   v_obj_dropbox.oauth_base_string :=
      http_method || '&' || v_obj_dropbox.urlencode (oauth_api_url) || '&' || v_obj_dropbox.urlencode ('file=helloworld.htm')
      || v_obj_dropbox.urlencode (
               '&oauth_consumer_key='
            || v_obj_dropbox.urlencode (v_obj_dropbox.oauth_consumer_key)
            || '&oauth_nonce='
            || v_obj_dropbox.oauth_nonce
            || '&oauth_signature_method=HMAC-SHA1&oauth_timestamp='
            || v_obj_dropbox.oauth_timestamp
            || '&oauth_token='
            || v_obj_dropbox.urlencode (v_obj_dropbox.oauth_access_token)
            || '&oauth_version=1.0');

   v_obj_dropbox.oauth_signature :=
      v_obj_dropbox.signature (
         p_oauth_base_string   => v_obj_dropbox.oauth_base_string,
         p_oauth_key           => v_obj_dropbox.key_token (v_obj_dropbox.oauth_consumer_secret,
                                                           v_obj_dropbox.oauth_access_token_secret));
   oauth_api_url :=
         oauth_api_url
      || '?'
      || 'oauth_consumer_key='
      || v_obj_dropbox.oauth_consumer_key
      || '&oauth_nonce='
      || v_obj_dropbox.oauth_nonce
      || '&oauth_signature='
      || v_obj_dropbox.urlencode (v_obj_dropbox.oauth_signature)
      || '&oauth_signature_method=HMAC-SHA1'
      || '&oauth_timestamp='
      || v_obj_dropbox.oauth_timestamp
      || '&oauth_token='
      || v_obj_dropbox.oauth_access_token
      || '&oauth_version=1.0';

   /*
      DBMS_OUTPUT.put_line ('oauth_consumer_key : ' || v_obj_dropbox.oauth_consumer_key);
      DBMS_OUTPUT.put_line ('oauth_consumer_secret : ' || v_obj_dropbox.oauth_consumer_secret);
      DBMS_OUTPUT.put_line ('oauth_access_token : ' || v_obj_dropbox.oauth_access_token);
      DBMS_OUTPUT.put_line ('oauth_access_token_secret : ' || v_obj_dropbox.oauth_access_token_secret);
      DBMS_OUTPUT.put_line ('oauth_nonce : ' || v_obj_dropbox.oauth_nonce);
      DBMS_OUTPUT.put_line ('oauth_timestamp : ' || v_obj_dropbox.oauth_timestamp);
      DBMS_OUTPUT.put_line ('oauth_base_string : ' || v_obj_dropbox.oauth_base_string);
      DBMS_OUTPUT.put_line ('oauth_signature : ' || v_obj_dropbox.oauth_signature);
      DBMS_OUTPUT.put_line ('var_http_authorization_header : ' || v_obj_dropbox.var_http_authorization_header);
      DBMS_OUTPUT.put_line ('oauth_api_url : ' || oauth_api_url);
   */
   UTL_HTTP.set_wallet (PATH => con_str_wallet_path, PASSWORD => con_str_wallet_pass);
   UTL_HTTP.set_response_error_check (FALSE);
   UTL_HTTP.set_detailed_excp_support (FALSE);
   http_req := UTL_HTTP.begin_request (oauth_api_url, http_method, UTL_HTTP.http_version_1_1);


   UTL_HTTP.Set_Header (r       => http_req,
                        name    => 'Content-Type',
                        VALUE   => 'multipart/form-data; boundary=---------------------------7d5b36e0752');

   --Creating the message, detecting its size...
   msg_multipart := msg_multipart || '-----------------------------7d5b36e0752' || crlf;
   msg_multipart := msg_multipart || 'Content-Disposition: form-data; name="file"; filename="helloworld.htm"' || crlf;
   msg_multipart := msg_multipart || 'Content-Type: text/html' || crlf;
   msg_multipart := msg_multipart || crlf;
   msg_multipart := msg_multipart || '<h1>Hello España</h1>';
   l_multipart := LENGTH (msg_multipart);
   msg_multipart := msg_multipart || '-----------------------------7d5b36e0752' || crlf;

   UTL_HTTP.Set_Header (r => http_req, name => 'Content-Length', VALUE => TO_CHAR (l_multipart));
   UTL_HTTP.write_text (http_req, msg_multipart);

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
      --DBMS_LOB.writeappend (l_clob, LENGTH (var_http_resp_value), var_http_resp_value);
      END LOOP;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         NULL;
   END;

   --l_xml := xmltype (l_clob);

   UTL_HTTP.end_response (http_resp);
   --HTP.p (l_clob);
   DBMS_LOB.freetemporary (l_clob);
END;