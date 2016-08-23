/* Formatted on 11/18/2011 1:59:27 PM (QP5 v5.163.1008.3004) */
DECLARE
   v_obj_dropbox   dropbox;
--p_filename VARCHAR2(255);
BEGIN
   SELECT (obj_dropbox)
     INTO v_obj_dropbox
     FROM objs_dropbox
    WHERE ACCOUNT = '35291135';

   v_obj_dropbox.post_html_file (p_filecontent => '<h2>portami via</h2>', p_filename => 'Ciao Belli Ciao.html');
END;