import std.file: getcwd, exists;
import std.path: buildPath;
import std.stdio: writefln, writeln, stderr;

import lib.deref;
import lib.err.valid: ValidationException;

int main(string[] args)
{
  if (args.length < 2) {
    writeln(`js-deref
    usage:
      js-deref <input-dir> [output-dir]`);
    return 1;
  }

  const string cwd = getcwd();

  Dereferencer deref;
  const string inPath = cwd.buildPath(args[1]).trailingSlash();

  if (!inPath.exists()) {
    writefln("Input path does not exist: %s", inPath);
    return 1;
  }

  if (args.length == 2) {
    deref = new Dereferencer(inPath);
  } else {
    const string outPath = cwd.buildPath(args[2]).trailingSlash();
    deref = new Dereferencer(inPath, outPath);
  }

  try {
    return deref.run();
  } catch (ValidationException e) {
    stderr.writeln(e.msg);
    return 1;
  }
}

//TODO: Rehome us

private string trailingSlash(const string path) {
  return path[$-1] == '/' ? path : path ~ '/';
}
