/* Formatted on 12/5/2011 3:20:18 PM (QP5 v5.163.1008.3004) */
SELECT GET_ECONOMIST_RSS_AS_XML (
          'https://www.googleapis.com/customsearch/v1?alt=atom&cx=006037921336921081277:gopgq_px0-k&key=AIzaSyAN80EPArspHpyxtisnqFRSe0fCkOW8w_k&q=Davide+Moraschi')
          rss
  FROM DUAL;


SELECT EXTRACTVALUE (
          VALUE (p),
          '/entry/title',
          'xmlns="http://www.w3.org/2005/Atom" xmlns:cse="http://schemas.google.com/cseapi/2010" xmlns:gd="http://schemas.google.com/g/2005" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/')
          title
  FROM TABLE (
          XMLSEQUENCE (
             EXTRACT (
                GET_ECONOMIST_RSS_AS_XML (
                   'https://www.googleapis.com/customsearch/v1?alt=atom&cx=010722013183089041389:ab5yj_rbe5q&key=AIzaSyAN80EPArspHpyxtisnqFRSe0fCkOW8w_k&q=Davide+Moraschi'),
                '/feed/entry',
                'xmlns="http://www.w3.org/2005/Atom" xmlns:cse="http://schemas.google.com/cseapi/2010" xmlns:gd="http://schemas.google.com/g/2005" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/'))) p;