/* Formatted on 08/11/2011 14:10:15 (QP5 v5.139.911.3011) */
DECLARE
   x   BOOLEAN;
BEGIN
   x :=
      PKG_AMAZON_AWS_SES.SendEmail ('eurostat.microstrategy@gmail.com',
                                    'dmoraschi@gmail.com',
                                    'Hello HTMLworld',
                                    '<h1>Hello World!</h1>');
END;