CREATE OR REPLACE procedure EUROSTAT.test_pptx
as
   l_template   BLOB;
   l_new_file   BLOB;
BEGIN
   l_template := file_util_pkg.get_blob_from_file ('DATA_PUMP_DIR', 'Presentation_template.pptx');
   l_new_file :=
      ooxml_util_pkg.
      get_file_from_template (l_template,
                              t_str_array ('#COMPANY_NAME#', '#PRODUCT_NAME#', '#VERSION#'),
                              t_str_array ());

   file_util_pkg.save_blob_to_file ('DATA_PUMP_DIR', 'Presentation_modified.pptx', l_new_file);
END;
/
