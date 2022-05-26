import os
import pathlib
import subprocess

TEMPLATE = pathlib.Path(__file__).parents[1] / "template"

_EXTRA_ENV = {
    "GIT_AUTHOR_NAME": "Alice",
    "GIT_AUTHOR_EMAIL": "alice@example.com",
    "GIT_AUTHOR_DATE": "Thu, 01 Jan 1970 00:00:00 +0000",
    "GIT_COMMITTER_NAME": "Bob",
    "GIT_COMMITTER_EMAIL": "bob@example.com",
    "GIT_COMMITTER_DATE": "Thu, 01 Jan 1970 00:00:00 +0000",
}


def test_new_package_passes_tests(tmp_path):
    def check_call(cmd):
        subprocess.check_call(cmd, cwd=tmp_path, env=os.environ | _EXTRA_ENV)

    subprocess.check_call(["copier", "--defaults", str(TEMPLATE), str(tmp_path)])
    check_call(["git", "add", "."])
    check_call(["git", "commit", "-m", "Add boilerplate from template"])
    check_call(
        [
            "bash",
            "-c",
            (
                "set -e;"
                "source ./init_env.sh;"
                "pip install -r requirements.txt;"
                "make check_all"
            ),
        ],
    )
