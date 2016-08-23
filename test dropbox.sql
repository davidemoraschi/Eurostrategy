/* Formatted on 11/18/2011 8:58:31 AM (QP5 v5.163.1008.3004) */
DECLARE
   my_dropbox                  dropbox;
   p_credentials_in_response   CLOB;
BEGIN
   --   my_dropbox := NEW dropbox (id => 'EuroStrategy', oauth_consumer_key => '5dlgdhkctfn4ngq', oauth_consumer_secret => 'dgkduksn1pdxltm');
   --   my_dropbox.save;

   SELECT obj_dropbox
     INTO my_dropbox
     FROM OBJS_DROPBOX
    WHERE ROWNUM = 1;

   my_dropbox.get_account_info (p_credentials_in_response => p_credentials_in_response);
--   DBMS_OUTPUT.put_line ('Consumer key:         ' || my_linkedin.oauth_consumer_key);
--   DBMS_OUTPUT.put_line ('Consumer Secret:      ' || my_linkedin.oauth_consumer_secret);
--   DBMS_OUTPUT.put_line ('api_url:              ' || my_linkedin.oauth_api_url);
--   DBMS_OUTPUT.put_line ('oauth_timestamp:      ' || my_linkedin.oauth_timestamp);
--   DBMS_OUTPUT.put_line ('oauth_nonce:          ' || my_linkedin.oauth_nonce);
--   DBMS_OUTPUT.put_line ('oauth_callback:       ' || my_linkedin.oauth_callback);
--   DBMS_OUTPUT.put_line ('oauth_base_string:    ' || my_linkedin.oauth_base_string);
--   DBMS_OUTPUT.put_line ('oauth_signature:      ' || my_linkedin.oauth_signature);
--   DBMS_OUTPUT.put_line ('authorization_header: ' || my_linkedin.var_http_authorization_header);
END;
/