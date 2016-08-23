/* Formatted on 28/08/2011 12:59:02 (QP5 v5.139.911.3011) */
CREATE OR REPLACE PACKAGE EUROSTAT.UTL_TSV
AS
   /******************************************************************************
      NAME:       UTL_TSV
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        6/30/2011      Davide       1. Created this package.
   ******************************************************************************/

   PROCEDURE read_tsv_file (p_filename IN VARCHAR2 := 'avia_paoac.tsv', p_folder IN VARCHAR2 := 'DATA_PUMP_DIR');
END UTL_TSV;
/