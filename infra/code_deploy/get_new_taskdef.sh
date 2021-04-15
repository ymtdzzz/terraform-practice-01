#!/bin/bash

# set -eux

TAG=$1

# get current taskdef
# ref: https://github.com/aws/aws-cli/issues/3064#issuecomment-784614089
TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition terraform-practice-dev --region us-east-1 \
      --query '{  containerDefinitions: taskDefinition.containerDefinitions,
                  family: taskDefinition.family,
                  taskRoleArn: taskDefinition.taskRoleArn,
                  executionRoleArn: taskDefinition.executionRoleArn,
                  networkMode: taskDefinition.networkMode,
                  volumes: taskDefinition.volumes,
                  placementConstraints: taskDefinition.placementConstraints,
                  requiresCompatibilities: taskDefinition.requiresCompatibilities,
                  cpu: taskDefinition.cpu,
                  memory: taskDefinition.memory}')
ORIGINAL_TEXT=$(echo $TASK_DEFINITION | jq '.containerDefinitions[] | .image' -r | uniq)
REPLACED_TEXT=$(echo ${ORIGINAL_TEXT} | sed -z "s/:\S*/:$TAG/g")
ORIGINAL_ARR=($(echo $ORIGINAL_TEXT))
REPLACED_ARR=($(echo $REPLACED_TEXT))

for i in $(seq 1 ${#ORIGINAL_ARR[@]})
do
  # escape
  ORIGIN=$(echo ${ORIGINAL_ARR[i-1]} | sed 's/\./\\\./g' | sed 's/\//\\\//g')
  REPLACED=$(echo ${REPLACED_ARR[i-1]} | sed 's/\./\\\./g' | sed 's/\//\\\//g')
  TASK_DEFINITION=$(echo $TASK_DEFINITION | sed -z s/$ORIGIN/$REPLACED/g)
done

echo $TASK_DEFINITION >&1