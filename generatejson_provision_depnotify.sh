#!/bin/bash

COREDIR=$(/usr/bin/dirname $0)
JSON="${COREDIR}/demo_depnotify.json"
GENERATEJSON="${COREDIR}/generatejson.py"
PKGSDIR="${COREDIR}/pkgs"
ROOTSCRIPTSDIR="${COREDIR}/scripts"
BASEURL="https://raw.githubusercontent.com/xtian08/NYU/main"
PKGSURL="${BASEURL}/pkgs"
ROOTSCRIPTSURL="${BASEURL}/scripts"

/bin/chmod a+x ${GENERATEJSON}

${GENERATEJSON} \
--base-url ${BASEURL} \
--output ~/Desktop \
--item \
item-name='Preflight' \
item-path="${ROOTSCRIPTSDIR}/preflight.py" \
item-stage='preflight' \
item-type='rootscript' \
item-url="${ROOTSCRIPTSURL}/preflight.py" \
script-do-not-wait=False \
--item \
item-name='DEPNotify' \
item-path="${PKGSDIR}/01-airwatch-23.01.0.pkg" \
item-stage='setupassistant' \
item-type='package' \
item-url="${PKGSURL}/01-airwatch-23.01.0.pkg" \
script-do-not-wait=False \
--item \
item-name='DEPNotify' \
item-path="${PKGSDIR}/02-DEPNotify-1.1.6.pkg" \
item-stage='setupassistant' \
item-type='package' \
item-url="${PKGSURL}/02-DEPNotify-1.1.6.pkg" \
script-do-not-wait=False \
--item \
item-name='DEPNotify Customization' \
item-path="${ROOTSCRIPTSDIR}/depnotify_customization.py" \
item-stage='setupassistant' \
item-type='rootscript' \
item-url="${ROOTSCRIPTSURL}/depnotify_customization.py" \
script-do-not-wait=False \
--item \
item-name='DEPNotify User Launcher' \
item-path="${ROOTSCRIPTSDIR}/depnotify_user_launcher.py" \
item-stage='userland' \
item-type='userscript' \
item-url="${ROOTSCRIPTSURL}/depnotify_user_launcher.py" \
script-do-not-wait=False \
--item \
item-name='Caffeinate Machine' \
item-path="${ROOTSCRIPTSDIR}/caffeinate.py" \
item-stage='userland' \
item-type='rootscript' \
item-url="${ROOTSCRIPTSURL}/caffeinate.py" \
script-do-not-wait=True \
--item \
item-name='Bless VM' \
item-path="${ROOTSCRIPTSDIR}/bless_vm.py" \
item-stage='userland' \
item-type='rootscript' \
item-url="${ROOTSCRIPTSURL}/bless_vm.py" \
script-do-not-wait=False \
--item \
item-name='DEPNotify End' \
item-path="${ROOTSCRIPTSDIR}/depnotify_end.py" \
item-stage='userland' \
item-type='rootscript' \
item-url="${ROOTSCRIPTSURL}/depnotify_end.py" \
script-do-not-wait=False

/bin/mv ~/Desktop/bootstrap.json ${JSON}
