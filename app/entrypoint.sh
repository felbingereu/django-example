#!/usr/bin/env sh

# check if required environment variables are set
[ -z ${SQL_HOST:? SQL_HOST must be specified} ] && error=1
[ -z ${SQL_PORT:? SQL_PORT must be specified} ] && error=1
[ ! -z ${error+x} ] && exit 1

# check whether the database is accessible via the network
echo -n "Waiting for postgresql database..."
while ! nc -z "${SQL_HOST}" "${SQL_PORT}"; do
    sleep 0.1
done
echo -e "\b\b\b ✓ "

# check if required environment variables are set
[ -z ${SQL_USER:? SQL_USER must be specified} ] && error=1
[ -z ${SQL_PASSWORD:? SQL_PASSWORD must be specified} ] && error=1
[ -z ${SQL_DATABASE:? SQL_DATABASE must be specified} ] && error=1
[ ! -z ${error+x} ] && exit 1

python manage.py collectstatic --no-input
python manage.py migrate

# shellcheck disable=SC2198
if [ -z "${@}" ]; then
    # determine whether gunicorn should be started in debug mode
    [[ "${DEBUG}" != "0" ]] && debug=1
    gunicorn app.wsgi:application --bind 0.0.0.0:8000 ${debug:+--log-level DEBUG}
else
    exec "${@}"
fi
