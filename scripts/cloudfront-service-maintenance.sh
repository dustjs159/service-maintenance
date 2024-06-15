#!/bin/bash

set -eux

SERVICE_MAINTENANCE="$1"
CLOUDFRONT_DISTRIBUTION_ID=$2
CURRENT_DISTRIBUTION_FILE="./config/current_distribution_file.json"
NEW_DISTRIBUTION_FILE="./config/new_distribution_file.json"
MAINTENANCE_PATH="/maintenance"
ORIGINAL_PATH=""

if [ $SERVICE_MAINTENANCE = "on" ]; then
    aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID > $CURRENT_DISTRIBUTION_FILE
    status=$?
    if [ $status -eq 0 ]; then
        ETAG=$(cat $CURRENT_DISTRIBUTION_FILE | jq -r ".ETag")

        cat $CURRENT_DISTRIBUTION_FILE | jq "del(.ETag)" | jq ".Distribution.DistributionConfig" | jq --arg INDEX_PATH "$MAINTENANCE_PATH" '.Origins.Items[0].OriginPath=$INDEX_PATH' > $NEW_DISTRIBUTION_FILE

        aws cloudfront update-distribution \
            --id $CLOUDFRONT_DISTRIBUTION_ID \
            --distribution-config "file://$NEW_DISTRIBUTION_FILE" \
            --if-match $ETAG \
            --no-cli-pager

        status=$?
        if [ $status -eq 0 ]; then
            aws cloudfront create-invalidation \
                --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
                --paths "/*" \
                --no-cli-pager
            rm -rf $CURRENT_DISTRIBUTION_FILE $NEW_DISTRIBUTION_FILE
        else
            echo "ERROR"
        fi
    else
        echo "ERROR"
    fi
elif [ $SERVICE_MAINTENANCE = "off" ]; then
    aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID > $CURRENT_DISTRIBUTION_FILE
    status=$?
    if [ $status -eq 0 ]; then
        ETAG=$(cat $CURRENT_DISTRIBUTION_FILE | jq -r ".ETag")

        cat $CURRENT_DISTRIBUTION_FILE | jq "del(.ETag)" | jq ".Distribution.DistributionConfig" | jq --arg INDEX_PATH "$ORIGINAL_PATH" '.Origins.Items[0].OriginPath=$INDEX_PATH' > $NEW_DISTRIBUTION_FILE

        aws cloudfront update-distribution \
            --id $CLOUDFRONT_DISTRIBUTION_ID \
            --distribution-config "file://$NEW_DISTRIBUTION_FILE" \
            --if-match $ETAG \
            --no-cli-pager

        status=$?
        if [ $status -eq 0 ]; then
            aws cloudfront create-invalidation \
                --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
                --paths "/*" \
                --no-cli-pager
            rm -rf $CURRENT_DISTRIBUTION_FILE $NEW_DISTRIBUTION_FILE
        else
            echo "ERROR"
        fi
    else
        echo "ERROR"
    fi
else
    echo "ERROR"
fi