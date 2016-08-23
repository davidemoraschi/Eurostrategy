CREATE OR REPLACE TYPE EUROSTAT.TWITTER
   UNDER OAUTH
   (oauth_callback VARCHAR2 (1000),
    oauth_api_version NUMBER,
    CONSTRUCTOR FUNCTION TWITTER (id                      IN VARCHAR2 DEFAULT 'test',
                                  oauth_consumer_key      IN VARCHAR2 DEFAULT NULL,
                                  oauth_consumer_secret   IN VARCHAR2 DEFAULT NULL,
                                  oauth_callback          IN VARCHAR2 DEFAULT 'oob')
       RETURN SELF AS RESULT,
    MEMBER PROCEDURE save,
    MEMBER PROCEDURE upgrade_token,
    MEMBER PROCEDURE get_account (p_callback IN VARCHAR2 DEFAULT NULL, p_credentials_in_response OUT XMLTYPE),
    MEMBER PROCEDURE post_status (p_status IN VARCHAR2 DEFAULT 'chip', p_result_in_response OUT XMLTYPE),
    MEMBER PROCEDURE post_status_with_media (p_status IN VARCHAR2 DEFAULT 'chip', p_result_in_response OUT XMLTYPE));
/