import subprocess
import sys


def find_files(SHAs=None):
    diff_command = ['git', 'diff', '--name-only']

    if SHAs is not None:
        diff_command += SHAs

    stdout, stderr = subprocess.Popen(diff_command,
                                      stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT).communicate()

    if stderr is not None:
        raise Exception('git diff encountered an error')

    files = [f for f in stdout.decode('utf-8').strip().split('\n') 
             if f[:6] == 'Source']
    print(files)

    # look for whether any files have changed in these directories
    flag_dirs = {'diffusion': ('USE_DIFFUSION', 'science/flame_wave'),
                 'gravity': ('USE_GRAVITY', 'science/flame_wave'),
                 'mhd': ('USE_MHD', 'mhd_tests/BrioWu'),
                 'radiation': ('USE_RADIATION', 'radiation_tests/Rad2Tshock'),
                 'sdc': ('USE_TRUE_SDC', 'reacting_tests/reacting_convergence')}

    # see which directories contain changed files
    changed_directories = set()
    for f in files:
        d = f.split('/')[1]
        if d in flag_dirs:
            changed_directories.add(d)

    problems = {}
    for d in changed_directories:
        flag, prob = flag_dirs[d]
        if prob in problems:
            problems[prob] += f' {flag}=TRUE'
        else:
            problems[prob] = f'{flag}=TRUE'

    # no special flags, use default
    if not problems:
        problems['science/flame_wave'] = ""

    print(problems)

    return problems


if __name__ == '__main__':

    if len(sys.argv) > 1:
        find_files(sys.argv[1:])
    else:
        find_files()
