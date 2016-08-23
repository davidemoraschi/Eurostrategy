/* Formatted on 12/5/2011 2:21:56 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE FUNCTION EUROSTAT.GET_ECONOMIST_RSS (
   p_rss_url IN VARCHAR2 := 'http://www.economist.com/topics/euro-zone/index.xml')
   RETURN CLOB
AS
   l_http_req   UTL_HTTP.req;
   l_content    CLOB;
BEGIN
   pq_constants.http_init;
   l_http_req := pq_constants.http_begin_request (p_url => p_rss_url, p_gzip => TRUE);
   UTL_HTTP.set_header (r => l_http_req, name => 'Accept', VALUE => 'application/xml');
   pq_constants.http_return_response (p_http_req => l_http_req, p_content => l_content, p_gzip => TRUE);
   RETURN l_content;
END;
/