/* Formatted on 8/14/2012 2:26:55 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY SSO.twitter_status_update
AS
   PROCEDURE jsp (twitter_account IN objs_twitter.account%TYPE, twitter_status IN VARCHAR2)
   IS
      v_obj_twitter          twitter;
      p_result_in_response   XMLTYPE;
   BEGIN
      NULL;

      SELECT (obj_twitter)
        INTO v_obj_twitter
        FROM objs_twitter
       WHERE account = twitter_account;

      v_obj_twitter.post_status (twitter_status, p_result_in_response);
      OWA_UTIL.mime_header ('text/xml', TRUE, 'utf-8');
      HTP.p (p_result_in_response.getstringval ());
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         SSO.error_handler.aspx (SQLCODE, 'Invalid account', 'You are not authorized to use this service');
      WHEN OTHERS
      THEN
         SSO.error_handler.aspx (SQLCODE, SQLERRM, DBMS_UTILITY.format_error_backtrace);
   END jsp;
END;
/