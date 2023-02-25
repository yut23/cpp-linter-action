import argparse
import shlex
from contextlib import contextmanager
import os
import subprocess
from contextlib import contextmanager

from find_changed_files import find_files


@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)


def run(SHAs=None, make_options='', header_filter='',
        ignore_files='', config_file='', use_gpu=False, run_linter=False):

    problems = find_files(SHAs)

    GITHUB_WORKSPACE = os.environ.get('GITHUB_WORKSPACE')

    for prob_path, flags in problems.items():
        if run_linter:
            make_command = 'bear -- '
        else:
            make_command = ''

        if use_gpu:
            make_command += f'make {make_options} USE_MPI=FALSE USE_OMP=FALSE USE_CUDA=TRUE CUDA_ARCH=60 ' + flags
        else:
            make_command += f'make {make_options} USE_MPI=FALSE USE_OMP=FALSE USE_CUDA=FALSE ' + flags

        print(f'make command = {make_command}')

        with cd(f'Exec/{prob_path}'):

            print(f'making in Exec/{prob_path}')

            # this will raise a CalledProcessError if the command fails
            subprocess.run(make_command, shell=True, check=True)

            if run_linter:
                header_filter = shlex.quote(header_filter)
                ignore_files = shlex.quote(ignore_files)
                clang_tidy_command = f"python3 {GITHUB_WORKSPACE}/external/cpp-linter-action/run-clang-tidy.py -j 2 -header-filter={header_filter} -ignore-files={ignore_files} -config-file={config_file}"
                print(f'clang_tidy_command = {clang_tidy_command}')
                clang_tidy_command += f" | tee -a {GITHUB_WORKSPACE}/clang-tidy-report.txt"

                subprocess.run(clang_tidy_command, shell=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-make-options',
                        default='-j 2',
                        help='make options')
    parser.add_argument('SHAs', nargs='*', default=None,
                        help='SHAs to be compared')
    parser.add_argument('-header-filter', default='',
                        help='header filter')
    parser.add_argument('-gpu', action='store_true',
                        help='compile with GPU')
    parser.add_argument('-run-linter', action='store_true',
                        help='Run C++ linter')
    parser.add_argument('-ignore-files', default='amrex|Microphysics',
                        help='ignore these files')
    parser.add_argument('-config-file', default=".clang-tidy",
                        help='path to the config file')

    args = parser.parse_args()

    run(SHAs=args.SHAs, make_options=args.make_options,
        header_filter=args.header_filter,
        ignore_files=args.ignore_files, config_file=args.config_file,
        use_gpu=args.gpu, run_linter=args.run_linter)
