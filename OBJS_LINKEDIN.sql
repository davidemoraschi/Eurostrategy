/* Formatted on 8/20/2012 11:40:41 AM (QP5 v5.163.1008.3004) */
DROP TABLE OBJS_LINKEDIN
/

CREATE TABLE OBJS_LINKEDIN
(
   ACCOUNT         VARCHAR2 (50),
   CREATION_DATE   TIMESTAMP (6) WITH TIME ZONE,
   OBJ_LINKEDIN    LINKEDIN,
   --ORIGINALURL VARCHAR2(4000),
   CONSTRAINT OBJECTS_LINKEDIN_PK PRIMARY KEY (ACCOUNT)
--USING INDEX OBJECTS_LINKEDIN_PK
)
--COLUMN OBJ_LINKEDIN NOT SUBSTITUTABLE AT ALL LEVELS
NOLOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
NOMONITORING;