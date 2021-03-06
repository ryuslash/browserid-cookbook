#!/usr/bin/python

import cgi
import json
import os
import urllib
import urllib2

def print_login_form():
    print """<html>
<head>
<script src="https://browserid.org/include.js"></script>
<script>
function login() {
    navigator.id.get(function (assertion) {
        if (assertion) {
            var assertion_field = document.getElementById("assertion-field");
            assertion_field.value = assertion;
            var login_form = document.getElementById("login-form");
            login_form.submit();
        }
    });
}
</script>
</head>

<body>
<form id="login-form" method="POST">
<input id="assertion-field" type="hidden" name="assertion" value="">
</form>

<p><a href="javascript:login()">Login</a></p>
</body>
</html>"""

def verify_assertion(assertion):
    audience = 'http://'
    if 'HTTPS' in os.environ:
        audience = 'https://'
    audience += os.environ['SERVER_NAME'] + ':' + os.environ['SERVER_PORT']
    postdata = urllib.urlencode({"assertion": assertion, "audience": audience})

    page = urllib2.urlopen('https://browserid.org/verify', postdata)
    return json.load(page)

print 'Content-type: text/html\n\n'

form = cgi.FieldStorage()
if 'assertion' in form:
    print "<html><body>"
    result = verify_assertion(form['assertion'].value)
    if result['status'] == 'okay':
        print "<p>Logged in as: " + result['email'] + "</p>"
    else:
        print "<p>Error: " + result['reason'] + "</p>"

    print '<p><a href="python.cgi">Back to login page</p>'
    print "</body></html>"
else:
    print_login_form()
