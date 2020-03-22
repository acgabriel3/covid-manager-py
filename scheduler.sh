#!/bin/sh
# Gera os horários de execucão dos scripts, podendo eles ser de execucão recorente (20) ou
# de execucão simples (E)

scriptfolder=$1
scriptpattern=".*\.(R$|py$)"
cronstatus=$(ps -ef | grep crond)
atdstatus=$(ps -e | grep -e "atd$")

# Gera o schedule do crontab e edita o arquivo
gen_crontab() {
	flag=${2:(-1)}
	value=${2:0:(-1)}
	intervals="* * * * *"

	case $flag in
		"M") intervals=$(echo "$intervals" | sed -e "s/\*/\*\/${value}/1") ;;
		"H") intervals=$(echo "$intervals" | sed -e "s/\*/\*\/${value}/2") ;; 
	esac

	case $extension in
		"py") executable="python" ;;
		"R") executable="R" ;;
	esac	
	cronjob=$(printf "%b %b %b\n" "$intervals" "$executable" "$1")

	(crontab -l 2>/dev/null; echo "$cronjob") | crontab -
}

# Cria uma entrada no 'at'
gen_at() {
	time=$(echo $2 | sed -r 's/.{2}/&:/')
	echo "$1" | at "$time" 2> /dev/null
}

# Verifica se o script deve ser executado periodicamente (R) ou uma vez (E)
generate_schedule() {
	flag=${2:0:1}	
	value=${2:1}
	extension="${file##*.}"

	case $flag in
		"E") gen_at $1 "$value" ;;
		"R") gen_crontab $1 "$value" "$extension" 
	esac
}

# Faz o parse dos arquivos e extrai as flags
parse_schedule() {
	for file in $files; do
		flags=$(sed -e "s/.*_//" -e "s/\.[^.]*$//"  <<< $file)
		generate_schedule "$file" "$flags"
	done
}

# Exibe a ajuda para o comando
display_help() {
	echo "scheduler.sh - Gera um cronograma de execucão para scripts"
	echo "Uso: ./scheduler.sh SCRIPTFOLDER"
	echo "Flags:"
	echo " -h  Exibe esse menu de ajuda"
}


if [[ -z $1 || $* == *-h* ]]
then
	display_help
	exit  1
fi

if [[ -z "$cronstatus" || -z $atdstatus ]]
then
	echo "cron ou atd não iniciados"
	exit 1
else
	files=$(find $scriptfolder -type f -regextype egrep -regex "$scriptpattern" \
	-exec realpath {} \;)
	parse_schedule "$files"
	exit 0
fi
