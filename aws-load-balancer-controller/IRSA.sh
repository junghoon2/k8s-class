eksctl create iamserviceaccount \
  --cluster=my-cluster \
  --namespace=kube-system \
  --region=ap-northeast-2 \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
