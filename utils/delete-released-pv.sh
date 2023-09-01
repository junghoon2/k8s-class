# feat by GPT
#!/bin/bash

# Released 상태의 모든 PVs 가져오기
released_pvs=$(kubectl get pv --no-headers | awk '$5 == "Released" {print $1}')

# 각 PV에 대해
for pv in $released_pvs; do
  echo "Processing Released PV: $pv"

  # PV 삭제
  kubectl delete pv $pv

  echo "Deleted PV: $pv"
done
