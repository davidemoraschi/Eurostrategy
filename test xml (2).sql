/* Formatted on 22/09/2011 12:57:27 (QP5 v5.139.911.3011) */
SELECT EXTRACT (result, '/group-memberships/group-membership') FROM log_http;

SELECT * FROM TABLE(XMLSEQUENCE(EXTRACT(result,'/group-memberships/group-membership')));