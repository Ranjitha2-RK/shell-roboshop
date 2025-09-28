#!/bin/bash

USERID=$(id -u)
R="\e[31m]"
G="\e[32m]"
Y="\e[33m]"
N="\e[0m]"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.daws86s.sbs
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/mongodb.sh
MYSQL_HOST=mysql.daws86s.sbs

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

dnf install python3 gcc python3-deval -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating system user"
else
  echo -e "User already exit ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the payment application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing the existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzip payment"

pip3 install -r requirements.txt &>>$LOG_FILE

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload
systemctl enable payment &>>$LOG_FILE


systemctl restart payment