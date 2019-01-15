#############################################################
# Set the appropriate environmental variables               #
#############################################################

##
## Set Oracle Specific Environmental env's
##
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
export ORACLE_SID="oggsrc"
DBROLE=""

RESTORE_USER=`whoami`


##
## For Warning and Text manupulation
##
bold=$(tput bold)
reset=$(tput sgr0)
bell=$(tput bel)
underline=$(tput smul)


#############################################################
# Functions to handle exceptions and erros                  #
#############################################################

###
### Handling error while running script
###
### $1 : Error Code
### $2 : Error message in detail
###

ReportError(){
			echo "########################################################"
			echo "Error during Running Script"
			echo -e "$1: $2"
			echo "########################################################"
			exit 1;
}


ReportInfo(){
			echo "########################################################"
			echo "Information by the script : $CURSCRIPT"
			echo -e "INFO : $1 "
			echo "########################################################"
}


###
### FUNCTION TO CHECK FUNDAMENTAL VARIABLES
###

CheckVars(){
	if [ "${1}" = "" ]
	then
		ReportError "RERR-001" "${bell}${bold}${underline}ORACLE_HOME${reset} Env variable not Set. Aborting...."
		
	elif [ ! -d ${1} ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${1}${reset}\" not found or ORACLE_HOME Env invalid. Aborting...."
	
	elif [ ! -x ${1}/bin/sqlplus ]
	then
		ReportError  "RERR-003" "Executable \"${bell}${bold}${underline}${1}/bin/sqlplus${reset}\" not found; Aborting..."
       
	elif [ "${2}" = "" ]
        then
                ReportError  "RERR-004" "${bell}${bold}${underline}ORACLE_SID${reset} Env variable not Set. Aborting..."

	elif [ "${3}" != "oracle" ]
        then
                ReportError  "RERR-004" "User "${bell}${bold}${underline}${3}${reset}" not valid for running script; Aborting..."
	else
		return 0;
	fi
}



checkSidValid(){
	param1=("${!1}")
	check=${2}  
	statusSID=0
	for i in ${param1[@]}
		do
			if [ ${i} == $2 ];
				then
				statusSID=1
				break
			esle
                echo $i; 
			fi 
        done
    return $statusSID;
}

###
### Get Oracle SID env 
###
FunGetOracleSID(){
myarr=($(ps -ef | grep ora_smon| grep -v grep | awk -F' ' '{print $NF}' | cut -c 10-))
checkSidValid myarr[@] ${ORACLE_SID}
if [ $? -eq 0 ]
	then
		ReportError  "\nRERR-005" "ORACLE_SID : ${bell}${bold}${underline}${ORACLE_SID}${reset} Env is invalid, no instance is running. Aborting..."
fi

ReportInfo "\nChecking for validness for ORACLE_SID: ${bell}${bold}${underline}${ORACLE_SID}${reset} passed....."
}

###
### Get the Database open mode...
###
FunGetDBRole(){
DBROLE=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select DATABASE_ROLE from v\$database;
END
)
}

FunRestartMR(){
DBROLE=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
alter database recover managed standby database cancel;
alter database recover managed standby database using current logfile disconnect from session;
END
)
}

CheckVars ${ORACLE_HOME} ${ORACLE_SID} ${RESTORE_USER}
FunGetDBRole ${ORACLE_HOME}

if [ "${DBROLE}" = "PHYSICAL STANDBY" ]
then
	ReportInfo "\nReclaiming Space............"
	rm -f /u01/app/oracle/diag/rdbms/oggsrc/oggsrc/trace/*.trc
	rm -f /u01/app/oracle/diag/rdbms/oggsrc/oggsrc/trace/*.trm
	#rm /findata1/admin/bokho/bdump/*.trc
	#rm /findata1/admin/bokho/udump/*.trc
	FunRestartMR ${ORACLE_HOME}
else
	ReportInfo "\nDatabase is not Standby database"
fi

