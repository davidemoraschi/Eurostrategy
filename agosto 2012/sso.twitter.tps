CREATE OR REPLACE TYPE     TWITTER
                     UNDER OAUTH
                  (oauth_callback VARCHAR2 (1000),
                   oauth_api_version NUMBER,
                   CONSTRUCTOR FUNCTION TWITTER (id                      IN VARCHAR2 DEFAULT 'test',
                                                 oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                                 oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                                 oauth_callback          IN VARCHAR2 DEFAULT 'oob')
                      RETURN SELF AS RESULT,
                   MEMBER PROCEDURE save,
                   MEMBER PROCEDURE remove,
                   MEMBER PROCEDURE upgrade_token,
                   MEMBER PROCEDURE get_account (p_callback IN VARCHAR2 DEFAULT NULL, p_credentials_in_response OUT XMLTYPE),
                   MEMBER PROCEDURE post_status (p_status IN VARCHAR2 DEFAULT 'chip', p_result_in_response OUT XMLTYPE),
                   MEMBER PROCEDURE post_status_with_media (p_status IN VARCHAR2 DEFAULT 'chip', p_result_in_response OUT XMLTYPE));
/


CREATE OR REPLACE TYPE BODY     TWITTER wrapped
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
5992 f86
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
BFfBs
GMUujOcICrrmDrJx3Jne9GxyPB5dox6geuOKd8bfvQl4IzkSePmLcKPkje1RQm4J05w
wcX2kLfPbU8l3p6/K8CDDhv5Q7U2Q8SU
/
