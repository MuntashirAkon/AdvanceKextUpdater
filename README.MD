# Kext Configurations Database
This branch doesn't contain any kext file, but only kext configurations.

**Configuration Version: 0.9.2**

## Adding a kext configuration
In order to add a kext configuration to this database, you have to edit ***catalog.json*** file first.

### Editing *catalog.json* file
***catalog.json*** file is sorted in alphabetical order. To add a new kext, find a suitable place and add the name of the
kext (namely `title`) followed by the original kext file name. Suppose, you have a **FooBar.kext**, you can add it like
this:
 
 ```json
 {
    "SomeKextAbove" : "...",
    "FooBar": {
      "id": "com.buzz.FooBar",
      "remote_url": "https://example.com/config.json"
    },
    "SomeKextBelow": "..."
 } 
 ```
 Notice: The `title` is important, since the name of the directory (as explained below) must be the same as the `title`.
 
 **NOTE:** `remote_url` contains the remote ***config.json*** file instead of the one hosted here. All the document
       locations inside this config is relative to the URL, except unzipped locations (ie. `bin.rel.loc` and `bin.dev.loc`)
       which are relative to the zipped file. In this way, `config.json` can be changed directly from a remote repository
       containing the kext.  The zip file locations (ie. `bin.dev.url` and `bin.rel.url`) and `info` (ie. ***Info.plist*** file)
       location can be either a relative URL or an absolute URL. Make sure the absolute URL contains `http://` or `https://`
       prefix.
  
 ### Adding a *config.json* file
Create a directory same as the `title` mentioned above (in this example, `FooBar`). Now, create a ***config.json*** file
inside it. You can create multiple configuration files, in which case, the other config files must have the `config-` prefix
and must be described in the default ***config.json*** file.
 
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
- `name` : (String) Name of the Kext (same as the `title` of the **config.json**)
- `kext`: (String) Kext binary file name
- `info`: [Optional] (String) Relative or absolute URL to the ***Info.plist*** file of the kext, useful I/O Kit based extensions as the eligibility of installing the kext can be determined automatically using the plist file (you can manually edit this file instead of using the original ***Info.plist***). Only the `IOKitPersonalities` and `OSBundleLibraries` will be validated, version and other info will not be evaluated. (Not implemented yet)
- `description`: (String) A short description of the Kext
- `homepage`: (String) The main location of the kext or kext source
- `version`: (String) Current version of the kext
- `versions`: (Array|null) Previous/other version of the kext (use this when only necessary)
    - `versions[].version`: (String) The kext version
    - `versions[].since`: (String) The first supported macOS version
    - `versions[].location`: (String) Relative location of the ***config-*.json*** for the version
