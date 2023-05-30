eksctl create iamserviceaccount \
  --region $REGION \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts \
  --role-name AmazonEKS_EBS_CSI_DriverRole_singapore_test

aws eks describe-cluster --region $REGION  --name $CLUSTER_NAME  --query "cluster.identity.oidc.issuer" --output text

eksctl create addon --name aws-ebs-csi-driver --region $REGION --cluster $CLUSTER_NAME --service-account-role-arn arn:aws:iam::886632063643:role/AmazonEKS_EBS_CSI_DriverRole09 --force
