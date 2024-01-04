#!/bin/bash

# 카운트 파일 경로
COUNT_FILE="/data/count.file"

# 카운트 파일이 존재하는지 확인하고, 없으면 초기화
if [[ ! -f "$COUNT_FILE" ]]; then
    echo 0 > "$COUNT_FILE"
fi

# 현재 카운트 읽기
count=$(cat "$COUNT_FILE")
count=$((count+1))

# 카운트 업데이트
echo "$count" > "$COUNT_FILE"

# 5회 실행 후 중지
if [[ "$count" -ge 5 ]]; then
    echo "Maximum execution count reached. Exiting."
    exit 0
fi

# 실제 작업 수행
echo "Performing task..."
# 작업 로직...
