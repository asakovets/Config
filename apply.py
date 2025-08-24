#!/usr/bin/env python3

import argparse
import os
import os.path
from pathlib import Path
import platform
import shutil
import subprocess
from collections import namedtuple

WINDOWS: bool = platform.system() == "Windows"
MACOS: bool = platform.system() == "Darwin"
LINUX: bool = platform.system() == "Linux"

IDEAL_BRANCH = "main"
LOCAL_BRANCH = "local"

gVerbose: bool = False


def proc_spawn(*args, **kwargs):
    cmd = [*args]
    if gVerbose:
        print("running", cmd)
    return subprocess.run(cmd, **kwargs)


def git_new_branch(branch_name):
    return proc_spawn("git", "branch", branch_name)


def git_switch_branch(branch_name):
    return proc_spawn("git", "switch", branch_name)


def git_commit():
    return proc_spawn("git", "commit")


def to_posix_path(p):
    return p.replace("\\", "/")


class PathResolver(object):
    resolvers: dict

    def __init__(self):
        self.resolvers = dict()

    def __resolve(self, name):
        return self.resolvers[name]()

    def add(self, name, resolver):
        if type(resolver) is str:
            self.resolvers[name] = lambda: self.resolve(resolver)
        else:
            self.resolvers[name] = resolver

    def resolve(self, pat):
        orig_pat = pat
        pat = os.path.expanduser(pat)
        result = str()
        while pat:
            if not pat[0] == "%":
                result += pat[0]
                pat = pat[1:]
            else:
                pat = pat[1:]
                p = pat.find("%")
                assert p != -1, f"invalid pattern: {orig_pat}"
                name = pat[:p]
                result += self.__resolve(name)
                pat = pat[p + 1 :]
        return result


class Ignore(Path):
    reason: str

    def __init__(self, reason="", *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.reason = reason


IGNORE = Ignore()


def make_symlink(target, link_name):
    if os.path.lexists(link_name):
        if os.path.islink(link_name) or os.path.isfile(link_name):
            os.remove(link_name)
        elif os.path.isdir(link_name):
            shutil.rmtree(link_name)
    os.symlink(target, link_name, target_is_directory=os.path.isdir(target))


class RArrow(object):
    left: object
    cb: object

    def __init__(self, left, cb):
        self.left = left
        self.cb = cb

    def __rshift__(self, right):
        return self.cb(self.left, right)


ConfigPath = namedtuple("ConfigPath", ["path", "prio"])


def r(resolver, *args):
    cur = None
    for arg in args:
        path_rule = arg()
        if path_rule:
            if not cur:
                cur = path_rule
            elif path_rule.prio > cur.prio:
                cur = path_rule
    if cur:
        if type(cur.path) is Ignore:
            return cur.path
        return resolver.resolve(cur.path)
    return Ignore()


win = RArrow(100, lambda l, r: lambda: None if not WINDOWS else ConfigPath(r, l))
mac = RArrow(100, lambda l, r: lambda: None if not MACOS else ConfigPath(r, l))
lin = RArrow(100, lambda l, r: lambda: None if not LINUX else ConfigPath(r, l))
any = RArrow(10, lambda l, r: lambda: ConfigPath(r, l))


def tool(name, config, resolver):
    def c(left, right):
        if type(right) is tuple:
            right = r(resolver, *right)
        config(left, right)

    return RArrow(name, c)


def apply(config, resolver):
    def t(name):
        return tool(name, config, resolver)

    ripgreprc = t("ripgreprc")
    neovide = t("neovide")
    clangd = t("clangd")

    ripgreprc >> "~/.config/ripgreprc"

    neovide >> (win >> "%LocalAppData%/neovide", any >> "~/.config/neovide")

    clangd >> (
        win >> "%LocalAppData%/clangd",
        lin >> "~/.config/clangd",
        mac >> "%LibraryPreferences%/clangd",
    )


def symlink():
    def config(a, b):
        if type(b) is Ignore:
            if b.reason:
                print(f"Ignoring {a}: {b.reason}")
            else:
                print(f"Ignoring {a}")
        else:
            b = os.path.expanduser(b)
            b = to_posix_path(b)
            if args.clean:
                if args.dry_run:
                    print("Will remove", b)
                else:
                    p = Path(b)
                    print("remove", p)
                    if p.is_symlink() or p.is_file():
                        p.unlink()
                    elif p.is_dir():
                        shutil.rmtree(str(p))

            else:

                def mklink(target, link):
                    assert os.path.isabs(link), f"not absolute path: {link}"
                    assert os.path.isabs(target), f"not absolute path: {target}"

                    if args.dry_run:
                        print("Will link", link, "->", target)
                    else:
                        dir = os.path.dirname(link)
                        os.makedirs(dir, exist_ok=True)
                        print("mklink", link, "->", target)
                        make_symlink(target, link)

                basedir = os.path.dirname(__file__)
                source_file = os.path.join(basedir, a)
                source_file = to_posix_path(source_file)

                if os.path.isfile(source_file):
                    if not os.path.exists(source_file):
                        print(f"not a valid path: {a}")
                    else:
                        mklink(source_file, b)

                else:
                    if args.dry_run:
                        print("Will mkdir -p", b)
                    else:
                        print("mkdir -p", b)
                        os.makedirs(b, exist_ok=True)
                    for target in os.listdir(source_file):
                        mklink(
                            os.path.join(source_file, target), os.path.join(b, target)
                        )

    apply(config, resolver)


def init():
    git_new_branch(LOCAL_BRANCH)
    git_switch_branch(LOCAL_BRANCH)


def apply():
    rc = git_commit()
    if rc.returncode == 0:
        git_switch_branch("main")
        proc_spawn("git", "cherry-pick", "local")
        git_switch_branch("local")
        proc_spawn("git", "merge", "--no-ff", "main")


def fetch():
    proc_spawn("git", "fetch", "origin", "main")
    proc_spawn("git", "merge", "--no-ff", "main")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-n",
        "--dry-run",
        dest="dry_run",
        action="store_true",
        help="Just show what would be done",
    )

    parser.add_argument(
        "-c",
        "--clean",
        dest="clean",
        action="store_true",
        help="Remove configuration files",
    )

    parser.add_argument(
        "--sys",
        dest="sys",
        choices=["win", "linux", "macos"],
        help="Override operating system",
    )
    parser.add_argument(
        "-v", "--verbose", dest="verbose", action="store_true", help="Be verbose"
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    parser_init = subparsers.add_parser("init", help="Init")
    parser_apply = subparsers.add_parser("apply", help="Apply")
    parser_fetch = subparsers.add_parser("fetch", help="Fetch")
    parser_symlink = subparsers.add_parser("symlink", help="Symlink")

    args = parser.parse_args()

    global gVerbose
    gVerbose = bool(args.verbose)
    gVerbose = True

    if args.sys:
        global WINDOWS, LINUX, MACOS
        WINDOWS = args.sys == "win"
        LINUX = args.sys == "linux"
        MACOS = args.sys == "macos"

    if args.command == "init":
        init()
    elif args.command == "apply":
        apply()
    elif args.command == "fetch":
        fetch()
    elif args.command == "symlink":
        symlink()


if __name__ == "__main__":
    main()
