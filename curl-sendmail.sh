#!/bin/bash

if [ ! 1 -eq $# ]
then
    echo "Usage: $0 <file name>"
    exit 1
fi


# -----------------
#  Configure first
# -----------------

FILE_NAME="$1"
SENDER_NAME="nobody"
RECIPIENT_NAME="nobody"
FROM="nobody@gmail.com"
TO="nobody@gmail.com"
SUBJECT="Тема"
MESSAGE="Письмо с вложением"

GMAIL_LOGIN="$FROM"
GMAIL_PASSWD= # !!!WARNING!!! Clear password

ATTACHMENT_CONTENT_TYPE="image/jpeg"

DEBUG_ENVELOPE=1
# -----------------

debug() {
    if [ "$DEBUG_ENVELOPE" ]
    then
        cat - | tee >(cat - >&2)
    else
        cat
    fi
}


(cat "$FILE_NAME" | \
cat <<- EOF
MIME-Version: 1.0
From: =?UTF-8?B?$(echo -n $SENDER_NAME | base64)?= <$FROM>
To: =?UTF-8?B?$(echo -n $RECIPIENT_NAME | base64)?= <$TO>
Subject: =?UTF-8?B?$(echo -n $SUBJECT | base64)?=
Content-Type: multipart/mixed; boundary=abcdef

--abcdef
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit

$MESSAGE

--abcdef
Content-Type: $ATTACHMENT_CONTENT_TYPE
Content-Disposition: attachment; filename="=?UTF-8?B?$(basename $FILE_NAME | base64)?="
Content-Transfer-Encoding: base64

$(base64)
--abcdef--
EOF
) \
    | sed s/$/$'\r'/ \
    | debug \
    | curl -s --ssl-reqd -u "$GMAIL_LOGIN:$GMAIL_PASSWD" smtps://smtp.gmail.com:465 --mail-from "$FROM" --mail-rcpt "$TO" -T - >/dev/null 2>&1

ERROR=$?

if [ $ERROR -ne 0 ]
then
    echo -ne "\nError"
    [ $ERROR -eq 67 ] && echo ": Auth failed, check GMAIL_LOGIN and GMAIL_PASSWD vars"
    echo
else
    echo -e "\nSuccess"
fi

exit $ERROR

