/* Formatted on 12/1/2011 1:56:03 PM (QP5 v5.163.1008.3004) */
CREATE SYNONYM mstr_frbk_ffsql FOR EUROSTAT.mstr_frbk_ffsql@mstr921;


DECLARE
   p_response   XMLTYPE;
BEGIN
   mstr_frbk_ffsql.time_entry_create (0.45, '2 bullo');
END;