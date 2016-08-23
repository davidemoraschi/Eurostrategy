/* Formatted on 12/14/2011 2:08:08 PM (QP5 v5.163.1008.3004) */
BEGIN
   DBMS_NETWORK_ACL_ADMIN.create_acl (acl           => 'acl_hr_economist.xml',
                                      description   => 'Access to www.economist.com',
                                      principal     => 'HR',
                                      is_grant      => TRUE,
                                      privilege     => 'connect');
END;
/

BEGIN
   DBMS_NETWORK_ACL_ADMIN.assign_acl (acl => 'acl_hr_economist.xml', HOST => '*.economist.com');
END;

COMMIT;