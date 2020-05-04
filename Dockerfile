FROM ubuntu:latest

LABEL com.github.actions.name="c-linter check"
LABEL com.github.actions.description="Lint your code with clang-tidy in parallel to your builds"
LABEL com.github.actions.icon="code"
LABEL com.github.actions.color="gray-dark"

LABEL repository="https://github.com/AMReX-Astro/cpp-linter-action"

WORKDIR /build
RUN apt-get update
RUN apt-get -qq -y install curl clang-tidy cmake jq clang cppcheck clang-format bear g++ gfortran python3 git

COPY runchecks.sh /entrypoint.sh
COPY run-clang-tidy.py /run-clang-tidy.py
CMD ["bash", "/entrypoint.sh"]
