#!/bin/sh

# shell-utils.sh -- A collection of useful shellscript functions
# Copyright (C) 2005-16  Sakis Kasampalis <s.kasampalis@zoho.com>

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
perr ()
{
    printf "ERROR: ${@}\n" >&2
}

# print a warning nessage to STDERR
# Arguments: $@ -> message to print
pwarn ()
{
    printf "WARNING: ${@}\n" >&2
}

# print a usage message and then exits
# Arguments: $@ -> message to print
puse ()
{
    printf "USAGE: ${@}\n" >&2
}

# ask a yes/no question
# Arguments: $1 -> The prompt
#            $2 -> The default answer (optional)
# Variables: yesno -> set to the user response (y for yes, n for no)
prompt_yn ()
{
    if [ $# -lt 1 ]
    then
	puse "prompt_yn prompt [default answer]"
	return 1
    fi

    def_arg=""
    yesno=""

    case "${2}" in
	[yY]|[yY][eE][sS])
	    def_arg=y ;;
	[nN]|[nN][oO])
	    def_arg=n ;;
    esac

    while :
    do
	printf "${1} (y/n)? "
	test -n "${def_arg}" && printf "[${def_arg}] "

	read yesno
	test -z "${yesno}" && yesno="${def_arg}"

	case "${yesno}" in
	    [yY]|[yY][eE][sS])
		yesno=y ; break ;;
	    [nN]|[nN][oO])
		yesno=n ; break ;;
	    *)
		yesno="" ;;
	esac
    done

    export yesno
    unset def_arg
}

# ask a question
# Arguments: $1 -> The prompt
#            $2 -> The default answer (optional)
# Variables: response -> set to the user response
prompt_resp ()
{
    if [ $# -lt 1 ]
    then
	puse "promp_resp prompt [default answer]"
	return 1
    fi

    response=""
    def_arg="${2}"

    while :
    do
	printf "${1} ? "
	test -n "${def_arg}" -a "${def_arg}" != "-" && printf "[${def_arg}] "

	read response
	test -n "${response}" && break

	if [ -z "${response}" -a -n "${def_arg}" ]
	then
	    response="${def_arg}"
	    break
	fi
    done

    test "${response}" = "-" && response=""

    export response
    unset def_arg
 }

# print a list of process id(s) matching $1
# Arguments: $1 -> the process name to search for
get_pid ()
{
    if [ $# -lt 1 ]
    then
	perr "Insufficient Arguments."
        return 1
    fi

    ps -ef | grep "${1}" | grep -v grep | awk '{ print $2; }'

    unset psopts
}

# print the numeric user id
# Arguments: $1 -> the user name
get_uid ()
{
    if [ $# -lt 1 ]
    then
	perr "Insufficient Arguments."
        return 1
    fi

    user_id=$(id ${1} 2>/dev/null)

    if [ $? -ne 0 ]
    then
	perr "No such user: ${1}"
	return 1
    fi

    printf "${user_id}\n" | sed -e 's/(.*$//' -e 's/^uid=//'

    unset user_id
}

# print an input string to lower case
# Arguments: $@ -> the string
to_lower ()
{
    printf "${@}\n" | tr '[A-Z]' '[a-z]'
}

# print an input string to upper case
# Arguments: $@ -> the string
to_upper ()
{
    printf "${@}\n" | tr '[a-z]' '[A-Z]'
}

# convert the input files to lower case
# Arguments: $@ -> files to convert
file_to_lower ()
{
    for file in "${@}"
    do
	mv -f "${file}" "$(printf "${file}\n" | tr '[A-Z]' '[a-z]')" \
	    2>/dev/null || perr "File ${file} does not exist"
    done
}

# convert the input files to upper case
# Arguments: $@ -> files to convert
file_to_upper ()
{
    for file in "${@}"
    do
	mv -f "${file}" "$(printf "${file}\n" | tr '[a-z]' '[A-Z]')" \
	    2>/dev/null || perr "File ${file} does not exist"
    done
}

# rename all the files with a new suffix
# Arguments: $1 -> the old suffix (for example html)
#            $2 -> the new suffix (for example xhtml)
ren_all_suf ()
{
    if [ $# -lt 2 ]
    then
	puse "ren_all_suf oldsuffix newsuffix"
	return 1
    fi

    oldsuffix="${1}"
    newsuffix="${2}"

    # fake command to check if the suffix really exists
    if ! ls *."${oldsuffix}" 2>/dev/null
    then
	pwarn "There are no files with the suffix \`${oldsuffix}'."
	return 1
    fi

    for file in *."${oldsuffix}"
    do
	newname=$(printf "${file}\n" | sed "s/${oldsuffix}/${newsuffix}/")
	mv -i "${file}" "${newname}"
    done

    unset oldsuffix newsuffix newname
}

# rename all the files with a new prefix
# Arguments: $1 -> the old prefix
#            $2 -> the new prefix
ren_all_pref ()
{
    if [ $# -lt 2 ]
    then
	puse "ren_all_pref oldprefix newprefix"
	return 1
    fi

    oldprefix="${1}"
    newprefix="${2}"

    # fake command to check if the prefix really exists
    ls "${oldprefix}"* 2>/dev/null
    if ! ls *."${oldprefix}" 2>/dev/null
    then
	pwarn "There are no files with the prefix \`${oldprefix}'."
	return 1
    fi

    for file in "${oldprefix}"*
    do
	newname=$(printf "${file}\n" | sed "s/${oldprefix}/${newprefix}/")
	mv -i "${file}" "${newname}"
    done

    unset oldprefix newprefix newname
}

# convert a list of dos formatted files to the POSIX format
# Arguments: $@ -> the list of files to convert
dos2posix ()
{
    for file in "${@}"
    do
        tr -d '\015' < "${file}" > "${file}".posix
        prompt_yn "Overwrite ${file}"
        test "${yesno}" = "y" && mv -f "${file}".posix "${file}"
    done
}

# print the system's name
os_name ()
{
    case $(uname -s) in
        *BSD)
            printf BSD ;;
        Darwin)
            printf macOS ;;
        SunOS)
            case $(uname -r) in
                5.*) printf Solaris ;;
                *) printf SunOS ;;
            esac
            ;;
        Linux)
            printf GNU/Linux ;;
        MINIX*)
            printf MINIX ;;
        HP-UX)
            echo HPUX ;;
        AIX)
            echo AIX ;;
        *) echo unknown ;;
    esac
    printf "\n"
}

