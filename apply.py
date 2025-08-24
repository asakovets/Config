#!/usr/bin/env python3

import argparse
import os
import os.path
from pathlib import Path
import platform
import shutil
from collections import namedtuple

WINDOWS: bool = platform.system() == "Windows"
MACOS: bool = platform.system() == "Darwin"
LINUX: bool = platform.system() == "Linux"


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


def apply(config, resolver):
    ConfigPath = namedtuple("ConfigPath", ["path", "prio"])

    def r(*args):
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

    def _(left):
        def c(left, right):
            if type(right) is tuple:
                right = r(*right)
            config(left, right)

        return RArrow(left, c)

    win = RArrow(100, lambda l, r: lambda: None if not WINDOWS else ConfigPath(r, l))
    mac = RArrow(100, lambda l, r: lambda: None if not MACOS else ConfigPath(r, l))
    lin = RArrow(100, lambda l, r: lambda: None if not LINUX else ConfigPath(r, l))
    any = RArrow(10, lambda l, r: lambda: ConfigPath(r, l))

    _("ripgreprc") >> "~/.config/ripgreprc"

    _("neovide") >> (win >> "%LocalAppData%/neovide", any >> "~/.config/neovide")

    _("clangd") >> (
        win >> "%LocalAppData%/clangd",
        lin >> "~/.config/clangd",
        mac >> "%LibraryPreferences%/clangd",
    )


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

    parser.add_argument("--sys", dest="sys", choices=["win", "linux", "macos"])

    args = parser.parse_args()
    if args.sys:
        global WINDOWS, LINUX, MACOS
        WINDOWS = args.sys == "win"
        LINUX = args.sys == "linux"
        MACOS = args.sys == "macos"

    resolver = PathResolver()
    if WINDOWS:
        resolver.add("LocalAppData", "~/AppData/Local/")
        resolver.add("RoamingAppData", "~/AppData/Roaming/")

    if MACOS:
        resolver.add("LibraryPreferences", "~/Library/Preferences")

    def config(a, b):
        if type(b) is Ignore:
            if b.reason:
                print(f"Ignoring {a}: {b.reason}")
            else:
                print(f"Ignoring {a}")
        else:
            b = os.path.expanduser(b)
            if args.clean:
                if args.dry_run:
                    print("Will remove", b)
                else:
                    p = Path(b)
                    if p.is_symlink() or p.is_file():
                        p.unlink()
                    elif p.is_dir():
                        shutil.rmtree(str(p))

            else:
                if args.dry_run:
                    print("Will link", b, "->", a)
                else:
                    a = os.path.join(os.path.dirname(__file__), a)
                    make_symlink(a, b)

    apply(config, resolver)

if __name__ == "__main__":
    main()
