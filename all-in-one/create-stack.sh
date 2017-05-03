#!/bin/bash

aws cloudformation create-stack \
--stack-name wso2am-all-in-one \
--template-body file://WSO2AM210-All-In-One-Deployment.template \
--parameters ParameterKey=KeyName,ParameterValue=wso2-key
