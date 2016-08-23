CREATE OR REPLACE TYPE     DROPBOX
                     UNDER OAUTH
                  (oauth_callback VARCHAR2 (1000),
                   oauth_api_version NUMBER,
                   originalurl VARCHAR2 (4000),
                   CONSTRUCTOR FUNCTION DROPBOX (id                      IN VARCHAR2 DEFAULT 'test',
                                                 oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                                 oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                                 oauth_callback          IN VARCHAR2 DEFAULT 'oob')
                      RETURN SELF AS RESULT,
                   MEMBER PROCEDURE save,
                   MEMBER PROCEDURE remove,
                   MEMBER PROCEDURE upgrade_token,
                   MEMBER PROCEDURE get_account_info (p_callback IN VARCHAR2 DEFAULT NULL, p_credentials_in_response OUT XMLTYPE));
/


CREATE OR REPLACE TYPE BODY     dropbox wrapped
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
37fa b3b
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
ADOhVRXZh4AN0Aigal3kVZ2asnc9
/
