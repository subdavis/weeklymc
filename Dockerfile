FROM java:8

ENV AWS_ACCESS_KEY_ID ""
ENV AWS_SECRET_ACCESS_KEY ""
ENV AWS_DEFAULT_REGION "us-east-1"

EXPOSE 25565
EXPOSE 8080

WORKDIR /

RUN apt update
RUN apt install -y git curl unzip awscli

COPY ./user_data_thin.sh .

CMD ["./user_data_thin.sh"]