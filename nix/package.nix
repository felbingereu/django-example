{
  lib,
  gettext,
  python3,
}:
let
  ignoredPaths = [
    ".github"
    "resources"
  ];
in
python3.pkgs.buildPythonApplication rec {
  pname = "django-example";
  version = "0.0.1";
  pyproject = false;

  src = lib.cleanSourceWith {
    filter = name: type: !(type == "directory" && builtins.elem (baseNameOf name) ignoredPaths);
    src = lib.cleanSource ../.;
  };

  nativeBuildInputs = [
    gettext
  ];

  dependencies = with python3.pkgs; [
    django
    djangorestframework
    gunicorn
    psycopg2
  ];

  postBuild = ''
    ${python3.pythonOnBuildForHost.interpreter} -OO -m compileall .
    ${python3.pythonOnBuildForHost.interpreter} app/manage.py collectstatic --clear --no-input
    # ${python3.pythonOnBuildForHost.interpreter} app/manage.py compilemessages
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/django-example/static/dashboard
    cp -r app/{app,base,static,manage.py} $out/lib/django-example
    chmod +x $out/lib/django-example/manage.py

    makeWrapper $out/lib/django-example/manage.py $out/bin/django-example \
      --prefix PYTHONPATH : "${python3.pkgs.makePythonPath dependencies}"

    runHook postInstall
  '';

  passthru = {
    inherit python3;
  };

  meta = {
    description = "Django example";
    homepage = "https://github.com/felbingereu/django-example";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ felbinger ];
    mainProgram = "django-example";
  };
}
