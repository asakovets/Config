#!/usr/bin/env python3

import argparse
import os
import os.path
from pathlib import Path
import shutil


is_posix = os.name == "posix"


def local_config_dir():
    if is_posix:
        return os.path.expanduser("~/.config/")
    else:
        return os.path.expanduser("~/AppData/Local/")


def roaming_config_dir():
    if is_posix:
        return local_config_dir ()
    else:
        return os.path.expanduser("~/AppData/Roaming/")


def local(s):
    return os.path.join(local_config_dir(), s)


def roaming(s):
    return os.path.join(roaming_config_dir(), s)


def make_symlink(target, link_name):
    if os.path.lexists(link_name):
        if os.path.islink(link_name) or os.path.isfile(link_name):
            os.remove(link_name)
        elif os.path.isdir(link_name):
            shutil.rmtree(link_name)
    os.symlink(target, link_name, target_is_directory=os.path.isdir(target))


def config__create(source_loc, destination_loc, opts):
    source_loc = os.path.join(os.path.dirname(__file__), source_loc)
    make_symlink(source_loc, destination_loc)


def config__prune(source_loc, destination_loc, opts):
    p = Path(destination_loc)
    if p.is_symlink() or p.is_file():
        p.unlink()
    elif p.is_dir():
        shutil.rmtree(str(p))


def config__dry_run(source_loc, destination_loc, opts):
    print(f" {source_loc} => {destination_loc}")


def apply(config):
    config("ripgreprc", local("ripgreprc"))
    config("neovide", roaming("neovide"))


def main():
    opts = ""
    config_impl = config__create

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-n",
        "--dry-run",
        dest="dry_run",
        action="store_true",
        help="Just show what would be done",
    )

    args = parser.parse_args()

    if args.dry_run:
        config_impl = config__dry_run

    def config(a, b):
        config_impl(a, b, opts)

    apply(config)


if __name__ == "__main__":
    main()
