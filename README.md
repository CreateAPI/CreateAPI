<img width="80px" src="https://user-images.githubusercontent.com/1567433/146774765-4671c989-62c3-4418-8bdb-2773d7a26067.png">

# Create API

Delightful code generation for OpenAPI specs for Swift written in Swift.

- **Fast**: processes specs with 100K lines of YAML in less than a second
- **Smart**: generates Swift code that looks like it's carefully written by hand
- **Reliable**: tested on 1KK lines of publicly available OpenAPI specs producing correct code every time
- **Customizable**: offers a ton of customization options

> Powered by [OpenAPIKit](https://github.com/mattpolzin/OpenAPIKit)

## Installation

### [Mint](https://github.com/yonaskolb/Mint)

```bash
mint install CreateAPI/CreateAPI
```

Usage:

```bash
mint run CreateAPI create-api generate -h
```

### Make

```bash
git clone https://github.com/CreateAPI/CreateAPI.git
cd CreateAPI
make install
```

Usage:

```bash
create-api generate -h
```

## Usage

```
USAGE: create-api generate [<options>] <input>

ARGUMENTS:
  <input>                 The OpenAPI spec input file in either JSON or YAML format

OPTIONS:
  --output <output>       The output folder (default: ./.create-api/)
  --config <config>       The path to generator configuration. If not present, the command
                          will look for .create-api.yaml in the current directory.
                          (default: ./.create-api.yaml)
  -s, --split             Split output into separate files
  -v, --verbose           Print additional logging information
  --strict                Turns all warnings into errors
  -c, --clean             Removes the output folder before continuing
  --allow-errors          Ignore any errors that happen during code generation
  --watch                 Monitor changes to both the spec and the configuration file and
                          automatically re-generated input
  --package <package>     Generates a complete package with a given name
  --module <module>       Use the following name as a module name
  --vendor <vendor>       Enabled vendor-specific logic (supported values: "github")
  --generate <generate>   Specifies what to generate (default: paths, entities)
  --filename-template <filename-template>
                          Example: "%0.generated.swift" will produce files with the
                          following names: "Paths.generated.swift". (default: %0.swift)
  --entityname-template <entityname-template>
                          Example: "%0Generated" will produce entities with the following
                          names: "EntityGenerated". (default: %0)
  --single-threaded       By default, saturates all available threads. Pass this option to
                          turn all parallelization off.
  --measure               Measure performance of individual operations
  -h, --help              Show help information.
```

## Documentation

- [Configuration](./Docs/ConfigOptions.md)

## OpenAPI Support

The goal is to completely cover OpenAPI 3.x spec.

Currently, the following features are **not** supported:

- External References

Some discrepancies with the OpenAPI spec are by design:

- `allowReserved` keyword in parameters is ignored and all parameter values are percent-encoded
- `allowEmptyValue` keyword in parameters is ignored as it's not recommended to be used

Upcoming:

- An improved way to generate patch parameters. Support for [JSON Patch](http://jsonpatch.com).
- OpenAPI 3.1 support.

