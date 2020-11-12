FROM amazon/aws-cli:latest

RUN yum install -y zip
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
