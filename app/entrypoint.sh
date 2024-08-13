#!/usr/bin/env sh

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
