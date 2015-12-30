#!/bin/bash
#
###############################################################################
# hydrastatus [-s]
#
#    Prints the status of the hydra cluster in a formatted table.
#    Nodes with 80% load or 80% memory use are colored red.
#
# OPTIONS:
#  -s   print result synchronously, omit to print asynchronously
#
#
# Sean Bell 2011


###############################################################################
# EDIT THIS TO CHANGE THE MACHINES BEING QUERIED

# basename prefix:
MACHINE_PREFIX="phoenix"

# id following prefix:
#MACHINE_IDS="s1 s2 s3 s4 s5 $(seq 0 18) $(seq 100 109)"
MACHINE_IDS="$(seq 0 28)"
MACHINE_ID_FORMAT="%02d"

# suffix following id:
#MACHINE_SUFFIX=".cs.cornell.edu"
MACHINE_SUFFIX=""

# length of machine name that will be unique from left
# if this is incorrect, the table may have extra empty rows but
# otherwise will work
UNIQ_LEN=9


###############################################################################
# Implementation:

if [ "$1" == "-s" ]; then
    sync=1
else
    sync=0
fi

# use temporary file to store results
TMPFILE=~/.hydrastatus.$$
if [ -f $TMPFILE ]; then
    echo "Tempfile $TMPFILE already exists!"
    exit
fi

#trap "echo trap1; kill 0; echo trap2; rm -f $TMPFILE; echo trap3" SIGINT SIGTERM EXIT
trap "pkill -P $$; rm -f $TMPFILE; exit" SIGINT SIGTERM EXIT

# local variables
printing=0
done=0
printtotal=0

# print current results
printresult(){
    # sort using special number, remove number, then print result in a table with red rows for overloaded nodes
    table="$(<$TMPFILE sort -nr | uniq -w $UNIQ_LEN | sort -n | awk 'NF>=12 { if ($7 > $10 * 0.8 || $11 > $12 * 0.8 || $13 !~ ".*G") printf "\033[1;31m"; printf "%8s  |  %2d %-5s  |  %2d cpus  |  load %5.2f, %5.2f, %5.2f  (%6.2f %%)  |  mem %6d / %6d MB (%6.2f %%)  |  /tmp  %s\n", $2, $3, $4, $10, $7, $8, $9, 100.0*$7/$10, $11, $12, 100.0*$11/$12, $13; if ($7 > $10 * 0.8 || $11 > $12 * 0.8 || $13 !~ ".*G") printf "\033[m\017" } NF<12 {printf "%8s  |\n", $2}')"

    # print result
    if [ "$sync" != "1" ]; then
        clear
    else
        echo -en "\r"
    fi
    echo "$0"
    echo -e "$table"

    # compute totals
    if [ "$printtotal" == "1" ]; then
        tnodes=$(cat $TMPFILE | grep -c load)
        tload=$(<$TMPFILE awk '{ SUM += $7 } END { print SUM }')
        tcpus=$(<$TMPFILE awk '{ SUM += $10 } END { print SUM }')
        tmem1=$(<$TMPFILE awk '{ SUM += $11 } END { print SUM }')
        tmem2=$(<$TMPFILE awk '{ SUM += $12 } END { print SUM }')
        tcpuperc=$(echo "100.0 * $tload / $tcpus" | bc)
        tmemperc=$(echo "100.0 * $tmem1 / $tmem2" | bc) 

        echo -e "\nTOTAL:  $tnodes nodes  |  $tcpus cpus  |  load $tload / $tcpus ($tcpuperc %)  |  mem $tmem1 / $tmem2 MB ($tmemperc %)"
    fi

    # if still running
    if [ "$done" == "0" ]; then
        echo -e "\nquerying nodes..."
    fi
}

# initial message
if [ "$sync" == "1" ]; then
    echo -n "querying nodes..."
else
    for f in $MACHINE_IDS; do
		if [ $f -ge 0 ] 2>/dev/null; then
			ff=$(printf $MACHINE_ID_FORMAT $f)
		else
			ff=$f
		fi
        echo "$ff $MACHINE_PREFIX$ff" >> $TMPFILE
    done

    printtotal=0
    printresult
    printtotal=1
fi

# query all machines
for f in $MACHINE_IDS; do
    (
	if [ $f -ge 0 ] 2>/dev/null; then
		ff=$(printf $MACHINE_ID_FORMAT $f)
	else
		ff=$f
	fi
    echo "$ff $MACHINE_PREFIX$ff $(ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=30 $MACHINE_PREFIX$ff$MACHINE_SUFFIX 'echo $(uptime | sed -r "s/^.*([0-9]+)\s+users?,\s+load average: (.*$)/\1 users load average \2/" | tr "," " ") $(grep -c processor /proc/cpuinfo) $(free -m | grep + | awk '\''{print $3 " " ($3+$4)}'\'') $(df -h /tmp | grep tmp | grep -E -o "\w*.?\w*\s*[0-9]+%") END' 2>/dev/null)" | grep END 1>>$TMPFILE
    if [[ "$sync" != "1" && "$printing" == "0" ]]; then
        sleep 0
        if [ "$printing" == "0" ]; then
            printing=1
            printresult
            printing=0
        fi
    fi
    ) &
done

# wait for result
wait

# print final result
done=1
printresult

# clean up
rm -f $TEMPFILE

