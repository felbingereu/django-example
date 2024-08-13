ARG PY_VERSION="3.12"

FROM python:${PY_VERSION}-alpine

# set work directory
WORKDIR /build

# install dependencies
COPY requirements.txt requirements.txt
RUN pip install --prefix=/build/venv -r requirements.txt

FROM python:${PY_VERSION}-alpine

# app config
ENV ALLOWED_HOSTS='0.0.0.0' DEBUG=0

# create the app user and directories
ENV HOME=/home/app
RUN mkdir -p ${HOME}/web/static \
 && addgroup -S app \
 && adduser -S app -G app \
 && chown -R app:app ${HOME}
WORKDIR ${HOME}/web

COPY --from=0 /build/venv/ /usr/local/

# copy project
COPY --chown=app:app . ${HOME}/web

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
EXPOSE 8000
USER app
