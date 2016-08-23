/* Formatted on 12/15/2011 12:57:02 PM (QP5 v5.163.1008.3004) */
DECLARE
   --   con_str_wallet_path       CONSTANT VARCHAR2 (500) := pq_constants.con_str_wallet_path;
   --   con_str_wallet_pass       CONSTANT VARCHAR2 (100) := pq_constants.con_str_wallet_pass;
   con_str_api_request_url   CONSTANT VARCHAR2 (1000) := 'https://dmoraschi.harvestapp.com/';
   con_str_api_username      CONSTANT VARCHAR2 (1000) := 'dmoraschi@gmail.com';
   con_str_api_password      CONSTANT VARCHAR2 (1000) := 'araknion';
   http_method               CONSTANT VARCHAR2 (5) := 'GET';
   http_req                           UTL_HTTP.req;
   var_http_api_request               VARCHAR2 (1023) := 'account/who_am_i';
   http_resp                          UTL_HTTP.resp;
   var_http_resp_value                VARCHAR2 (32767);
   l_gzcompressed_blob                BLOB;
   l_uncompressed_blob                BLOB;
   l_raw                              RAW (32767);
BEGIN
   UTL_HTTP.set_proxy (pq_constants.con_str_http_proxy);
   UTL_HTTP.set_wallet (PATH => pq_constants.con_str_wallet_path, password => pq_constants.con_str_wallet_pass);
   UTL_HTTP.set_response_error_check (FALSE);
   UTL_HTTP.set_detailed_excp_support (FALSE);
   http_req := UTL_HTTP.begin_request (con_str_api_request_url || var_http_api_request, http_method, UTL_HTTP.http_version_1_1);
   UTL_HTTP.set_header (r => http_req, name => 'Accept', VALUE => 'application/xml');
   UTL_HTTP.set_header (r => http_req, name => 'Accept-Encoding', VALUE => 'gzip,deflate');
   UTL_HTTP.SET_AUTHENTICATION (http_req, con_str_api_username, con_str_api_password);
   http_resp := UTL_HTTP.get_response (http_req);
   DBMS_LOB.createtemporary (l_gzcompressed_blob, FALSE);
   DBMS_LOB.createtemporary (l_uncompressed_blob, FALSE);

   BEGIN
      LOOP
         UTL_HTTP.read_raw (http_resp, l_raw, 32766);
         DBMS_LOB.writeappend (l_gzcompressed_blob, UTL_RAW.LENGTH (l_raw), l_raw);
      END LOOP;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         NULL;
   END;

   UTL_COMPRESS.lz_uncompress (src => l_gzcompressed_blob, dst => l_uncompressed_blob);
   DBMS_OUTPUT.put_line ('Uncompressed Data: ' || UTL_RAW.CAST_TO_VARCHAR2 (l_uncompressed_blob));
   DBMS_LOB.freetemporary (l_gzcompressed_blob);
   DBMS_LOB.freetemporary (l_uncompressed_blob);
   UTL_HTTP.end_response (http_resp);
END;