/* Formatted on 2010/08/11 13:48 (Formatter Plus v4.8.8) */
BEGIN
   dbms_network_acl_admin.drop_acl (acl              => 'oracle-base.xml');
   dbms_network_acl_admin.create_acl (acl              => 'oracle-base.xml'
                                     ,description      => 'oracle-base HTTP Access'
                                     ,principal        => 'OOXML'
                                     ,is_grant         => TRUE
                                     ,PRIVILEGE        => 'connect'
                                     ,start_date       => NULL
                                     ,end_date         => NULL);
   dbms_network_acl_admin.add_privilege (acl             => 'oracle-base.xml'
                                        ,principal       => 'OOXML'
                                        ,is_grant        => TRUE
                                        ,PRIVILEGE       => 'resolve'
                                        ,start_date      => NULL
                                        ,end_date        => NULL);
   dbms_network_acl_admin.assign_acl (acl => 'oracle-base.xml', HOST => '*.oracle-base.com');
   dbms_network_acl_admin.assign_acl (acl => 'oracle-base.xml', HOST => 'proxy02.sas.junta-andalucia.es');
   --10.234.23.117
   COMMIT;
END;