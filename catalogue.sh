#!/bin/bash

USERID=$(id -u)
R="\e[31m]"
G="\e[32m]"
Y="\e[33m]"
N="\e[0m]"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$(pwd)
MONGODB_HOST=mongodb.daws86s.sbs
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/mongodb.sh

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

#### NodeJS ####
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating system user"
else
  echo -e "User already exit ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the catalogue application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing the existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "Install Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install MongoDB client"

#cat /var/log/shell-roboshop/catalogue.log | grep -A 20 "Load Catalogue Products"
#mongosh --host mongodb.daws86s.sbs </app/db/master-data.js
#cat /var/log/shell-roboshop/catalogue.log | grep -A 20 "Load Catalogue Products"

INDEX=$(mongosh mongodb.daws86s.sbs --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -le 0 ]; then
  mongosh --host mongodb.daws86s.sbs </app/db/master-data.js &>>$LOG_FILE
  VALIDATE $? "Load Catalogue Products"
else
  echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi


systemctl restart catalogue
VALIDATE $? "Restarted catalogue"

