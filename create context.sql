/* Formatted on 8/20/2012 9:39:17 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE mstr_context
AS
   PROCEDURE set_value (par IN VARCHAR2, val IN VARCHAR2);
END;
/
CREATE OR REPLACE PACKAGE BODY mstr_context
AS
   PROCEDURE set_value (par IN VARCHAR2, val IN VARCHAR2)
   IS
   BEGIN
      DBMS_SESSION.set_context ('MicroStrategy', par, val);
   END;
END;
/
--DROP CONTEXT mstr_linkedin_user;-- USING mstr_context.set_linkedin_user;
CREATE OR REPLACE CONTEXT MicroStrategy USING mstr_context;

SELECT SYS_CONTEXT ('MicroStrategy', 'MSTR_ID') val FROM DUAL;

BEGIN
   mstr_context.set_value ('MSTR_ID', 'LNKD_37m8s7TOEZ');
END;

create or replace view MSTR_VW_LNKD_CONNECTIONS
AS
select * from LNKD_CONNECTIONS
where account = SYS_CONTEXT ('MicroStrategy', 'MSTR_ID');