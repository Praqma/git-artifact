ARG ALPINE_GIT_DOCKER_VERSION=dummy

FROM alpine/git:${ALPINE_GIT_DOCKER_VERSION}

RUN apk fix && \
    apk --no-cache --update add bash

ARG USER_ID
ARG GROUP_ID

RUN addgroup -g ${GROUP_ID} gituser && \
    adduser -D -u ${USER_ID} -G gituser gituser

USER gituser

RUN git config --global user.email "git@artifacts.com"
RUN git config --global user.name "Git Artifacts"

RUN git config --global --add safe.directory /git

ENV PATH="/git:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

