#!/bin/sh

# shell-utils.sh -- A collection of useful shellscript functions
# Copyright (C) 2005-13  Sakis Kasampalis <s.kasampalis@zoho.com>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# prints an error message to STDERR
# Arguments: $@ -> message to print
function perr ()
{
    printf "ERROR: ${@}\n" >&2
}

# print a warning nessage to STDERR
# Arguments: $@ -> message to print
function pwarn ()
{
    printf "WARNING: ${@}\n" >&2
}

# print a usage message and then exits
# Arguments: $@ -> message to print
function puse ()
{
    printf "USAGE: ${@}\n" >&2
}

# ask a yes/no question
# Arguments: $1 -> The prompt
#            $2 -> The default answer (optional)
# Variables: YESNO -> set to the user response y for yes, n for no
function prompt-yn ()
{
    if [ $# -lt 1 ] ; then
	    perr "Insufficient Arguments."
	    return 1
    fi

    DEF_ARG=""
    YESNO=""

    case "${2}" in
	    [yY]|[yY][eE][sS])
	        DEF_ARG=y ;;
	    [nN]|[nN][oO])
	        DEF_ARG=n ;;
    esac

    while :
    do
	    printf "${1} (y/n)? "

	    if [ -n "${DEF_ARG}" ] ; then
	        printf "[${DEF_ARG}] "
	    fi

	    read YESNO

	    if [ -z "${YESNO}" ] ; then
	        YESNO="${DEF_ARG}"
	    fi

	    case "${YESNO}" in
	        [yY]|[yY][eE][sS])
		        YESNO=y ; break ;;
	        [nN]|[nN][oO])
		        YESNO=n ; break ;;
	        *)
		        YESNO="" ;;
	    esac
    done

    export YESNO
    unset DEF_ARG
    return 0
}

