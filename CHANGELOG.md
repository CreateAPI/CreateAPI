# CreateAPI 0.x

## 0.0.4

### June 10, 2022

* Discriminator Support by @PhilipTrauner in [#10](https://github.com/CreateAPI/CreateAPI/pull/10)
* Strip parent name of enum cases within nested objects by @PhilipTrauner in [#15](https://github.com/CreateAPI/CreateAPI/pull/15)
* Added options for mutable properties in classes and structs by @JanC in [#17](https://github.com/CreateAPI/CreateAPI/pull/17)
* Add entities name template by @imjn in [#14](https://github.com/CreateAPI/CreateAPI/pull/14)
* Added imports option for entities by @JanC in [#19](https://github.com/CreateAPI/CreateAPI/pull/19)
* Fix shouldGenerate check for entities.include option by @ainame in [#10](https://github.com/CreateAPI/CreateAPI/pull/20)
* Fix namespace when using operations style by @simorgh3196 in [#21](https://github.com/CreateAPI/CreateAPI/pull/21)
* Fix `String` type with `byte` format by @mattia in [#25](https://github.com/CreateAPI/CreateAPI/pull/25)
* Fixed fileHeader option to fileHeaderComment by @imjn in [#22](https://github.com/CreateAPI/CreateAPI/pull/22)
* Fixed test failures for string with byte format by @imjn in [#26](https://github.com/CreateAPI/CreateAPI/pull/26)
* Fix test failures in comparing Package.swift by @imjn in [#28](https://github.com/CreateAPI/CreateAPI/pull/28)
* Update repository links to github.com/CreateAPI/CreateAPI by @liamnichols in [#35](https://github.com/CreateAPI/CreateAPI/pull/35)
* Support multiple discriminator mappings to share one type by @imjn in [#36](https://github.com/CreateAPI/CreateAPI/pull/36)
* Update GitHub Workflow CI by @liamnichols in [#37](https://github.com/CreateAPI/CreateAPI/pull/37)
* Fix allOf decoding issue by @imjn in [#27](https://github.com/CreateAPI/CreateAPI/pull/27)
* Removed redundant space before struct and class declaration by @imjn in [#38](https://github.com/CreateAPI/CreateAPI/pull/38)
* Decode JSON input specs using `YAMLDecoder` by @liamnichols in [#34](https://github.com/CreateAPI/CreateAPI/pull/34)
* Treat single element allOf/oneOf/anyOf schemas as the nested schema by @liamnichols in [#39](https://github.com/CreateAPI/CreateAPI/pull/39)

**Full Changelog**: https://github.com/CreateAPI/CreateAPI/compare/0.0.2...0.0.4

## 0.0.2

### Jan 29, 2022

* Add support for installation by Mint by @simorgh3196 in [#1](https://github.com/CreateAPI/CreateAPI/pull/1)
* Fixed small typos in README.md by @imjn in [#2](https://github.com/CreateAPI/CreateAPI/pull/2)
* Fixed wrong example in readme yaml by @imjn in [#4](https://github.com/CreateAPI/CreateAPI/pull/4)
* Add Entities.include by @imjn in [#5](https://github.com/CreateAPI/CreateAPI/pull/5)
* Revert "Added entityPrefix and entitySuffix to GenerateOptions.Rename" by @imjn in [#8](https://github.com/CreateAPI/CreateAPI/pull/8)
* Added --clean to readme by @imjn in [#7](https://github.com/CreateAPI/CreateAPI/pull/7)
* Use builtin `UUID` type for `uuid` format in schemas by @PhilipTrauner in [#11](https://github.com/CreateAPI/CreateAPI/pull/11)
* Fix tests by @PhilipTrauner in [#13](https://github.com/CreateAPI/CreateAPI/pull/13)


**Full Changelog**: https://github.com/CreateAPI/CreateAPI/compare/0.0.1...0.0.2

## 0.0.1

### Jan 3, 2022

Initial pre-release
