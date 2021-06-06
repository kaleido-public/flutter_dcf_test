FROM python:3
ENV PYTHONUNBUFFERED=1
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git
    
RUN git clone https://github.com/kaleido-public/Django-Test-Server-For-Dart.git
WORKDIR /Django-Test-Server-For-Dart
RUN pip install -r requirements.txt
RUN python manage.py makemigrations
RUN python manage.py migrate