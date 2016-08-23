/* Formatted on 8/14/2012 1:23:56 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE SSO.twitter_status_update
AS
   PROCEDURE jsp (twitter_account IN objs_twitter.account%TYPE, twitter_status IN VARCHAR2);
END;
/