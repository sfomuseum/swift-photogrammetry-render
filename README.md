# swift-image-emboss

An opinionated Swift package for basic `PhotogrammetrySession` operations to derive 3D models from photographs

## Documentation

Documentation is incomplete at this time.

## Example

```
import RealityKit
import Logging
import PhotogrammetryRenderer

var logger: Logger
var detail: PhotogrammetrySession.Request.Detail

let r = PhotogrammetryRenderer(
	inputFolder: "/path/to/images/folder",
	outputFile: "/path/to/3dmodel.usdz",
	detail: detail,
	logger: logger
)
        
r.Render(
    onprogress: { (fractionComplete) in
        // print fractionComplete here or adjust to taste 
    },
    oncomplete: { (result) in            
        if case let .success(modelUrl) = result {
                print(modelUrl)
        } else if case let .failure(error) = result {
                logger.error("Failed to process model, \(error)")
        }
    }
)
```

## Tools

### render

```
$> swift build

$> ./.build/debug/render -h
USAGE: photogrammetry <input-folder> <output-file> [--logfile <logfile>] [--verbose <verbose>] [--detail <detail>]

ARGUMENTS:
  <input-folder>          The path to the folder containing images used to derive 3D model
  <output-file>           The path (and filename) of the 3D model to create

OPTIONS:
  --logfile <logfile>     Log events to system log files (default: false)
  --verbose <verbose>     Enable verbose logging (default: false)
  --detail <detail>       The level of detail to use when creating the 3D model. Valid options are: preview, reduced, medium, full, raw. (default: medium)
  -h, --help              Show help information.
```

## Requirements

This requires MacOS 12.0, iOS 17.0 or higher.

## See also

