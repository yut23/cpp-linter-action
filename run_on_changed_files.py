from find_changed_files import find_files 
import subprocess 
import sys 
import argparse
from contextlib import contextmanager
import os

@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)


def run(SHAs=None, make_options='', header_filter='',
        ignore_files='', input_checks=''):

    problems = find_files(SHAs)

    GITHUB_WORKSPACE = os.environ.get('GITHUB_WORKSPACE')

    for prob_path, flags in problems.items():
        make_command = f'bear make {make_options} USE_MPI=FALSE USE_OMP=FALSE USE_CUDA=FALSE' + flags

        print(f'make command = {make_command}')

        with cd(f'Exec/{prob_path}'):

            print(f'making in Exec/{prob_path}')

            process = subprocess.run(make_command,
                                      stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT,
                                      shell=True)
            print(process.stdout.decode('utf-8'))
            if process.stderr is not None:
                raise Exception('bear make encountered an error')

            clang_tidy_command = rf'python3 {GITHUB_WORKSPACE}/external/cpp-linter-action/run-clang-tidy.py -header-filter={header_filter} -ignore-files={ignore_files} -j 2 -checks={input_checks}'
            print(f'clang_tidy_command = {clang_tidy_command}')

            process = subprocess.run(clang_tidy_command,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT,
                             shell=True)

            print(process.stdout.decode('utf-8'))

            with open(f'{GITHUB_WORKSPACE}/clang-tidy-report.txt', 'a') as f:
                f.write(process.stdout.decode('utf-8'))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-make-options',
                        default='-j 2',
                        help='make options')
    parser.add_argument('SHAs', nargs='*', default=None,
                        help='SHAs to be compared')
    parser.add_argument('-header-filter', default='', 
    help='header filter')
    parser.add_argument('-ignore-files', default='amrex|Microphysics', 
    help='ignore these files')
    parser.add_argument('-input-checks', default='bugprone-*,performance-*,portability-*,modernize-*,clang-analyzer-*,cppcoreguidelines-*,readability-*,-cppcoreguidelines-pro-bounds-pointer-arithmetic,-cppcoreguidelines-pro-bounds-constant-array-index,-clang-diagnostic-unknown-warning-option,-clang-diagnostic-unknown-pragmas,-readability-avoid-const-params-in-decls,-cppcoreguidelines-owning-memory', 
    help='input checks')

    args = parser.parse_args()

    run(SHAs=args.SHAs, make_options=args.make_options, 
        header_filter=args.header_filter, 
        ignore_files=args.ignore_files, input_checks=args.input_checks)