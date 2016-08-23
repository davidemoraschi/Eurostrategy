/* Formatted on 15/01/2012 21:54:55 (QP5 v5.139.911.3011) */
CREATE OR REPLACE PACKAGE EUROSTAT.obj_goog_oauth2_profiles
AS
   PROCEDURE jsp ( --access_token IN VARCHAR2 := NULL, token_type IN VARCHAR2 := NULL,
                  state IN VARCHAR2 := NULL);
END obj_goog_oauth2_profiles;
/