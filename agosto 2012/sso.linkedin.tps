CREATE OR REPLACE TYPE     LINKEDIN
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


CREATE OR REPLACE TYPE BODY     LINKEDIN wrapped
a000000
1
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
e
301d 9a9
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
/
