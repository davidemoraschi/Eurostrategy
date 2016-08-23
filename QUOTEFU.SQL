/* Formatted on 2010/08/12 19:08 (Formatter Plus v4.8.8) */
--select (UTL_HTTP.request('http://feeds.feedburner.com/brainyquote/QUOTEFU')) from dual;

DECLARE
   con_str_http_proxy   CONSTANT VARCHAR2 (50) := 'proxy02.sas.junta-andalucia.es:8080';
   var_http_request              UTL_HTTP.req;
   var_http_response             UTL_HTTP.resp;
   var_http_value                VARCHAR2 (32767);
   var_http_xml_result           VARCHAR2 (32767);
   var_http_xml                  XMLTYPE;
BEGIN
   UTL_HTTP.set_proxy ('10.234.23.117:8080');
   var_http_request := UTL_HTTP.begin_request (url => 'http://feeds.feedburner.com/brainyquote/QUOTEFU', method => 'GET');
   UTL_HTTP.set_header (var_http_request, 'User-Agent', 'Mozilla/4.0');
   var_http_response := UTL_HTTP.get_response (r => var_http_request);

   BEGIN
      LOOP
         UTL_HTTP.read_line (r => var_http_response, DATA => var_http_value, remove_crlf => TRUE);
         var_http_xml_result := var_http_xml_result || var_http_value;
      END LOOP;
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (r => var_http_response);
   END;

   var_http_xml := XMLTYPE (var_http_xml_result);
   DBMS_OUTPUT.put_line (var_http_xml.getstringval ());

   UPDATE log_google
      SET entry = var_http_xml;

   COMMIT;
END;
/

DECLARE
   tweet_string                  VARCHAR2 (140);
BEGIN
   SELECT REPLACE (EXTRACTVALUE (a.entry, '/rss/channel/item[1]/description'), '"')
   || ' - ' ||REPLACE (EXTRACTVALUE (a.entry, '/rss/channel/item[1]/title'), '"')
   INTO   tweet_string
   FROM   log_google a;

   DBMS_OUTPUT.put_line (tweet_string);
   pkg_oauth.twiting_by_the_pl (tweet_string);
END;
/