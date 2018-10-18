module lib.deref;

import std.stdio: writefln, writeln, toFile;
import std.file: dirEntries, SpanMode, readText, mkdirRecurse;
import std.path: buildNormalizedPath, dirName, baseName, buildPath;
import std.json: JSONValue, parseJSON, JSONException, JSONType;
import std.string: indexOf, split, format;

import lib.schema;
import lib.json_schema;
import lib.err;
debug(deref) import lib.bug.pdb: printDebug;

private const string INCLUDES_DIR = "includes";

private const string SCHEMA_FILTER = "*.json";

private const string ERR_JSON_PARSE = `Failed to parse JSON file contents.
    Schema File: %s`;

class Dereferencer {

  private Schema[string] all;

  private const string inDir;

  private const bool writeOutput;

  private const string outDir;

  /**
   * @param inDir  input schema home
   * @param outDir schema output directory
   */
  this(const string inDir, const string outDir) {
    debug(deref) printDebug(["inDir": inDir, "outDir": outDir]);
    this.inDir  = inDir;
    this.outDir = outDir;
    this.writeOutput = true;
  }

  /**
   * @param inDir  input schema home
   * @param outDir schema output directory
   */
  this(const string inDir) {
    debug(deref) printDebug(["inDir": inDir]);
    this.inDir  = inDir;
    this.outDir = "";
    this.writeOutput = false;
  }

  /**
   *
   */
  public int run() {
    debug(deref) printDebug([]);

    if (!scanDir())
      return 1;

    if (!seekAll(this.all))
      return 1;

    if(!writeOutput)
      return 0;

    foreach(Schema s; all) {
      s.resolveDefs();
      writeOut(s);
    }

    return 0;
  }

  private bool seekAll(ref Schema[string] all) {
    string[] errors;

    foreach(const string path, Schema s; all) {
      if (!s.hasRef())
        continue;

      try {
        seek(s, s.getValue());
      } catch (ValidationException e) {
        errors ~= e.msg;
      }
    }

    if (errors.length == 0)
      return true;

    writefln("Error: validation failed for %d schema files.\n", errors.length);
    foreach(const string e; errors)
      writefln("%s\n", e);

    return false;
  }

  private void writeOut(Schema s) {
    debug(deref) printDebug(["s": &s]);

    const string outPath = buildPath(outDir, s.getLocalDir());

    if (baseName(outPath) == INCLUDES_DIR)
      return;

    mkdirRecurse(outPath);
    toFile(s.getValue().toString(), s.getPath(outDir));
  }

  /**
   *
   */
  private void seek(Schema s, JSONValue* val) {
    debug(deref) printDebug(["s": &s, "val": val]);

    switch(val.type) {
      case JSONType.array:
        seekArray(s, val);
        return;
      case JSONType.object:
        seekObject(s, val);
        return;
      default:
        return;
    }
  }

  /**
   *
   */
  void seekObject(Schema s, JSONValue* value) {
    debug(deref) printDebug(["s": &s, "value": value]);

    foreach(const string key, ref JSONValue cur; value.object) {

      if (
        key == REFERENCE_KEY
        && cur.type == JSONType.string
        && cur.str()[0] != '#'
      ) {
        Schema res = resolve(cur.str(), s);
        const string path = res.getPath(outDir);

        value.object[key] = defPath(res.safeKey);
        s.appendDef(path, res);

      } else {
        seek(s, &cur);
      }
    }
  }

  /**
   * Iterates over JSON array elements and passes each to
   * the seek method.
   */
  void seekArray(Schema s, JSONValue* value) {
    debug(deref) printDebug(["s": &s, "value": value]);

    foreach(ref JSONValue cur; value.array)
      seek(s, &cur);
  }

  /**
   * Decides how to resove the given path, then pass it to
   * the correct file resolution method.
   */
  private Schema resolve(const string path, Schema s) {
    debug(deref) printDebug(["path": &path, "s": &s]);

    if(path[0] != '/')
      throw new InvalidRefException(path, s.getPath());

    return localResolve(path, s);
  }

  /**
   *
   */
  private Schema localResolve(const string path, Schema s) {
    debug(deref) printDebug(["path": &path, "s": &s]);

    const string normal = buildNormalizedPath(inDir, path[1..$]);
    Schema* found = (normal in all);

    if (found is null) {
      throw new NotFoundException(path, s.getPath());
    }

    return *found;
  }

  /**
   * Scan given directory for entries matching SCHEMA_FILTER
   * and pass them to processFile
   */
  private bool scanDir() {
    debug(deref) printDebug([]);
    string[] errors;

    foreach (string file; dirEntries(inDir, SCHEMA_FILTER, SpanMode.breadth)) {
      try {
        processFile(file);
      } catch (ValidationException e) {
        errors ~= e.msg;
      }
    }

    if (errors.length > 0) {
      writefln("Error: %d files could not be read due to JSON syntax errors", errors.length);
      foreach (const string e; errors) {
        writeln(e);
      }
      return false;
    }
    return true;
  }

  /**
   * Read the contents of a json schema file and build a
   * {@link Schema} instance containing the file details.
   */
  private void processFile(const string path) {
    debug(deref) printDebug(["path": &path]);

    const string body = readText(path);
    const string shortPath = dirName(path[inDir.length..$]);

    try {
      all[path] = new Schema(baseName(path), shortPath, checkRefs(body), parseJSON(body));
    } catch(JSONException e) {
      throw new BadJsonException(shortPath, e);
    }
  }
}



private string defPath(const string next) {
  debug(deref) printDebug(["next": &next]);

  return "#/definitions/" ~ next;
}

private bool checkRefs(const string s) {
  debug(deref) printDebug(["s": &s]);

  return s.indexOf(REFERENCE_KEY) != -1;
}
