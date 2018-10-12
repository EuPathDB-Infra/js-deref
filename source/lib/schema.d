module lib.schema;

import std.json: JSONValue;
import std.path: buildPath;
import std.array: replace;
import std.digest.sha: sha1Of;
import std.base64: Base64;

import lib.json_schema;

/**
 * JSON Schema file contents and details.
 */
class Schema {
  private string file;
  private string local;

  private string key;
  private JSONValue value;
  private bool reffed;
  private Schema[string] defs;
  private bool deffed;

  /**
   * @param file   base file name for this JSON Schema
   * @param local  parent directory path relative to the
   *               resource root.
   * @param hasRef whether or not this schema file contains
   *               a schema reference.  This also counts
   *               internal references.
   * @param value  JSON content of the schema file.
   */
  this(const string file, const string local, bool hasRef, JSONValue value) {
    this.file   = file;
    this.local  = local;
    this.value  = value;
    this.reffed = hasRef;
  }

  /**
   * Returns the base file name for this JSON schema.
   */
  public string getFile() const {
    return this.file;
  }

  /**
   * Gets the path relative to the resource root.
   */
  public string getLocalDir() const {
    return this.local;
  }

  /**
   *
   */
  public string getPath(const string wd) const {
    return buildPath(wd, this.getPath());
  }

  public string getPath() const {
    return buildPath(local, file);
  }

  public bool hasRef() const {
    return this.reffed;
  }

  public void setHasRef(bool reffed) {
    this.reffed = reffed;
  }

  public JSONValue* getValue() {
    return &this.value;
  }

  public void appendDef(const string path, Schema s) {
    defs[path] = s;
  }

  public string safeKey() {
    if (key is null || key.length == 0)
      key = Base64.encode(sha1Of(getPath("")));
    return key;
  }

  public void resolveDefs() {
    if(deffed)
      return;

    if((DEFINITIONS_KEY in value.object) == null && defs.length > 0) {
      JSONValue[string] val;
      value.object[DEFINITIONS_KEY] = JSONValue(val);
    }

    foreach(const string path, Schema s; defs) {
      s.resolveDefs();

      JSONValue[string] copy = s.value.objectNoRef;
      if(JSONValue* defs = (DEFINITIONS_KEY in copy)) {
        foreach(const string def; defs.object.keys)
          value.object[DEFINITIONS_KEY].object[def] = defs.object[def];
        copy.remove(DEFINITIONS_KEY);
      }

      copy.remove(SCHEMA_KEY);

      value.object[DEFINITIONS_KEY].object[s.safeKey] = copy;
    }

    deffed = true;
  }
}
