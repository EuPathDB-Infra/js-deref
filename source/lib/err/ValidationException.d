module lib.err.valid;

import std.exception;

public class ValidationException : Exception {
  public this(const string message) {
    super(message);
  }
}
