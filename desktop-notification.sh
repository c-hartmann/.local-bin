#! /bin/bash

# desktop-notification.sh, aliased to dn

# NOTIFY-SEND(1)                                                                      User Commands                                                                     NOTIFY-SEND(1)
#
# NAME
#        notify-send - a program to send desktop notifications
#
# SYNOPSIS
#
#        notify-send [OPTIONS] {summary} [body]
#
# DESCRIPTION
#        With notify-send you can send desktop notifications to the user via a notification daemon from the command line. These notifications can be used to inform the user about an
#        event or display some form of information without getting in the user’s way.
#
# OPTIONS
#        -?, --help
#            Show help and exit.
#
#        -a, --app-name=APP_NAME
#            Specifies the app name for the notification.
#
#        -A, --action=[NAME=]Text...
#            Specifies the actions to display to the user. Implies --wait to wait for user input. May be set multiple times. The NAME of the action is output to stdout. If NAME is
#            not specified, the numerical index of the option is used (starting with 1).
#
#        -u, --urgency=LEVEL
#            Specifies the urgency level (low, normal, critical).
#
#        -t, --expire-time=TIME
#            The duration, in milliseconds, for the notification to appear on screen.
#
#            Not all implementations use this parameter. GNOME Shell and Notify OSD always ignore it, while Plasma ignores it for notifications with the critical urgency level.
#
#        -i, --icon=ICON
#            Specifies an icon filename or stock icon to display.
#
#        -c, --category=TYPE[,TYPE...]
#            Specifies the notification category.
#
#        -h, --hint=TYPE:NAME:VALUE
#            Specifies basic extra data to pass. Valid types are BOOLEAN, INT, DOUBLE, STRING, BYTE and VARIANT.
#
#        -p, --print-id
#            Print the notification ID.
#
#        -r, --replace-id=REPLACE_ID
#            The ID of the notification to replace.
#
#        -w, --wait
#            Wait for the notification to be closed before exiting. If the expire-time is set, it will be used as the maximum waiting time.
#
#        -e, --transient
#            Show a transient notification. Transient notifications by-pass the server's persistence capability, if any. And so it won't be preserved until the user acknowledges it.
#
# SEE ALSO
#        The Desktop Notification Spec on https://specifications.freedesktop.org/notification-spec/.

summary=${1:-$(hostname --long)}
notify-send --app-name='Desktop Notification' --wait --expire-time=6000 "${summary}" &
exit 0
