ARG ALPINE_VERSION=3.16

### Builder ###
FROM python:3.10.5-alpine${ALPINE_VERSION} as builder

ARG AWS_CLI_VERSION=2.9.1

RUN apk add --no-cache git unzip groff build-base libffi-dev cmake
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR aws-cli
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# reduce image size: remove autocomplete and examples
RUN rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/data -name completions-1*.json -delete
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

FROM alpine:${ALPINE_VERSION}

ENV CRON_EXPRESSION="*/5 * * * *"

USER root
RUN apk --update add --no-cache logrotate apk-cron && \
    rm -f /etc/logrotate.d/*

#  Install AWSCli v2
COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/

ADD logrotate.sh /etc/logrotate.sh
RUN chmod +x /etc/logrotate.sh

ADD entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh
ENTRYPOINT ["/etc/entrypoint.sh"]