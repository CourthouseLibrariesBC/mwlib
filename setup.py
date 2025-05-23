import os
import subprocess
from pathlib import Path

import toml
from Cython.Build import cythonize
from setuptools import Extension, setup

MWLIB_SRC_DIR = "src/mwlib"
MWLIB_MODULES_DIR = "mwlib"


def get_version():
    pyproject_toml_path = os.path.dirname(os.path.abspath(__file__)) + "/pyproject.toml"
    with open(pyproject_toml_path) as f:
        pyproject = toml.load(f)
    return pyproject["project"]["version"]


def build_deps():
    subprocess.run("make build", shell=True, check=True)


def get_ext_modules():
    extensions = [
        Extension("mwlib.parser.token._uscan", sources=[f"{MWLIB_SRC_DIR}/parser/token/_uscan.cc"]),
    ]
    for path in Path(MWLIB_SRC_DIR).rglob("**/*.pyx"):
        module_name = (
            path.relative_to(MWLIB_SRC_DIR).with_suffix("").as_posix().replace("/", ".")
        )
        module_name = "mwlib." + module_name
        extensions.append(
            Extension(
                module_name,
                sources=[str(path)],
                extra_compile_args=[
                    "-Wno-unreachable-code-fallthrough",
                    # ignore false positive warning "fallthrough annotation in unreachable code"
                    # https://github.com/cython/cython/issues/5041
                ],
            )
        )
    return extensions


def main():
    if Path("Makefile").exists():
        build_deps()

    long_description = Path("README.md").read_text()

    setup(
        name="mwlib",
        version=get_version(),
        ext_modules=cythonize(
            get_ext_modules(),
            compiler_directives={
                "language_level": 3,
                "boundscheck": False,
                "wraparound": False,
            },
        ),
        packages=[MWLIB_MODULES_DIR, "qs"],
        package_dir={"": "src"},
        include_package_data=True,
        package_data={
            "mwlib.writers.rl.locale": ["*.mo", "*.po"],
        },
        zip_safe=False,
        long_description=long_description,
        long_description_content_type="text/markdown",
    )


if __name__ == "__main__":
    main()
