/* Formatted on 12/1/2011 1:16:47 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE TYPE EUROSTAT.freshbooks
                     UNDER oauth
                  (oauth_callback VARCHAR2 (1000),
                   oauth_api_version NUMBER,
                   CONSTRUCTOR FUNCTION freshbooks (id                      IN VARCHAR2 DEFAULT 'test',
                                                    oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                                    oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                                    oauth_callback          IN VARCHAR2 DEFAULT 'oob')
                      RETURN SELF AS RESULT,
                   MEMBER PROCEDURE save,
                   MEMBER PROCEDURE upgrade_token,
                   MEMBER PROCEDURE system_current (p_callback IN VARCHAR2 DEFAULT NULL, p_credentials_in_response OUT XMLTYPE) /*<!--?xml version="1.0" encoding="utf-8"?--><request method="system.current"></request>*/
                                                                                                                               ,
                   MEMBER PROCEDURE project_list (p_callback IN VARCHAR2 DEFAULT NULL, p_projects_in_response OUT XMLTYPE),
                   MEMBER PROCEDURE time_entry_create (p_callback   IN     VARCHAR2 DEFAULT NULL,
                                                       p_response      OUT XMLTYPE,
                                                       p_date       IN     VARCHAR2 := TO_CHAR (SYSDATE, 'yyyy-mm-dd'),
                                                       p_hours      IN     VARCHAR2 := 1,
                                                       p_notes      IN     VARCHAR2 := 'Report Execution'),
                   OVERRIDING MEMBER FUNCTION authorization_header (p_callback_url   IN VARCHAR2 DEFAULT NULL,
                                                                    p_consumer_key   IN VARCHAR2,
                                                                    p_timestamp      IN VARCHAR2,
                                                                    p_nonce          IN VARCHAR2,
                                                                    p_signature      IN VARCHAR2,
                                                                    p_token          IN VARCHAR2 DEFAULT NULL,
                                                                    p_verifier       IN VARCHAR2 DEFAULT NULL)
                      RETURN VARCHAR2);
/