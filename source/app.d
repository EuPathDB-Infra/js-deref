import std.file: getcwd;
import std.path: buildPath;
import std.stdio: writeln;

import lib.deref;

int main(string[] args)
{
  if (args.length < 2) {
    writeln(`js-deref
    usage:
      js-deref <input-dir> <output-dir>`);
    return 1;
  }

  const string cwd = getcwd();
  new Dereferencer(cwd.buildPath(args[1]), cwd.buildPath(args[2])).run();

  return 0;
}
