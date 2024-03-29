/* Formatted on 15/01/2012 22:27:47 (QP5 v5.139.911.3011) */
ALTER TABLE OBJS_GOOGLE_ANALYTICS
 DROP PRIMARY KEY CASCADE;

DROP TABLE OBJS_GOOGLE_ANALYTICS CASCADE CONSTRAINTS;

CREATE TABLE OBJS_GOOGLE_ANALYTICS
(
   ACCOUNT              VARCHAR2 (50 BYTE),
   CREATION_DATE        TIMESTAMP (6) WITH TIME ZONE,
   AUTHORIZATION_CODE   VARCHAR2 (500 BYTE),
   ACCESS_TOKEN         VARCHAR2 (500 BYTE),
   TOKEN_TYPE           VARCHAR2 (50 BYTE),
   EXPIRES_IN           NUMBER,
   PROFILE_ID           VARCHAR2 (500 BYTE),
   XML_RESPONSE         XMLTYPE
);



ALTER TABLE OBJS_GOOGLE_ANALYTICS ADD (
  CONSTRAINT OBJECTS_GOOGLE_ANALYTICS_PK
 PRIMARY KEY
 (ACCOUNT));