# ask a question
# Arguments: $1 -> The prompt
#            $2 -> The default answer (optional)
# Variables: RESPONSE -> set to the user response
function prompt-resp ()
{
    if [ $# -lt 1 ] ; then
	    perr "Insufficient Arguments."
	    return 1
    fi

    RESPONSE=""
    DEF_ARG="${2}"

    while :
    do
	    printf "${1} ? "
	    if [ -n "${DEF_ARG}" -a "${DEF_ARG}" != "-" ] ; then
	        printf "[${DEF_ARG}] "
 	    fi

	    read RESPONSE

	    if [ -n "${RESPONSE}" ] ; then
	        break
	    elif [ -z "${RESPONSE}" -a -n "${DEF_ARG}" ] ; then
	        RESPONSE="${DEF_ARG}"
	        if [ "${RESPONSE}" = "-" ] ; then RESPONSE="" ; fi
	        break
	    fi
    done

    export RESPONSE
    unset DEF_ARG
    return 0
}

# print the available space for a directory in KB
# Arguments: $1 -> The directory to check
function free-space ()
{
    if [ $# -lt 1 ] ; then
	    puse "get_free_space [directory]"
	    return 1
    fi

    df -k "${1}" | awk 'NR != 1 { print $4 ; }'
}

# check if there is sufficient space
# Arguments: $1 -> The directory to check
#            $2 -> The amount of space to check for
#            $3 -> The units for $2 (optional)
#                  k for kilobytes
#                  m for megabytes
#                  g for gigabytes
function is-space-avail ()
{
    if [ $# -lt 2 ] ; then
	    print_error "Insufficient Arguments."
	    return 1
    fi

    if [ ! -d "${1}" ] ; then
	    print_error "${1} is not a directory."
	    return 1
    fi

    SPACE_MIN="${2}"

    case "${3}" in
        [mM]|[mM][bB])
            SPACE_MIN=`echo "$SPACE_MIN * 1024" | bc` ;;
	    [gG]|[gG][bB])
            SPACE_MIN=`echo "$SPACE_MIN * 1024 * 1024" | bc` ;;
    esac

    if [ `free-space "$1"` -gt "${SPACE_MIN}" ] ; then
	    return 0
    fi

    unset SPACE_MIN
    return 1
}

# print a list of process id(s) matching $1
# Arguments: $1 -> the process name to search for
function get-pid ()
{
    if [ $# -lt 1 ] ; then
	    perr "Insufficient Arguments."
        return 1
    fi

    PSOPTS="-ef"

    ps "${PSOPTS}" | grep "${1}" | grep -v grep | awk '{ print $2; }'

    unset PSOPTS
}

# print the numeric user id
# Arguments: $1 -> the user name
function get-uid ()
{
    if [ $# -lt 1 ] ; then
	    perr "Insufficient Arguments."
        return 1
    fi

    ID=`id ${1} 2>/dev/null`

    if [ $? -eq 1 ] ; then
	    perr "No such user: ${1}"
	    return 1
    fi

    echo ${ID} | sed -e 's/(.*$//' -e 's/^uid=//'

    unset ID
    return 0
}

# print an input string to lower case
# Arguments: $@ -> the string
function to-lower ()
{
    printf "${@}\n" | tr '[A-Z]' '[a-z]'
}

# print an input string to upper case
# Arguments: $@ -> the string
function to-upper ()
{
    printf "${@}\n" | tr '[a-z]' '[A-Z]'
}

# convert the input files to lower case
# Arguments: $@ -> files to convert
function file-to-lower ()
{
    for file in "${@}"
    do
	    if [ ! -f "${file}" ]; then
	        perr "File ${file} does not exist";
	    else
	        mv -f "${file}" "`printf "${file}\n" | tr '[A-Z]' '[a-z]'`"
	    fi
    done

    return 0
}

# convert the input files to upper case
# Arguments: $@ -> files to convert
function file-to-upper ()
{
    for file in "${@}"
    do
	    if [ ! -f "${file}" ]; then
	        perr "File ${file} does not exist";
	    else
	        mv -f "${file}" "`printf "${file}\n" | tr '[a-z]' '[A-Z]'`"
	    fi
    done

    return 0
}

# rename all the files with a new suffix
# Arguments: $1 -> the old suffix (for example html)
#            $2 -> the new suffix (for example xhtml)
function ren-all-suf ()
{
    if [ $# -lt 2 ] ; then
	    perr "Insufficient arguments."
	    return 1
    fi

    OLDSUFFIX="${1}"
    NEWSUFFIX="${2}"

    # fake command to check if the suffix really exists
    ls *."${OLDSUFFIX}" 2>/dev/null
    if [ $? -ne 0 ] ; then
	    print_warning "There are no files with the suffix \`${OLDSUFFIX}'."
	    return 1
    fi

    for file in *."${OLDSUFFIX}"
    do
	    NEWNAME=`printf "${file}\n" | sed "s/${OLDSUFFIX}/${NEWSUFFIX}/"`
	    mv -i "${file}" "${NEWNAME}"
    done

    unset OLDSUFFIX NEWSUFFIX NEWNAME
    return 0
}

# rename all the files with a new prefix
# Arguments: $1 -> the old prefix
#            $2 -> the new prefix
function ren-all-pref ()
{
    if [ $# -lt 2 ] ; then
	    perr "Insufficient arguments."
	    return 1
    fi

    OLDPREFIX="${1}"
    NEWPREFIX="${2}"

    # fake command to check if the prefix really exists
    ls "${OLDPREFIX}"* 2>/dev/null
    if [ $? -ne 0 ] ; then
	    pwarn "There are no files with the prefix \`${OLDPREFIX}'."
	    return 1
    fi

    for file in "${OLDPREFIX}"*
    do
	    NEWNAME=`printf "${file}\n" | sed "s/${OLDPREFIX}/${NEWPREFIX}/"`
	    mv -i "${file}" "${NEWNAME}"
    done

    unset OLDPREFIX NEWPREFIX NEWNAME
    return 0
}

# convert a list of dos formatted files to the POSIX format
# Arguments: $@ -> the list of files to convert
function dos2posix ()
{
    for file in "${@}"
    do
        tr -d '\015' < "${file}" > "${file}".posix
        prompt_yes_no "Overwrite ${file}"
        if [ "${YESNO}" = "y" ] ; then
	        mv -f "${file}".posix "${file}"
        fi
    done

    return 0
}

# print the system's name
function os-name ()
{
    case `uname -s` in
        *BSD)
            echo BSD ;;
        Darwin)
            echo Darwin ;;
        SunOS)
            case `uname -r` in
                5.*) echo Solaris ;;
                *) echo SunOS ;;
            esac
            ;;
        Linux)
            echo GNU/Linux ;;
        MINIX*)
            echo MINIX ;;
        HP-UX)
            echo HPUX ;;
        AIX)
            echo AIX ;;
        *) echo unknown ;;
    esac
}

# print out the number of characters which exist in a file
# Arguments: $@ -> the files to count the chars of
function chars ()
{
    case `os-name` in
        bsd|sunos|linux)
            WCOPT="-c" ;;
        *)
            WCOPT="-m" ;;
    esac

    wc "${WCOPT}" "${@}"

    unset WCOPT
}

