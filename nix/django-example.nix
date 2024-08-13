{
  lib,
  buildPythonPackage,
  setuptools,
  djangorestframework,
  gunicorn,
  psycopg2,
}:
buildPythonPackage rec {
  pname = "django-example";
  version = "0.0.1";
  pyproject = true;

  src = ../.;

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    djangorestframework
    gunicorn
    psycopg2
  ];

  postInstall = ''
    mkdir -p $out/bin
    cp -v ${src}/app/manage.py $out/bin/manage.py
    chmod +x $out/bin/manage.py
    wrapProgram $out/bin/manage.py --prefix PYTHONPATH : "$PYTHONPATH"
  '';

  meta = {
    description = "Django example";
    homepage = "https://github.com/felbingereu/django-example";
    maintainers = with lib.maintainers; [ felbinger ];
  };
}
