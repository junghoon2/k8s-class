eksctl create iamserviceaccount \
  --cluster=switch-japan-staging \
  --region=ap-northeast-1 \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole-switch-tokyo \
  --attach-policy-arn=arn:aws:iam::886632063643:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
