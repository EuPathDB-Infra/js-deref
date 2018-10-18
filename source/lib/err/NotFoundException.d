module lib.err.nf;

import std.string: format;

import lib.err.valid: ValidationException;

public class NotFoundException : ValidationException {
  this(const string path, const string schema) {
    super(format(`References not found in the resource directory.
    Invalid Ref: %s
    Schema File: %s`, path, schema));
  }
}