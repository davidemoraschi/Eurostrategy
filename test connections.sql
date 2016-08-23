/* Formatted on 8/30/2012 7:41:09 PM (QP5 v5.163.1008.3004) */
--TRUNCATE TABLE api_result;
--
--SELECT raw_xml FROM api_result;
--
--SELECT SUBSTR (lnkd_id, 6), lnkd_last_name
--  FROM lnkd_connections
-- WHERE account = 'LNKD_37m8s7TOEZ';
--
--
DECLARE
   my_profile       linkedin;
   my_connections   XMLTYPE;
BEGIN
   SELECT obj_linkedin
     INTO my_profile
     FROM objs_linkedin
    WHERE account = 'LNKD_37m8s7TOEZ'; --  'LNKD_74oTveK-gQ';--                                                  --'LNKD_oIOYur506b';--'LNKD_37m8s7TOEZ';

   my_profile.get_connections ( --      '(id,first-name,last-name,api-standard-profile-request:(url,headers),picture-url,date-of-birth,headline,summary,specialties,industry,location:(name),num-connections,num-connections-capped,primary-twitter-account,interests,positions:(id,title,start-date,end-date,company:(id,name,industry,ticker)),educations:(id,school-name,field-of-study,end-date,degree),member-url-resources:(name,url),languages:(language:(name),proficiency:(level)))',--,skills:(skill:(name),proficiency:(level))
                               '(id)', my_connections);


   FOR c1 IN (SELECT EXTRACTVALUE (VALUE (p), '/person/id') "id"
                FROM TABLE (XMLSEQUENCE (EXTRACT (my_connections, '/connections/person'))) p
               WHERE EXTRACTVALUE (VALUE (p), '/person/id') <> 'private')
   LOOP
      my_profile.get_connection_profile (
         c1."id",
         '(id,first-name,last-name,api-standard-profile-request:(url,headers),picture-url,date-of-birth,headline,summary,specialties,industry,location:(name),num-connections,num-connections-capped,primary-twitter-account,interests,positions:(id,title,start-date,end-date,company:(id,name,industry,ticker)),educations:(id,school-name,field-of-study,end-date,degree),member-url-resources:(name,url),languages:(language:(name),proficiency:(level)),skills:(skill:(name),proficiency:(level)))',
         my_connections);

      MERGE INTO lnkd_connections c
           USING (SELECT 'LNKD_37m8s7TOEZ' account,
                         'LNKD_' || EXTRACTVALUE (VALUE (p), '/person/id') "id",
                         EXTRACTVALUE (VALUE (p), '/person/first-name') "first-name",
                         EXTRACTVALUE (VALUE (p), '/person/last-name') "last-name",
                         EXTRACTVALUE (VALUE (p), '/person/headline') "headline",
                         EXTRACTVALUE (VALUE (p), '/person/num-connections') "num-connections",
                         --EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
                         EXTRACTVALUE (VALUE (p), '/person/location/name') "location",
                         EXTRACTVALUE (VALUE (p), '/person/industry') "industry"
                    FROM TABLE (XMLSEQUENCE (EXTRACT (my_connections, '/person'))) p
                   WHERE EXTRACTVALUE (VALUE (p), '/person/id') <> 'private') d
              ON (c.account = d.account AND c.lnkd_id = d."id")
      WHEN MATCHED
      THEN
         UPDATE SET c.lnkd_first_name = d."first-name",
                    c.lnkd_last_name = d."last-name",
                    LNKD_HEADLINE = d."headline",
                    LNKD_NUM_CONNECTIONS = d."num-connections",
                    LNKD_LOCATION = d."location",
                    LNKD_INDUSTRY = d."industry"
      WHEN NOT MATCHED
      THEN
         INSERT     (ACCOUNT,
                     LNKD_ID,
                     LNKD_FIRST_NAME,
                     LNKD_LAST_NAME,
                     LNKD_HEADLINE,
                     LNKD_NUM_CONNECTIONS,
                     LNKD_LOCATION,
                     LNKD_INDUSTRY)
             VALUES ('LNKD_37m8s7TOEZ',
                     d."id",
                     d."first-name",
                     d."last-name",
                     d."headline",
                     d."num-connections",
                     --EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
                     d."location",
                     d."industry");
   --      INSERT INTO api_result (raw_xml)
   --           VALUES (my_connections);
   END LOOP;


   COMMIT;
/*
   MERGE INTO lnkd_connections c
        USING (SELECT 'LNKD_37m8s7TOEZ' account,
                      'LNKD_' || EXTRACTVALUE (VALUE (p), '/person/id') "id",
                      EXTRACTVALUE (VALUE (p), '/person/first-name') "first-name",
                      EXTRACTVALUE (VALUE (p), '/person/last-name') "last-name",
                      EXTRACTVALUE (VALUE (p), '/person/headline') "headline",
                      EXTRACTVALUE (VALUE (p), '/person/num-connections') "num-connections",
                      --EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
                      EXTRACTVALUE (VALUE (p), '/person/location/name') "location",
                      EXTRACTVALUE (VALUE (p), '/person/industry') "industry"
                 FROM TABLE (XMLSEQUENCE (EXTRACT (my_connections, '/connections/person'))) p
                WHERE EXTRACTVALUE (VALUE (p), '/person/id') <> 'private') d
           ON (c.account = d.account AND c.lnkd_id = d."id")
   WHEN MATCHED
   THEN
      UPDATE SET c.lnkd_first_name = d."first-name",
                 c.lnkd_last_name = d."last-name",
                 LNKD_HEADLINE = d."headline",
                 LNKD_NUM_CONNECTIONS = d."num-connections",
                 LNKD_LOCATION = d."location",
                 LNKD_INDUSTRY = d."industry"
   WHEN NOT MATCHED
   THEN
      INSERT     (ACCOUNT,
                  LNKD_ID,
                  LNKD_FIRST_NAME,
                  LNKD_LAST_NAME,
                  LNKD_HEADLINE,
                  LNKD_NUM_CONNECTIONS,
                  LNKD_LOCATION,
                  LNKD_INDUSTRY)
          VALUES ('LNKD_37m8s7TOEZ',
                  d."id",
                  d."first-name",
                  d."last-name",
                  d."headline",
                  d."num-connections",
                  --EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
                  d."location",
                  d."industry");
                           /*
SELECT 'LNKD_37m8s7TOEZ',
       'LNKD_' || EXTRACTVALUE (VALUE (p), '/person/id') "id",
       EXTRACTVALUE (VALUE (p), '/person/first-name') "first-name",
       EXTRACTVALUE (VALUE (p), '/person/last-name') "last-name"
  -- EXTRACTVALUE (VALUE (p), '/person/headline') "headline",
  --EXTRACTVALUE (VALUE (p), '/person/site-standard-profile-request/url') "link",
  --EXTRACTVALUE (VALUE (p), '/person/location/name') "location",
  -- EXTRACTVALUE (VALUE (p), '/person/industry') "industry"
  FROM TABLE (XMLSEQUENCE (EXTRACT (my_connections, '/connections/person'))) p
 WHERE EXTRACTVALUE (VALUE (p), '/person/id') <> 'private';
 */
END;