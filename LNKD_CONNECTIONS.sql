/* Formatted on 8/29/2012 2:13:06 PM (QP5 v5.163.1008.3004) */
ALTER TABLE SSO.LNKD_CONNECTIONS
 DROP PRIMARY KEY CASCADE;

DROP TABLE SSO.LNKD_CONNECTIONS CASCADE CONSTRAINTS;

CREATE TABLE SSO.LNKD_CONNECTIONS
(
   ACCOUNT                         VARCHAR2 (50 BYTE),
   LNKD_ID                         VARCHAR2 (50 BYTE),
   LNKD_FIRST_NAME                 VARCHAR2 (50 BYTE),
   LNKD_LAST_NAME                  VARCHAR2 (50 BYTE),
   LNKD_HEADLINE                   VARCHAR2 (250 BYTE),
   LNKD_NUM_CONNECTIONS            NUMBER,
   LNKD_LOCATION                   VARCHAR2 (250 BYTE),
   LNKD_INDUSTRY                   VARCHAR2 (50 BYTE),
   LNKD_PICTURE_URL                VARCHAR2 (1500 BYTE),
   LNKD_API_STD_PROFILE_REQUEST    VARCHAR2 (1500 BYTE),
   LNKD_1ST_POSITION               VARCHAR2 (250 BYTE),
   LNKD_1ST_COMPANY                VARCHAR2 (250 BYTE),
   LNKD_1ST_SCHOOL_NAME            VARCHAR2 (250 BYTE),
   LNKD_1ST_FIELD_OF_STUDY         VARCHAR2 (250 BYTE),
   LNKD_1ST_DEGREE                 VARCHAR2 (250 BYTE),
   LNKD_1ST_DEGREE_YEAR            NUMBER,
   LNKD_1ST_LANGUAGE               VARCHAR2 (50 BYTE),
   LNKD_1ST_LANGUAGE_PROFICIENCY   VARCHAR2 (50 BYTE)
);

/*
SELECT EXTRACTVALUE (VALUE (p), '/person/positions/position[1]/title') "position",
       EXTRACTVALUE (VALUE (p), '/person/positions/position[1]/company/name') "company",
       EXTRACTVALUE (VALUE (p), '/person/educations/education[1]/school-name') "school-name",
       EXTRACTVALUE (VALUE (p), '/person/educations/education[1]/field-of-study') "field-of-study",
       EXTRACTVALUE (VALUE (p), '/person/educations/education[1]/degree') "degree",
       EXTRACTVALUE (VALUE (p), '/person/educations/education[1]/end-date/year') "year",
       EXTRACTVALUE (VALUE (p), '/person/languages/language[1]/language/name') "language",
       EXTRACTVALUE (VALUE (p), '/person/languages/language[1]/proficiency/level') "proficiency"
  FROM api_result, TABLE (XMLSEQUENCE (EXTRACT (raw_xml, '/connections/person'))) p
 WHERE EXTRACTVALUE (VALUE (p), '/person/id') <> 'private'
 */
ALTER TABLE SSO.LNKD_CONNECTIONS ADD (
  CONSTRAINT LNKD_CONNECTIONS_PK
  PRIMARY KEY
  (ACCOUNT, LNKD_ID)
  USING INDEX);