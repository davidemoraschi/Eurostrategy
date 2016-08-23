CREATE OR REPLACE PACKAGE EUROSTAT.mstr_lnkd_groups
AS
   PROCEDURE jsp (lnkd_id IN VARCHAR2 := NULL);
END mstr_lnkd_groups;
/
