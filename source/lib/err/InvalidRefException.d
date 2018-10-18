module lib.err.iref;

import std.string: format;

import lib.err.valid: ValidationException;

public class InvalidRefException : ValidationException {
  this(const string path, const string schema) {
    super(format("References must be absolute paths to "
    ~ `the root of the resource directory.  Example '/schema/wdk/...'.
    Invalid Ref: %s
    Schema File: %s`, path, schema));
  }
}
