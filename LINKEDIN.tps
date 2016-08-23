CREATE OR REPLACE
TYPE     SSO.LINKEDIN
                     UNDER OAUTH
                  (oauth_callback VARCHAR2 (1000),
                   originalurl VARCHAR2 (4000),
                   CONSTRUCTOR FUNCTION LINKEDIN (id                      IN VARCHAR2 DEFAULT 'test',
                                                  oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                                  oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                                  oauth_callback          IN VARCHAR2 DEFAULT 'oob')
                      RETURN SELF AS RESULT,
                   MEMBER PROCEDURE save,
                   MEMBER PROCEDURE remove,
                   MEMBER PROCEDURE upgrade_token,
                   MEMBER PROCEDURE get_profile (p_fields IN VARCHAR2 DEFAULT '(id,first-name,last-name,headline)'));
/