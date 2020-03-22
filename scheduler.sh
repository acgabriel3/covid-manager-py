#!/bin/sh
# Gera os horários de execucão dos scripts, podendo eles ser de execucão recorente (20) ou
# de execucão simples (E)

scriptfolder=$1
logfolder=$2
scriptpattern=".*\.(R$|py$)"
cronstatus=$(ps -ef | grep crond)
atdstatus=$(ps -e | grep -e "atd$")

get_executable() {
	case $1 in
		"py") executable="python" ;;
		"R") executable="R -q -f" ;;
	esac
	echo "$executable"	
}

# Gera o schedule do crontab e edita o arquivo
# Parâmetros:
#	$1 - Path do arquivo
#	$2 - Valor numérico com o período de repeticão
#	$3 - Extensão do arquivo
gen_crontab() {
	flag=${2:(-1)}
	value=${2:0:(-1)} 
	intervals="* * * * *"

	case $flag in
		"M") intervals=$(echo "$intervals" | sed -e "s/\*/\*\/${value}/1") ;;
		"H") intervals=$(echo "$intervals" | sed -e "s/\*/\*\/${value}/2") ;; 
	esac

	executable=$(get_executable "$3")
	cronjob=$(printf "%b %b %b >> ${logfolder}/cronlogs\n" "$intervals" "$executable" "$1")
	echo "$cronjob"
		
	(crontab -l 2>/dev/null; echo "$cronjob") | crontab -
}

# Cria uma entrada no 'at'
# Parâmetros:
# 	$1 - Path do arquivo
# 	$2 - Hora da execucão do script
#	$3 - Extensão do arquivo
gen_at() {
	time=$(echo $2 | sed -r 's/.{2}/&:/')
	executable=$(get_executable $3)
	command=$(echo "$timestamp" "$executable $1 >> ${logfolder}/atlogs")
	echo "$command" | at "$time" 2> /dev/null
}

# Verifica se o script deve ser executado periodicamente (R) ou uma vez (E)
# Parâmetros:
#	$1 - Path do arquivo
#	$2 - Flags extraídas do arquivo
generate_schedule() {
	flag=${2:0:1}	
	value=${2:1}
	extension="${file##*.}"

	case $flag in
		"E") gen_at $1 "$value" "$extension" ;;
		"R") gen_crontab $1 "$value" "$extension" 
	esac
}

# Faz o parse dos arquivos e extrai as flags
parse_schedule() {
	for file in $1; do
		flags=$(sed -e "s/.*_//" -e "s/\.[^.]*$//"  <<< $file)
		generate_schedule "$file" "$flags"
	done
}

# Exibe a ajuda para o comando
display_help() {
	echo "scheduler.sh - Gera um cronograma de execucão para scripts, passando-se a pasta onde estão os scripts e a pasta onde serão salvos os logs."
	echo "Uso: ./scheduler.sh SCRIPTFOLDER LOGFOLDER"
	echo "Flags:"
	echo " -h  Exibe esse menu de ajuda"
}

# Main
if [[ -z $1 || -z $2 ||$* == *-h* ]]
then
	display_help
	exit  1
fi

if [[ -z "$cronstatus" || -z $atdstatus ]]
then
	echo "cron ou atd não iniciados"
	exit 1
else
	logfolder=$(echo "$logfolder" | sed 's/\/$//')
	files=$(find $scriptfolder -type f -regextype egrep -regex "$scriptpattern" \
	-exec realpath {} \;)
	parse_schedule "$files"
	exit 0
fi
