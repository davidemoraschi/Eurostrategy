/* Formatted on 12/1/2011 1:13:14 PM (QP5 v5.163.1008.3004) */
DECLARE
   my_freshbooks               freshbooks;
   p_credentials_in_response   XMLTYPE;
   p_response                  XMLTYPE;
BEGIN
   --   my_dropbox := NEW dropbox (id => 'EuroStrategy', oauth_consumer_key => '5dlgdhkctfn4ngq', oauth_consumer_secret => 'dgkduksn1pdxltm');
   --   my_dropbox.save;

   SELECT obj_freshbooks
     INTO my_freshbooks
     FROM OBJS_freshbooks
    WHERE ROWNUM = 1;

   --my_freshbooks.upgrade_token;
   --my_freshbooks.system_current (p_credentials_in_response => p_credentials_in_response);
   -- my_freshbooks.project_list (p_projects_in_response => p_projects_in_response);
   my_freshbooks.time_entry_create (p_response => p_response, p_notes => 'Pimpiripettenusa');
--my_dropbox.get_account_info (p_credentials_in_response => p_credentials_in_response);
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