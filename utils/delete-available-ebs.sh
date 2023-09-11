# Available 상태의 PVC 삭제 Script

#!/bin/bash

# AWS 리전을 설정합니다. 예를 들어, us-west-2
AWS_REGION="ap-northeast-2"

# "available" 상태의 EBS 볼륨 ID를 가져옵니다.
VOLUME_IDS=$(aws ec2 describe-volumes --region $AWS_REGION --filters Name=status,Values=available --query "Volumes[*].[VolumeId]" --output text)

# 각 볼륨을 삭제합니다.
for VOLUME_ID in $VOLUME_IDS
do
  echo "Deleting EBS volume $VOLUME_ID in $AWS_REGION..."
  aws ec2 delete-volume --region $AWS_REGION --volume-id $VOLUME_ID
done

echo "Deletion process completed."
