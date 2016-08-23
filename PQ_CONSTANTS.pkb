CREATE OR REPLACE PACKAGE BODY SSO.PQ_CONSTANTS
AS
   /******************************************************************************
      NAME:       PKG_CONSTANTS
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        28.jul.2011      Davide       1. Created this package body.
   ******************************************************************************/
   PROCEDURE set_proxy
   AS
   BEGIN
      UTL_HTTP.set_proxy (PQ_CONSTANTS.con_str_http_proxy);
   END set_proxy;

   PROCEDURE set_wallet
   AS
   BEGIN
      UTL_HTTP.set_wallet ( PATH => PQ_CONSTANTS.con_str_wallet_path, PASSWORD => PQ_CONSTANTS.con_str_wallet_pass);
   END set_wallet;

   PROCEDURE init ( p_response_error_check IN BOOLEAN := FALSE, p_detailed_excp_support IN BOOLEAN := FALSE)
   AS
   BEGIN
      set_proxy;
      set_wallet;
      UTL_HTTP.set_response_error_check (p_response_error_check);
      UTL_HTTP.set_detailed_excp_support (p_detailed_excp_support);
   END init;
END PQ_CONSTANTS;
/

