module lib.err.json;

import std.json: JSONException;
import std.string: format;

import lib.err.valid : ValidationException;

public class BadJsonException: ValidationException {
  public this(const string file, const JSONException e) {
    super(format(`%s:
    %s`, file, e.msg));
  }
}
