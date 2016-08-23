CREATE OR REPLACE PACKAGE SSO.PQ_CONSTANTS
AS
   /******************************************************************************
      NAME:       PQ_CONSTANTS
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        4/5/2011      Davide       1. Created this package.
   ******************************************************************************/

   CONST_NL_CHAR               CONSTANT VARCHAR2 (1) := CHR (10);
   con_str_http_POST           CONSTANT VARCHAR2 (5) := 'POST';
   CONST_GCHARTS_URL                    VARCHAR2 (40) := 'http://chart.apis.google.com/chart?cht=';
   CONST_GCHARTS_PROXY                  VARCHAR2 (250) := 'proxy02.sas.junta-andalucia.es:8080';
   CONST_GCHART_PROXY_EXCL              VARCHAR2 (40) := 'fraterno.*';
   CONST_CROSS_DOMAIN_ALLOW             VARCHAR2 (100) := 'Access-Control-Allow-Origin: http://fraterno:8080';
   con_str_wallet_path         CONSTANT VARCHAR2 (50) := 'file:C:\oracle\product\11.2.0';
   con_str_wallet_pass         CONSTANT VARCHAR2 (50) := 'Lepanto1571';
   con_str_hostname_port       CONSTANT VARCHAR2 (1024) := 'http://fraterno';
   con_str_http_proxy          CONSTANT VARCHAR2 (50) := '10.234.23.117:8080';
   con_num_timestamp_tz_diff   CONSTANT NUMBER := 7200;

   PROCEDURE set_proxy;

   PROCEDURE set_wallet;

   PROCEDURE init (p_response_error_check IN BOOLEAN := FALSE, p_detailed_excp_support IN BOOLEAN := FALSE);
END PQ_CONSTANTS;
/

