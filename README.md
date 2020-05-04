Github action for linting the C code.
Uses clang-tidy, clang-format, and cppcheck.

Example of usage:
```
name: c-linter

on: [pull_request]
jobs:
  c-linter:
    name: c-linter
    runs-on: ubuntu-latest
    steps:
      - name: c-linter
        uses: AMReX-Astro/clang-tidy-action@master
        with: 
          github_token: ${{ secrets.GITHUB_TOKEN }}
          build_path: /path/to/executable
```

There are also the options `make_options` which defines the Make arguments that shall be used by `clang-tidy`, and `ignore_files` which defines a regex which `clang-tidy` uses to ignore files. 
