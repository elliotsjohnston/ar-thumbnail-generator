# AR Thumbnail Generator

## Usage

To use `ar-thumbnail-generator`, pass in your 3D object file:
```shell
$ ar-thumbnail-generator /path/to/file
```

By default, the the thumbnail is generated as a `1024x1024` image. You can specify custom dimensions with the `--dimensions` flag:
```shell
$ ar-thumbnail-generator /path/to/file --dimensions 256,256
```
