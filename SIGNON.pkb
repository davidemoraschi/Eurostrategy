CREATE OR REPLACE PACKAGE BODY SSO.signon
IS
   PROCEDURE jsp (originalurl IN VARCHAR2, errorcode IN VARCHAR2 DEFAULT NULL, errormessage IN VARCHAR2 DEFAULT NULL)
   IS
      v_originalurl    VARCHAR2 (32000) := originalurl;
      v_ErrorMessage   VARCHAR2 (4000) := ErrorMessage;
   BEGIN
      OWA_UTIL.mime_header ('text/html', TRUE, 'utf-8');
      HTP.p ('<!DOCTYPE html>
                <!--[if lte IE 8]> <html class="lteie8" lang="en"> <![endif]-->
                <!--[if gt IE 8]><!-->
                <html lang="en">
                <!--<![endif]-->
                <head>
                    <script type="text/javascript">        var NREUMQ = NREUMQ || []; NREUMQ.push(["mark", "firstbyte", new Date().getTime()]);</script>
                    <meta name="viewport" content="initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no, width=device-width" />
                    <meta name="apple-mobile-web-app-capable" content="yes" />
                    <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
                    <meta name="ROBOTS" content="NOINDEX, NOFOLLOW" />
                    <title>Sign In – EuroStrategy.net</title>
                    <script src="https://assetcache.harvestapp.com/assets/base.js?1346185996" type="text/javascript"></script>
                    <script src="https://assetcache.harvestapp.com/javascripts/signin.js?1346183207"
                        type="text/javascript"></script>
                    <script type="text/javascript"> 
                //<![CDATA[
                        window._dateFormat = [["dd", "mm", "yyyy"], "/"]; window._source_name = ''account/login'';
                //]]>
                    </script>
                    <link href="https://assetcache.harvestapp.com/stylesheets/screen.css?1346186099"
                        media="screen" rel="stylesheet" type="text/css" />
                </head>
                ');
      HTP.p('<body id="signin">
                <!--[if lte IE 7]>
            <div id="old_ie">
              <div class="wrapper">
                <strong>Attention: You are using an unsupported browser.</strong><br />
                <a href="/browser_upgrade">Please upgrade your web browser</a> now to continue your EuroStrategy experience.
                <a href="/browser_upgrade" class="learn-more" rel="nofollow">Learn More</a>  </div>
            </div>
            <![endif]-->
                <noscript>
                    <div id="old_ie" class="nooojs">
                        <div class="wrapper">
                            <strong>Attention: EuroStrategy uses Javascript</strong><br />
                            <a href="http://enable-javascript.com/">Please enable javascript</a> to use EuroStrategy
                            without issue.
                        </div>
                    </div>
                </noscript>
                <div id="signin-container">
                    <h2 id="company-logo">
                        <a href="/sso/auth_lnkd.jsp?originalurl=' || util.urlencode (v_originalurl)
                     || '"><img width="150" height="150" src="http://oregonbest.org/sites/default/files/linkedin-button.png" /></a></h2>
                    <div id="signin-form-container">
                        <form accept-charset="UTF-8" action="/sso/auth_lnkd.jsp?originalurl=' || util.urlencode (v_originalurl)
                     || '"" class="form-top-aligned js-signin-form it-validates it-validates-inside sign-in-hidden"
                        id="signin_form" method="post" novalidate="novalidate">
                        <div style="margin: 0; padding: 0; display: inline"></div>
                        <div class="form-field text-field">
                            <div class="validation-div">
                                <input id="email" type="hidden" name="user[email]" size="30"
                                    tabindex="1" type="email" /></div>
                        </div>
                        <div class="form-field text-field">
                            <div class="validation-div">
                                <input id="user_password" type="hidden" name="user[password]" size="30" type="password" tabindex="2" /></div>
                        </div>
                        <div class="form-field check-field remember-me">
                            <label for="remember_me">
                                You will prompted for a LinkedIn account to sign in.</label>
                        </div>
                        <div class="btn-submit-container">
                            <input class="btn-submit btn-primary" id="sign-in-button" name="commit" tabindex="4"
                                type="submit" value="Sign In" />
                        </div>
                        </form>
                        <form accept-charset="UTF-8" action="/account/reset_password" class="form-top-aligned js-signin-form it-validates it-validates-inside sign-in-hidden"
                        id="forgot_password_form" method="post" novalidate="novalidate">
                        <div style="margin: 0; padding: 0; display: inline">
                            <input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token"
                                type="hidden" value="VdJNNcWNSFi893xusTX+4N8nGO22MHrVMeT7rqx8/pc=" /></div>
                        <div class="form-field text-field">
                            <label for="pass_email" style="padding-bottom: 8px">
                                Please type your email address, we''ll contact you</label>
                            <div class="validation-div">
                                <input class="required email js-activate" id="pass_email" name="user[email]" size="30"
                                    tabindex="8" type="text" /></div>
                        </div>
                        <div class="btn-submit-container">
                            <input class="login btn-submit btn-primary" id="submit-button" name="commit" tabindex="9"
                                type="submit" value="Submit" />
                        </div>
                        <p style="padding-top: 18px">
                            <a href="#" class="js-signin-flink" rel="signin">Back to Sign In</a></p>
                        </form>
                        <input id="opend_id_preferred" name="opend_id_preferred" type="hidden" value="false" />
                        <input id="is_forgot_password" name="is_forgot_password" type="hidden" />
                    </div>
                </div>
                <div id="signin-footer">
                    <a href="#" class="js-signin-flink" id="forgot_password_flink" rel="forgot_password">
                        Don''t have a LinkedIn account?</a> <a href="#" class="js-signin-flink" id="signin_flink" rel="signin">
                            Sign in with LinkedIn account</a> <a style="background-image:url("https://cdn.groupcamp.com/get?id=71440")" href="#" id="poweredby-link-2" title="EuroStrategy">Powered by EuroStrategy</a>
                </div>
                <script type="text/javascript">
                    var _gaq = _gaq || [];
                    _gaq.push([''_setAccount'', ''UA-103886-9'']);

                    _gaq.push([''_setCustomVar'', 1, ''Account Type'', ''free'', 1]);
                    _gaq.push([''_setCustomVar'', 2, ''User Type'', ''Guest'', 1]);

                    _gaq.push([''_trackPageview'']);

                    (function () {
                        var ga = document.createElement(''script''); ga.type = ''text/javascript''; ga.async = true;
                        ga.src = (''https:'' == document.location.protocol ? ''https://ssl'' : ''http://www'') + ''.google-analytics.com/ga.js'';
                        var s = document.getElementsByTagName(''script'')[0]; s.parentNode.insertBefore(ga, s);
                    })();
                </script>
                <script type="text/javascript">        if (!NREUMQ.f) {
                        NREUMQ.f = function () {
                            NREUMQ.push(["load", new Date().getTime()]);
                            var e = document.createElement("script");
                            e.type = "text/javascript"; e.async = true; e.src = "https://d1ros97qkrwjf5.cloudfront.net/42/eum/rum.js";
                            document.body.appendChild(e);
                            if (NREUMQ.a) NREUMQ.a();
                        };
                        NREUMQ.a = window.onload; window.onload = NREUMQ.f;
                    };
                    NREUMQ.push(["nrfj", "beacon-1.newrelic.com", "7accebd50e", 216162, "JwxaQhMKVFhTERxWWgcMQVgVSlRbUQpd", 0, 23, new Date().getTime(), "", "", "", "", ""])</script>
            </body>
            </html>
            ');
      --HTP.htmlOpen;
      --HTP.headOpen;
      --HTP.title ('Social Sign on');
      --HTP.p ('<link href="signon.css" rel="stylesheet" type="text/css">');
      --HTP.headClose;
      --HTP.bodyOpen;
      --HTP.p (
--         '<div id="signin-container">
--            <h2 id="company-logo"><a href="/sso/auth_lnkd.jsp?originalurl=' || util.urlencode (v_originalurl)
--         || '"><img width="150" height="150" src="http://oregonbest.org/sites/default/files/linkedin-button.png" /></a></h2>
--            <div id="signin-form-container">
--                <p />
--                <label for="pass_email" style="padding-bottom:8px">Click on the "in" logo to sign in with your LinkedIn account</label>
--            </div>
--          </div>
--');
   --HTP.bodyClose;
   --HTP.htmlClose;
   EXCEPTION
      WHEN OTHERS
      THEN
         SSO.error_handler.aspx (SQLCODE, SQLERRM, DBMS_UTILITY.format_error_backtrace);
   END;


   PROCEDURE jsp_old (originalurl IN VARCHAR2, errorcode IN VARCHAR2 DEFAULT NULL, errormessage IN VARCHAR2 DEFAULT NULL)
   IS
      v_originalurl    VARCHAR2 (32000) := originalurl;
      v_ErrorMessage   VARCHAR2 (4000) := ErrorMessage;
   BEGIN
      OWA_UTIL.mime_header ('text/html', TRUE, 'utf-8');
      HTP.htmlOpen;
      HTP.headOpen;
      HTP.title ('Social Sign on');
      HTP.p ('<link href="/i/css/sso_msft.css" rel="stylesheet" type="text/css">');
      HTP.headClose;
      HTP.bodyOpen;
      HTP.p (
         '
                <div id="header">
                    <h1>EuroStrategy Social Sign on</h1>
                </div>
                <div id="server_version">
                    <p>' || v_ErrorMessage || '</p><p>' || v_originalurl
         || '</p>
                </div>
                <img src="/i/apex/builder/menu-administration-128.png" border="0" alt="" />
                <div id="content">
                    <div class="content-container">
                        <fieldset>
                            <legend>Please select one of the social networks available to log in.</legend>
                            <h2></h2>
                            <div id="details-left">
                                <table border="0" cellpadding="0" cellspacing="0">
                                    <tr class="alt">
                                        <th></th>
                                        <td><img src="/i/32px/dropbox.png" /><a href="/sso/auth_drbx.jsp?originalurl='
         || util.urlencode (v_originalurl)
         || '">Dropbox</a></td>
                                    </tr>
                                    <tr>
                                        <th></th>
                                        <td><img src="/i/32px/linkedin.png" /><a href="/sso/auth_lnkd.jsp?originalurl='
         || util.urlencode (v_originalurl)
         || '">LinkedIn</a></td>
                                    </tr>
                                    <tr class="alt">
                                        <th></th>
                                        <td><img src="/i/32px/twitter.png" /><a href="/sso/auth_twit.jsp?originalurl='
         || util.urlencode (v_originalurl)
         || '">Twitter</a></td>
                                    </tr>
                                    </tr>
                                    <tr>
                                        <th></th>
                                        <td><img src="/i/32px/google.png" /><a href="/sso/auth_goog_oauth2.jsp?originalurl='
         || util.urlencode (v_originalurl)
         || '">Google</a></td>
                                    </tr>
                                    <tr class="alt">
                                        <th></th>
                                        <td><img src="/i/32px/microsoft.png" /><a href="/sso/auth_live_oauth2.jsp?originalurl='
         || util.urlencode (v_originalurl)
         || '">Windows Live</a></td>
                                    </tr>
                                    <tr>
                                        <th>...coming soon</th>
                                        <td><img src="/i/32px/yahoo.png" /><span style=”font-family:arial;font-size:small;”>Yahoo</span></td>
                                </table>
                            </div>
                        </fieldset>
                    </div>
                </div>
      ');
      HTP.bodyClose;
      HTP.htmlClose;
   EXCEPTION
      WHEN OTHERS
      THEN
         SSO.error_handler.aspx (SQLCODE, SQLERRM, DBMS_UTILITY.format_error_backtrace);
   END;

   PROCEDURE xml (token IN VARCHAR2)
   IS
      v_obj_linkedin   linkedin;
      v_obj_dropbox    dropbox;
      v_obj_twitter    twitter;
      v_obj_google     google;
      v_obj_live       live;
      v_token          VARCHAR2 (2000) := token;
      l_html           VARCHAR2 (32767);
   BEGIN
      CASE SUBSTR (v_token, 1, 4)
         WHEN 'LNKD'
         THEN
            SELECT (obj_linkedin)
              INTO v_obj_linkedin
              FROM objs_linkedin
             WHERE account = v_token;

            SELECT    '<return_code><pass userid="'
                   || v_obj_linkedin.ID
                   || '" username="'
                   || v_obj_linkedin.descr
                   || '" /></return_code>'
              INTO l_html
              FROM DUAL;
         WHEN 'DRBX'
         THEN
            SELECT (obj_dropbox)
              INTO v_obj_dropbox
              FROM objs_dropbox
             WHERE account = v_token;

            SELECT    '<return_code><pass userid="'
                   || v_obj_dropbox.ID
                   || '" username="'
                   || v_obj_dropbox.descr
                   || '" /></return_code>'
              INTO l_html
              FROM DUAL;
         WHEN 'TWIT'
         THEN
            SELECT (obj_twitter)
              INTO v_obj_twitter
              FROM objs_twitter
             WHERE account = v_token;

            SELECT    '<return_code><pass userid="'
                   || v_obj_twitter.ID
                   || '" username="'
                   || v_obj_twitter.descr
                   || '" /></return_code>'
              INTO l_html
              FROM DUAL;
         WHEN 'GOOG'
         THEN
            SELECT (obj_google)
              INTO v_obj_google
              FROM objs_google
             WHERE account = v_token;

            SELECT    '<return_code><pass userid="'
                   || v_obj_google.ID
                   || '" username="'
                   || v_obj_google.descr
                   || '" /></return_code>'
              INTO l_html
              FROM DUAL;
         WHEN 'LIVE'
         THEN
            SELECT (obj_live)
              INTO v_obj_live
              FROM objs_live
             WHERE account = v_token;

            SELECT '<return_code><pass userid="' || v_obj_live.ID || '" username="' || v_obj_live.descr || '" /></return_code>'
              INTO l_html
              FROM DUAL;
      END CASE;

      OWA_UTIL.mime_header ('text/xml', TRUE, 'utf-8');
      HTP.p (l_html);
   END;

   PROCEDURE css
   IS
   BEGIN
      NULL;
      HTP.p (
         '
   body{background:#f6f6f6;text-align:center;font-family:"Helvetica Neue",Arial,Verdana,"Nimbus Sans L",sans-serif;font-size:12px;height:100%;line-height:1.6em}
   #signin-container{background:#fff;border:1px solid #d4d4d4;display:inline-block;line-height:1.63em;margin:100px auto 30px;min-width:451px;min-height:180px;height:auto;padding:30px;position:relative;-moz-border-radius:8px;-webkit-border-radius:8px;-o-border-radius:8px;-ms-border-radius:8px;-khtml-border-radius:8px;border-radius:8px;-moz-box-shadow:0px 1px 8px rgba(0,0,0,0.15);-webkit-box-shadow:0px 1px 8px rgba(0,0,0,0.15);-o-box-shadow:0px 1px 8px rgba(0,0,0,0.15);box-shadow:0px 1px 8px rgba(0,0,0,0.15)}
   #signin-container h2#company-logo{display:block;float:left;height:180px;line-height:176px;margin:0;padding:0;min-width:160px}
   #signin-container #signin-form-container{border-left:1px solid #ddd;float:right;margin-left:30px;min-height:180px;padding-left:30px;text-align:left;width:230px}
    ');
   END;
END;
/

