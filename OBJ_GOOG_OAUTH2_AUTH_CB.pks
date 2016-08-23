/* Formatted on 1/5/2012 2:48:29 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE EUROSTAT.obj_goog_oauth2_auth_cb
AS
   PROCEDURE jsp (state IN VARCHAR2 := NULL, code IN VARCHAR2 := NULL, error IN VARCHAR2 := NULL);
END obj_goog_oauth2_auth_cb;
/