# print out the number of characters which exist in a file
# Arguments: $@ -> the files to count the chars of
chars ()
{
    case $(os_name) in
        bsd|sunos|linux)
            wcopt="-c" ;;
        *)
            wcopt="-m" ;;
    esac

    wc "${wcopt}" "${@}"

    unset wcopt
}

# insert quotes in the beggining and the end of each file's line
# Arguments: $1 -> the file of which the contents will be quoted
ins_quotes ()
{
    if [ $# -ne 1 ]
    then
        puse "ins_quotes file"
        return 1
    fi

    if [ ! -f "${1}" ]
    then
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
rm_all ()
{
    if [ $# -ne 1 ]
    then
        puse "rm_all wildcard"
        return 1
    fi

    file * | grep "${1}" | awk '{ print $1 }' | sed 's/://' | xargs rm
}

# verbose remove
# Arguments: $@ -> what to remove
rm ()
{
    /bin/rm -i "${@}"
}

# listing with colours by default
# Arguments: $@ -> what to list
ls ()
{
    case $(os_name) in
        bsd|macOS)
            lsopt="-G" ;;
        *)
            lsopt="-c" ;;
    esac

    /bin/ls "${lsopt}" "${@}"
}

# long listing
# Arguments: $@ -> what to list
ll ()
{
    ls -lh "${@}"
}

# list all files
# Arguments: $@ -> what to list
la ()
{
    ls -A "${@}"
}

# list by column and type
# Arguments: $@ -> what to list
l ()
{
    ls -CF "${@}"
}

# grep with colours by default
# Arguments: $@ -> what to match
grep ()
{
    /usr/bin/grep --color=auto "${@}"
}

# fgrep with colours by default
# Arguments: $@ -> what to match
fgrep ()
{
    /usr/bin/fgrep --color=auto "${@}"
}

# egrep with colours by default
# Arguments: $@ -> what to match
egrep ()
{
    /usr/bin/egrep --color=auto "${@}"
}

# verbose move/rename
# Arguments: $@ -> what to match
mv ()
{
    /bin/mv -i "${@}"
}

# verbose copy
# Arguments: $@ -> what to match
cp ()
{
    /bin/cp -i "${@}"
}

# copy with progress using rsync
pcp ()
{
    rsync --progress -ah "${@}"
}

# make a file executable
# Arguments: $@ -> what to match
cx ()
{
    /bin/chmod +x "${@}"
}

# count lines
# Arguments: $@ -> what to match
cl ()
{
    /usr/bin/wc -l "${@}"
}

# sort files
# Arguments: $@ -> what to match
fsort ()
{
    ls -lSh "${@}" 2>/dev/null | tail +2 | awk '{print $5 "\t" $9}'
}

# sort mixed (directories & files)
# Arguments: $@ -> what to match
dsort ()
{
    du -s "${@}" 2>/dev/null | sort -rn | awk '{print $2}' | xargs du -sh 2>/dev/null
}

# simple way to keep a backup of a file
# Arguments: $1 -> the file
bkup ()
{
    if [ $# -ne 1 ]
    then
        puse "bkup file"
        return 1
    fi

    file_copy=${1}.$(date +%Y%m%d.%H%M.ORIG)
    mv -f ${1} ${file_copy}
    printf "Backing up ${1} to ${file_copy}\n"
    cp -p "${file_copy}" "${1}"

    unset file_copy
}

# show a message near the mouse
# useful for things like ``./build ; msg "libc build"''
# Arguments: $1 -> the message
msg ()
{
    type xmessage 2>/dev/null

    if [ $? -ne 0 ]
    then
	perr "xmessage is required, please install it."
	return 1
    fi
    
    if [ $# -ne 1 ]
    then
        puse "msg 'my message'"
        return 1
    fi

    test $? -eq 0 && out=success
    out=${out-failure}
    
    msg="${1}: ${out}"

    xmessage -buttons ok -default ok -nearmouse "${msg}" 2>/dev/null

    unset out err msg
}

# print a specific line of a file
# Arguments: $1 -> the line number
#            $2 -> the file
pln ()
{
    if [ $# -ne 2 ]
    then
        puse "pln line file"
        return 1
    fi

    sed -n "${1}p" ${2}
}

# create a directory and enter it
# Arguments: $1 -> the directory name
mkcd ()
{
    if [ $# -ne 1 ]
    then
        puse "mkcd directory"
        return 1
    fi

    mkdir "${1}" && cd "${1}"
}

# list all the files that are newer than the given
# Arguments: $1 -> the file name
newer()
{
    if [ $# -ne 1 ]
    then
        puse "newer file"
        return 1
    fi

    ls -t | sed "/^${1}\$/q" | grep -v "${1}"
}

# list all the files that are older than the given
# Arguments: $1 -> the file name
older()
{
    if [ $# -ne 1 ]
    then
        puse "older file"
        return 1
    fi

    ls -tr | sed "/^${1}\$/q" | grep -v "${1}"
}

# detect double words (eg. "hello my   my friend")
# Arguments: $1 -> the file(s) to be checked
dword()
{
    if [ $# -ne 1 ]
    then
        puse "dword file"
        return 1
    fi

    awk '
    FILENAME != prev {
        NR = 1
        prev = FILENAME
    }
    NF > 0 {
        if ($1 == lastword)
	    printf "%s:%d:`%s`\n", FILENAME, NR, $1
        for (i = 2; i <= NF; i++)
	    if ($i == $(i-1) )
	    printf "%s:%d:`%s`\n", FILENAME, NR, $i
	if (NF > 0)
	    lastword = $NF
    }' "${@}"
}

# count word frequencies
# Arguments: $1 -> the file(s) to use while counting
wfreq()
{
    if [ $# -ne 1 ]
    then
        puse "wfreq file"
        return 1
    fi

    awk '
    {
        for (i = 1; i <= NF; i++)
            cnt[$i]++
    }
    END {
        for (w in cnt)
            print w, cnt[w]
    }' "${@}"
}

# get the numeric value of a month (eg. march = 3)
# Arguments: $1 -> the month's name
# Variables: nmonth -> set to the value of the month
n_month()
{
    if [ $# -ne 1 ]
    then
        puse "n_month month"
        return 1
    fi

    nmonth=0

    case $1 in
	jan*) nmonth=1  ;;
	feb*) nmonth=2  ;;
	mar*) nmonth=3  ;;
	apr*) nmonth=4  ;;
	may*) nmonth=5  ;;
	jun*) nmonth=6  ;;
	jul*) nmonth=7  ;;
	aug*) nmonth=8  ;;
	sep*) nmonth=9  ;;
	oct*) nmonth=10 ;;
	nov*) nmonth=11 ;;
	dec*) nmonth=12 ;;
	*) perr "Incorrect month." ; return 1 ;;
    esac

    export nmonth
}

# /usr/bin/cal improved
# examples: `cal y' shows the full current year
#           `cal mar' shows march of the current year
#           `cal apr - jun' shows april-june of the current year (note the spaces)
cal()
{
    cyear=$(date | awk '{ print $4 }')  # current year

    case $# in
	1)
	    case $1 in
		[yY]*) year=$cyear ;;
		jan*|feb*|mar*|apr*|may*|jun*|jul*|aug*|sep*|oct*|nov*|dec*) month=$1; year=$cyear ;;
		*) year=$1 ;;
	    esac ;;
	2)  month=$1; year=$2 ;;
	3)  month=$1; month2=$3 ; year=$cyear ;; # eg. cal mar - jun
	*)  month=$1; year=$2 ;;
    esac

    if [ -z $month2 ] ; then
	/usr/bin/cal $month $year
    else			# assume month range
	# TODO: replace (with an array?) and loop to avoid code duplication
	n_month $month
	test $? -eq 0 && m1=$nmonth
	n_month $month2
	test $? -eq 0 && m2=$nmonth
	for m in $(seq $m1 $m2) ; do
	    /usr/bin/cal $m $year
	done
    fi

    unset cyear year month month2
}

