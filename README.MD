# Kext Configurations Database

This branch doesn't contain any kext file, but only kext configurations.

## Adding a kext configuration

In order to add a kext configuration to this database, you have to edit `catalog.json` file first.

### Editing `catalog.json` file

`catalog.json` file is sorted in alphabetical order. To add a new kext, find a suitable place and add the name of the
kext (namely `title`) followed by the original kext file name. Suppose, you have a `BlaBla.kext`, you can add it like
this:
 
 ```json
 {
    "SomeKextAbove" : "...",
    "BlaBla": {
      "kext": "BlaBla.kext",
      "remote_url": "https://example.com/config.json"
    },
    "SomeKextBelow": "..."
 } 
 ```
 Notice: The `title` is important, since the name of the directory (as explained below) must be the same as the `title`.
 
 NOTE: `remote_url` contains the remote `config.json` file (filename can be anything having `.json` suffix) instead of
       the one hosted here. All the document locations (except unzipped locations) inside this config is relative to the
       URL. In this way, `config.json` can be changed directly from a remote repository containing the kext.  
  
 ### Adding a `config.json` file
 
Create a directory same as the `title` mentioned above (in this example, `BlaBla`). Now, create a `config.json` file
inside it. You can create multiple configuration files,in which case, the other config files must have `config-` prefix
and must be described in the default `config.json` file.
 
From now on, we will use . (dot) notation for objects and [] (square brackets) for arrays. So,
```json
{
   "authors" : [
       {
         "name" : "Some one",
         "email": "example@email"
       }
   ]
}
```
becomes
```
authors[].name
authors[].email
```

#### `config.json` Schema
- `name` : (String) Name of the Kext (same as the `title`)
- `kext`: (String) Kext binary file name
- `description`: (String) A short description of the Kext
- `homepage`: (String) The main location of the kext or kext source
- `version`: (String) Current version of the kext
- `versions`: (Array|null) Previous/other version of the kext (use this when only necessary)
    - `versions[].version`: (String) The kext version
    - `versions[].since`: (String) The first supported macOS version
- `target`: (String) Where to install the kext (Either `LE` or `SLE`)
- `since`: (String) The version of macOS from which the kext can be installed
- `last`: (String|null) The version of macOS to which the kext can be installed (null = latest)
- `bin`: (Object) Binary file(s)
    - `bin.recommend`: (String|null) Recommended binary (either `dev` or `rel`)
    - `bin.dev`: (Object|null)
        - `bin.dev.url`: (String) Link to download the debug kext
        - `bin.dev.script`: (String|null) Location of the custom script relative to this `config.json` file (see below)
        - `bin.dev.loc`: (String|null) Relative location of the kext after the file has been extracted
    - `bin.rel`: (Object) 
        - `bin.rel.url`: (String) Link to download the release kext
        - `bin.rel.script`: (String|null) Location of the custom script relative to this `config.json` file (see below)
        - `bin.rel.loc`: (String|null) Relative location of the kext after the file has been extracted
    - `bin.post-install`: [Optional] (String) Relative location to the post-installation script. Just like custom script
                          , it must not have any Xcode dependencies. 
- `changes`: (String) A list of changes in the latest version (Markdown Supported)
- `guide`: (String) A general guideline on how to use the kext. This may contain boot arguments and their behavior, etc.
            or just the content of readme.md (Markdown Supported)
- `time`: (String) Release date of the kext (format: `YYYY-MM-DD HH:MM:SS` or `YYYY-MM-DD`)
- `license`: (String|Array|null) Kext license
- `authors`: (Array)
    - `authors[].name`: (String) Name of the author
    - `authors[].email`: (String|null) Email of the author
    - `authors[].homepage`: (String|null) Homepage of the author
- `require`: (Object|null) Contains a list of kext along with their versions. Example:
    ```json
    {
      "require": {
        "Lilu": "1.2.0^",
        "IntelGraphicsFixup": "1.2.0"
      }
    }
    ```
    If you need exact version, you can omit the `^` at the end. Use the wildcard `*` to denote all.
- `conflict`: (Object|null) 
    - `conflict.kexts`: (Object) Contains a list of kext along with their versions that have conflict(s) with this kext.
                        (Similar to the above example)
    - `conflict.action`: (String) Either `delete` or `none`
- `replaced_by`: (Object|null) The kext has been replaced by others.
    - `replaced_by.since`: (String) The version of macOS after which the kext has been replaced
    - `replaced_by.kexts`: (Object) List of alternative kext(s). (Similar to the above example)
- `suggest`: (Array|null) Suggest kext(s)
    - `suggest[].name`: (String) Name of the kext
    - `suggest[].text`: (String|null) Information on why this is suggested (Markdown supported)

NOTE: `bin.dev.script` and `bin.dev.loc` cannot be null at the same time. Same is applicable for `bin.rel.script` and
      `bin.rel.loc`.

NOTE 2: `conflict.kexts` can contain any kext name without the extension. It also supports wildcards.

#### Custom script
A custom script can be used to extract the kext from the given URL. The only argument that is supplied to the script is
the URL of the kext. The output should be a single line containing the location of the kext (including the name of the
kext!). If no output is provided, the default location will be considered. The default location is `/tmp/name/kext`,
`name` and `kext` are defined in the `confing.json` file.

NOTE: Custom scripts must not have any Xcode dependencies! Thus, it only supports a handful of scripting languages, eg.
      Bash, Python2.7, PHP, Perl, etc. Custom script can be Mach-O executable. So, executables written in C/C++, Obj-C,
      etc. are also supported.
