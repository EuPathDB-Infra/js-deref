module lib.bug.pdb;

debug(deref) {
  import std.stdio: writefln;

  public void printDebug(
    const void*[string] params,
    const string func = __FUNCTION__,
    const string pac = __MODULE__
  ) {
    writefln("%s(%s)", __FUNCTION__[__MODULE__.length + 1..$], params);
  }
}