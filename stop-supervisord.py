#!/usr/bin/env python
# Supervisord event-handler which tries to stop supervisord by sending
# SIGQUIT/SIGKILL signal to it.

import argparse
import os
import signal
import sys
import time


def write_stdout(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def kill_supervisord(pid_file, signal):
    try:
        with open(pid_file, 'r') as fp:
            pid = int(fp.readline())

        os.kill(pid, signal)
    except Exception as e:
        write_stdout('Could not kill supervisor: ' + e.strerror + '\n')


def main(pid_file='/var/run/supervisord.pid', max_tries=5):
    tries = 0

    while tries < max_tries:
        tries += 1
        write_stdout('READY\n')

        line = sys.stdin.readline()
        write_stdout('This line kills supervisor: ' + line)

        kill_supervisord(pid_file, signal.SIGQUIT)
        time.sleep(5)

        write_stdout('RESULT 2\nOK')

    if tries >= max_tries:
        write_stdout('Unable to SIGQUIT Supervisord, use SIGKILL instead...\n')
        kill_supervisord(pid_file, signal.SIGKILL)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('pid_file', nargs='?',
                        default='/var/run/supervisord.pid')
    parser.add_argument('max_tries', nargs='?', default=5, type=int)

    args = parser.parse_args(sys.argv[1:])
    main(args.pid_file, args.max_tries)
