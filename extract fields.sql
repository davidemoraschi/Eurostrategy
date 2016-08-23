/* Formatted on 8/29/2012 1:49:47 PM (QP5 v5.163.1008.3004) */
TRUNCATE TABLE api_result;

SELECT raw_xml FROM api_result;

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