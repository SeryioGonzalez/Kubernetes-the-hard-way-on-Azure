#!/bin/bash

source config.sh

echo 'TRYING TO READ VARIABLE subscription_id'

if [ -z "$subscription_id" ]
then
      echo "\$subscription_id is empty"
	  echo "Please input subscription id"
	  read subscription_id
fi

echo "subscription_id is $subscription_id"

az account set -s $subscription_id
