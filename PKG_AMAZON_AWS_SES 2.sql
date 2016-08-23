/* Formatted on 08/11/2011 14:07:04 (QP5 v5.139.911.3011) */
CREATE OR REPLACE PACKAGE EUROSTAT.PKG_AMAZON_AWS_SES
IS
   FUNCTION SendEmail (p_Sender      IN VARCHAR2,
                       p_Recipient   IN VARCHAR2,
                       p_Subject     IN VARCHAR2,
                       p_Html_Body   IN VARCHAR2)
      RETURN BOOLEAN;
END;
/