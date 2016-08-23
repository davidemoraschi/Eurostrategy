/* Formatted on 12/5/2011 12:43:22 PM (QP5 v5.163.1008.3004) */
DECLARE
   con_str_api_request_url   CONSTANT VARCHAR2 (4000) := 'https://dmoraschi.harvestapp.com/';
   con_str_api_username      CONSTANT VARCHAR2 (1000) := 'dmoraschi@gmail.com';
   con_str_api_password      CONSTANT VARCHAR2 (1000) := 'araknion';
   l_http_req                         UTL_HTTP.req;
   l_http_api_request                 VARCHAR2 (1023) := 'account/who_am_i';
   l_http_resp_value                  VARCHAR2 (32767);
   l_content                          CLOB;
BEGIN
   pq_constants.http_init;
   l_http_req := pq_constants.http_begin_request (p_url => con_str_api_request_url || l_http_api_request);

   UTL_HTTP.SET_AUTHENTICATION (l_http_req, con_str_api_username, con_str_api_password);

   pq_constants.http_return_response (p_http_req => l_http_req, p_content => l_content);
   DBMS_OUTPUT.put_line (l_content);
END;