- `target`: (String) Where to install the kext (Either `LE` or `SLE`)
- `since`: (String) The version of macOS from which the kext can be installed
- `last`: (String|null) The version of macOS to which the kext can be installed (null = latest)
- `bin`: (Object) Binary file(s)
    - `bin.recommend`: (String|null) Recommended binary (either `dev` or `rel`)
    - `bin.dev`: (Object|null)
        - `bin.dev.url`: (String) Link to download the debug kext (*must be a zipped file*)
        - `bin.dev.script`: (String|null) Location of the custom script relative to this `config.json` file.
                           [See below](./README.MD#custom-script) for more information. 
        - `bin.dev.loc`: (String|null) Relative location of the kext after the file has been extracted
    - `bin.rel`: (Object) 
        - `bin.rel.url`: (String) Link to download the release kext (*must be a zipped file*)
        - `bin.rel.script`: (String|null) Location of the custom script relative to this `config.json` file.
                            [See below](./README.MD#custom-script) for more information.
        - `bin.rel.loc`: (String|null) Relative location of the kext after the file has been extracted
    - `bin.post-install`: [Optional] (String) Relative location to the post-installation script.
                            [See below](./README.MD#post-installation-script) for more information.
- `hw`: [Optional] (Object) Hardware configuration (to get more idea on where this kext can be installed)
    - `hw.match_audio`: [Optional] (Array|String) Matches specific audio codecs with or without revisions. Available
                                    Formats: `AudioCodec:Revision` or `AudioCodec` (e.g: `10EC0256:100002` or `10EC0256`)
    - `hw.match_connected`: [Optional] (Array|String) Matches the ID of specific connected device(s). Devices can be
                                        connected via USB, etc. ID format: `VendorID:ProductID`
    - `hw.match_cpu`: [Optional] (Array|RegEx String) Matches the specific CPU(s). CPU brand string can be found by running:
      ```bash
      sysctl -n machdep.cpu.brand_string
      ```
    - `hw.match_gpu`: [Optional] (Array|RegEx String) Matches the specific GPU(s). GPU chipset name can be found by running:
      ```bash
      system_profiler SPDisplaysDataType | grep "Chipset Model"
      ```
    - `hw.match_pci`: [Optional] (Array|String) Matches specific PCI ID(s). ID format: `VendorID:ProductID`
                                (eg. `8086:9d21`)
    - `hw.restrict`: [Optional] (Boolean) Whether to restrict installation of kext provided the criteria does not match
                     (Default: true)
- `sw`: [Option] (Object) Software configuration (to get more idea on where this kext can be installed)
    - `sw.kernel`: [Optional] (Object|String) Kernel configuration. If applicable for a single version, set as string.
        - `sw.kernel.min`: (String) Minimum kernel version
        - `sw.kernel.max`: (String|null) Maximum kernel version (null = No maximum value set)
    - `sw.restrict`: [Optional] (Boolean) Whether to restrict installation of kext provided the criteria does not match
                     (Default: true)
- `changes`: (String) A list of changes in the latest version (Markdown Supported)
- `guide`: (String) A general guideline on how to use the kext. This may contain boot arguments and their behavior, etc.
            or just the content of ***readme.md***. You can use `@see <url>` to refer an url rather than copy-and-pasting
            the guide itself. (Markdown Supported)
- `time`: (String) Release date of the kext (format: `YYYY-MM-DD HH:MM:SS` or `YYYY-MM-DD`)
- `license`: (String|Array|null) Kext license(s)
- `tags`: [Optional] (String) Tags are good for searching, should be comma separated
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
    - ~~`conflict.action`: (String) Either `delete` or `none`~~ Conflicts will be deleted
- `replaced_by`: (Object|null) The kext has been replaced by others.
    - `replaced_by.since`: (String) The version of macOS after which the kext has been replaced
    - `replaced_by.kexts`: (Object) List of alternative kext(s). (Similar to the above example)
- `suggest`: (Array|null) Suggest kext(s)
    - `suggest[].name`: (String) Name of the kext (without extension) or supported files WITH extension. See **NOTES**
                        bellow for a list of supported file extensions.
    - `suggest[].url`: [Optional] (String) Absolute URL to the homepage or URL where the relevant info can be found. If the
                       item is a kext and available in the repo, this key will be ignored.
    - `suggest[].text`: (String|null) Information on why this is suggested (Markdown supported)

#### Notes on the schema
- `bin.dev.script` and `bin.dev.loc` cannot be null at the same time. Same is applicable for `bin.rel.script` and
`bin.rel.loc`
- `conflict.kexts` can contain any kext name without the extension. It also supports wildcards
- All IDs are in hexadecimal string without the `0x` prefix and ***must be in the uppercase***
- Supported file extensions are: `.app`, `.sh`, `.pkg`, `.mkpg`, `.dmg`, `.dylib`, `.efi`

#### Custom script
A custom script can be used to extract and/or install the kext from the given URL.

```
USAGE: binary_file binary_url install_paths...
```

##### Supplied arguments
- `binary_url`: It is the `bin.dev.url` or `bin.rel.url`, the URL of the kext file
- `install_paths`: Where to install the kext, there can be many install paths (currently upto 12)

##### Exit code with output
The necessity of getting output from the script depends on it's exit (=return) code. There can be a slight
chance that you are installing more than one kext. If this is the case, you'll have to print all the kext locations
separated by a new line.

| Code | Output           | Meaning
| ---- | ---------------- | -------
| `0`  | Kext location(s) | The script has moved the kext to LE or SLE by all itself
| `1`  | Kext location(s) | The script has extracted the kext, but did not move it to LE or SLE
| `2`  | Optional Message | The attempt was not successful
 
**Kext location** is the location of the kext along with kext name.

#### Post installation script
Sometimes it is necessary to run post-installation script to move thing in their places or just to make sure everything
is fine.

```
USAGE: binary_file install_paths...
```

##### Supplied arguments
- `install_paths`: Where to install the kext, there can be many install paths (currently upto 12)

##### Exit code with output
The optional output should contain a friendly message.

| Code | Output           | Meaning
| ---- | ---------------- | -------
| `0`  | Optional Message | Everything's all right, let's proceed
| `1`  | Optional Message | Something's went wrong, let's give the user a hint
| `2`  | Optional Message | Something's went wrong, let's give the user a hint and also revert the kext installation

If some additional task have been taken using custom script during the installation, make sure to revert them in the
post-installation script if you're returning code `2`.

#### Notes on scripts
Currently, all the scripts will be run using admin privilege.