# insert quotes in the beggining and the end of each file's line
# Arguments: $1 -> the file of which the contents will be quoted
function ins-quotes ()
{
    if [ $# -ne 1 ] ; then
        perr "Insufficient Arguments."
        return 1
    fi

    if [ ! -f "${1}" ] ; then
	    perr "Argument must be a file."
	    return 1
    fi

    while read ln
    do
        ln=\"$ln\"
        printf "${ln}\n"
    done < "${1}"
}

# remove all the files of a specific type that exist in the current directory
# Arguments: $1 -> the string to search in the output of `file'
# NOTE: use with caution...
function rm-all ()
{
    if [ $# -ne 1 ] ; then
        perr "Incorrect Arguments."
        return 1
    fi

    file * | grep "${1}" | awk '{ print $1 }' | sed 's/://' | xargs rm
}

# verbose remove
# Arguments: $@ -> what to remove
function rm ()
{
    /bin/rm -i "${@}"
}

# listing with colours by default
# Arguments: $@ -> what to list
function ls ()
{
    /bin/ls --color=auto "${@}"
}

# long listing
# Arguments: $@ -> what to list
function ll ()
{
    /bin/ls -l --color=auto "${@}"
}

# list all files
# Arguments: $@ -> what to list
function la ()
{
    /bin/ls -A --color=auto "${@}"
}

# list by column and type
# Arguments: $@ -> what to list
function l ()
{
    /bin/ls -CF --color=auto "${@}"
}

# grep with colours by default
# Arguments: $@ -> what to match
function grep ()
{
    /bin/grep --color=auto "${@}"
}

# fgrep with colours by default
# Arguments: $@ -> what to match
function fgrep ()
{
    /bin/fgrep --color=auto "${@}"
}

# egrep with colours by default
# Arguments: $@ -> what to match
function egrep ()
{
    /bin/egrep --color=auto "${@}"
}

# verbose move/rename
# Arguments: $@ -> what to match
function mv ()
{
    /bin/mv -i "${@}"
}

# verbose copy
# Arguments: $@ -> what to match
function cp ()
{
    /bin/cp -i "${@}"
}

# make a file executable
# Arguments: $@ -> what to match
function cx ()
{
    /bin/chmod +x "${@}"
}

# count lines
# Arguments: $@ -> what to match
function cl ()
{
    /usr/bin/wc -l "${@}"
}

# sort files
# Arguments: $@ -> what to match
function fsort ()
{
    ls -lSh ${@} 2>/dev/null | grep -v total | awk '{print $5 "\t" $9}'
}

# sort mixed (directories & files)
# Arguments: $@ -> what to match
function dsort ()
{
    du -s ${@} 2>/dev/null | sort -rn | awk '{print $2}' | xargs du -sh 2>/dev/null
}

# simple way to keep a backup of a file
# Arguments: $1 -> the file
function bkup ()
{
    if [ $# -ne 1 ] ; then
        perr "Insufficient Arguments."
        return 1
    fi

    FILE_COPY=${1}.`date +%Y%m%d.%H%M.ORIG`
    mv -f ${1} ${FILE_COPY}
    printf "Backing up ${1} to ${FILE_COPY}\n"
    cp -p "${FILE_COPY}" "${1}"

    unset FILE_COPY
}

# show a message near the mouse
# useful for things like ``./build ; msg "libc build"''
# Arguments: $1 -> the message
function msg ()
{
    if [ $? -eq 0 ] ; then
        OUT="success"
    else
        OUT="failure"
    fi

    type xmessage >/dev/null

    if [ $? -ne 0 ] ; then
	    perr "xmessage is required, please install it."
	    return 1
    fi

    if [ $# -ne 1 ] ; then
        perr "Insufficient Arguments."
        return 1
    fi

    MSG="${1}: ${OUT}"

    xmessage -buttons ok -default ok -nearmouse "${MSG}" 2>/dev/null

    unset OUT ERR MSG
}

# print a specific line of a file
# Arguments: $1 -> the line number
#            $2 -> the file
function pln ()
{
    if [ $# -ne 2 ] ; then
        perr "Insufficient Arguments."
        return 1
    fi

    sed -n "${1}p" ${2}
}

# create a directory and enter it
# Arguments: $1 -> the directory name
function mkcd ()
{
    if [ $# -ne 1 ] ; then
        perr "Insufficient Arguments."
        return 1
    fi

    mkdir "${1}" && cd "${1}"
}
