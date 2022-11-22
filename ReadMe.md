# TCC Tool
version 2.8, 15 November 2022

_Note: Terminal.app or the process running this script will need Full Disk Access_

## What does it do?
Reads the system and user tcc.db and translates the following:
- service name
- client name
- `auth_value` (allowed, denied)
- `auth_reason` (user, system default, MDM)
- `indirect_object_identifier`
- last modified date

Outputs the report in CSV

## Usage
`zsh tcctool.sh [-o outputfile]` 

If an output file path is not specified, the report text is sent to stdout.

## See also:
[https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive](https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive)

## To Do
- List of apps present in TCC.db that are no longer installed.
- Offer to clean missing apps from TCC.db with tccutil
