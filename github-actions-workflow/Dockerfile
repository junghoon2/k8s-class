# 베이스 이미지로 Python 3.8을 사용합니다.
FROM python:3.8

# 작업 디렉토리 설정
WORKDIR /app

# Python 의존성 파일을 컨테이너로 복사
COPY requirements.txt requirements.txt

# 의존성 설치
RUN pip install -r requirements.txt

# 나머지 파일을 작업 디렉토리로 복사
COPY . .

# Flask 애플리케이션 실행
CMD [ "python", "./app.py" ]
