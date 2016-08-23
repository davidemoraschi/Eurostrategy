/* Formatted on 08/11/2011 14:27:03 (QP5 v5.139.911.3011) */
DECLARE
   x    BOOLEAN;
   c1   SYS_REFCURSOR;
BEGIN
   OPEN c1 FOR SELECT SYSDATE FROM DUAL;

   x :=
      PKG_AMAZON_AWS_SES.SendEmail ('eurostat.microstrategy@gmail.com',
                                    'dmoraschi@gmail.com',
                                    'Una esperimento',
                                    '<table class="apex-standard-report" cellpadding="0" cellspacing="0"><tr><th>SYSDATE</th></tr><tr><td>08/11/11</td></tr></table>');

   CLOSE c1;
END;