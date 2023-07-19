resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = "arn:aws:iam::{ACCOUNT_ID}:role/ebs-csi-switch-singapore-test"
  addon_version            = "v1.20.0-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"

  lifecycle {
    ignore_changes = [
      service_account_role_arn
    ]
  }
}
