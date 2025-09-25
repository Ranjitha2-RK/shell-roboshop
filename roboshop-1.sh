#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-083d903c3fd30a343" # Replace with your SG ID
ZONE_ID="Z10394194WVGUSFSTERF" #REPALCE WITH YOUR id 
DOMAIN_NAME="daws86s.sbs"

for instance in $@
do
  INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-083d903c3fd30a343 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

  # if frontend is not there then it will take private IP
  if [ $instance != "frontend" ]; then
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
      RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.daws86s.sbs
  else
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
      RECORD_NAME="$DOMAIN_NAME" #daws86s.sbs
  fi

  echo "$instance: $IP"

  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }
    '
done