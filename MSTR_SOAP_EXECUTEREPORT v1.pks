CREATE OR REPLACE PACKAGE mstr_soap_executereport
AS
 crlf CONSTANT VARCHAR2 (2) := CHR (13) || CHR (10);
 soap_request XMLTYPE;
 con_http_ws_method CONSTANT VARCHAR2 (5) := 'POST';
 con_str_mstrwsj_server CONSTANT VARCHAR2 (200) := 'moraschi.eu';
 con_str_mstrwsj_user CONSTANT VARCHAR2 (200) := 'Administrator';
 con_str_mstrwsj_password CONSTANT VARCHAR2 (200) := 'vhjz342';
 con_str_mstrwsj_project CONSTANT VARCHAR2 (200) := 'EUROSTAT';
 -- con_str_ws_url CONSTANT VARCHAR2 (250)
 -- := 'http://ec2-50-19-187-227.compute-1.amazonaws.com:8080/MicroStrategyWS/services/MSTRWSJ' ;
 con_str_ws_url CONSTANT VARCHAR2 (250) := 'http://moraschi.eu/MicroStrategyWS/services/MSTRWSJ';
 con_str_ws_action CONSTANT VARCHAR2 (250) := '"http://microstrategy.com/webservices/v1_0/ExecuteReport"';
 --con_http_xsl_uri constant varchar2(1024):= 'http://fraterno:8080/MicroStrategyWS/MWS_VALME.xsl';
 con_http_xsl_uri CONSTANT VARCHAR2 (1024) := 'http://dl.dropbox.com/u/35291135/xsl/EUROSTRATEGY_MWS.xsl';

 PROCEDURE html (preportid IN VARCHAR2);

 PROCEDURE streamhtml (p_data_set XMLTYPE := NULL);
END EUROSTAT.mstr_soap_executereport;
/

