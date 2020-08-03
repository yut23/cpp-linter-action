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

    for prob_path, flags in problems.items():
        make_command = ['bear', 'make', f'{make_options}', flags]

        print(f'make command = {make_command}')

        with cd(f'Exec/{prob_path}'):

            print(f'making in Exec/{prob_path}')

            _, stderr = subprocess.Popen(make_command,
                                      stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT).communicate()
            if stderr is not None:
                raise Exception('bear make encountered an error')

            clang_tidy_command = ['python3', 'external/cpp-linter-action/run-clang-tidy.py', 
                f'-header-filter={header_filter}', 
                f'-ignore-files={ignore_files}', '-j', '2', 
                f'-checks={input_checks}', r'>> $GITHUB_WORKSPACE/clang-tidy-report.txt']

            subprocess.Popen(clang_tidy_command,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-make-options',
                        default='',
                        help='make options')
    parser.add_argument('SHAs', nargs='*', default=None,
                        help='SHAs to be compared')
    parser.add_argument('-header-filter', default='', 
    help='header filter')
    parser.add_argument('-ignore-files', default='', 
    help='ignore these files')
    parser.add_argument('-input-checks', default='', 
    help='input checks')

    args = parser.parse_args()

    run(SHAs=args.SHAs, make_options=args.make_options, 
        header_filter=args.header_filter, 
        ignore_files=args.ignore_files, input_checks=args.input_checks)