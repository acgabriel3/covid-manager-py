#!/bin/sh
# Gera os horários de execucão dos scripts, podendo eles ser de execucão recorente (20) ou
# de execucão simples (E)

scriptfolder=$1
scriptpattern=".*\.(R$|py$)"
cronstatus=$(ps -ef | grep crond)
atdstatus=$(ps -e | grep -e "atd$")


parse_schedule() {
	suffix=".R|.py"
	for file in $files; do
		foo=$(sed -e "s/.*_//" -e "s/\.[^.]*$//"  <<< $file)
		echo "$foo"
	done
}

if [[ -z "$cronstatus" || -z $atdstatus ]]
then
	echo "cron or atd not started"
else
	files=$(find $scriptfolder -type f -regextype egrep -regex "$scriptpattern" \
	-exec realpath {} \;)
	parse_schedule "$files"
fi
