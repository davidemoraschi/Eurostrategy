CREATE OR REPLACE PACKAGE EUROSTAT.mstr_lnkd_FFSQL
AS
   PROCEDURE connections (lnkd_id IN VARCHAR2, cursor_connections IN OUT SYS_REFCURSOR);

   FUNCTION connections_table (lnkd_id IN VARCHAR2)
      RETURN mstr_lnkd_connections_type;

   PROCEDURE groups (lnkd_id IN VARCHAR2, cursor_groups IN OUT SYS_REFCURSOR);
END mstr_lnkd_FFSQL;
/
