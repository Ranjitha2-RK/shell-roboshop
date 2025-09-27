#!/bin/bash

USERID=$(id -u)
R="\e[31m]"
G="\e[32m]"
Y="\e[33m]"
N="\e[0m]"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/mongodb.sh
START_TIME=$(date +%s)

mkdir -p "$LOGS_FOLDER"
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
  echo "ERROR:: Please run this script with root privelege"
  exit 1 # failure is other than 0
fi

VALIDATE(){ #functions receive input through args just like shell script args
  if [ $1 -ne 0 ]; then
    echo -e "$2 ... $R is failre $N" | tee -a $LOG_FILE
    exit 1
  else
    echo -e "$2 ... $G success" | tee -a $LOG_FILE
  fi
}



END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo  -e "Script executed in: $Y $TOTAL_TIME Seconds $N"