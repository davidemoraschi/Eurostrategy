/* Formatted on 12/15/2011 12:59:39 PM (QP5 v5.163.1008.3004) */
SELECT PKG_HARVEST.account_who_am_i () res FROM DUAL;
SELECT PKG_HARVEST.projects () res FROM DUAL;
SELECT PKG_HARVEST.tasks () res FROM DUAL;
SELECT TO_CHAR(SYSDATE,'Dy, DD Mon YYYY','nls_date_language = american') from dual;
SELECT PKG_HARVEST.daily_add (1678965,1108149,'<![CDATA[ maddech&eacute; ]]>') res FROM DUAL;