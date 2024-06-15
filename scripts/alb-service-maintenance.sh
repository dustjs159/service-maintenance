#!/bin/bash

set -eux

SERVICE_MAINTENANCE="$1"
ALB_MAINTENANCE_ON_CONFIG_FILE="./config/alb-maintenance-on-config.json"
ALB_MAINTENANCE_OFF_CONFIG_FILE="./config/alb-maintenance-off-config.json"
TEMP_FILE="./config/temp-config.json"
ALB_RULES=(
    $2 # API1 ALB rule ARN
    $3 # API2 ALB rule ARN
)
TARGETGROUPS=(
    $4 # API1 targetgroup ARN
    $5 # API2 targetgroup ARN 
)

if [ $SERVICE_MAINTENANCE = "on" ]; then
    for rule in "${ALB_RULES[@]}"; do
        aws elbv2 modify-rule \
            --rule-arn "$rule" \
            --actions file://$ALB_MAINTENANCE_ON_CONFIG_FILE \
            --no-cli-pager
        
        status=$?
        if [ $status -eq 0 ]; then
            echo "SUCCESS"
        else
            echo "ERROR"
        fi
    done
elif [ $SERVICE_MAINTENANCE = "off" ]; then
    for i in "${!ALB_RULES[@]}"; do
        for j in "${!TARGETGROUPS[@]}"; do
            if [ $i -eq $j ]; then
                cat $ALB_MAINTENANCE_OFF_CONFIG_FILE | jq --arg TARGETGROUP "${TARGETGROUPS[j]}" '.[].ForwardConfig.TargetGroups[0].TargetGroupArn=$TARGETGROUP' > $TEMP_FILE
                mv $TEMP_FILE $ALB_MAINTENANCE_OFF_CONFIG_FILE
                aws elbv2 modify-rule \
                    --rule-arn "${ALB_RULES[i]}" \
                    --actions file://$ALB_MAINTENANCE_OFF_CONFIG_FILE \
                    --no-cli-pager
                
                status=$?
                if [ $status -eq 0 ]; then
                    echo "SUCCESS"
                else
                    echo "ERROR"
                fi
                break
            fi
        done
    done
else
    echo "ERROR"
fi
