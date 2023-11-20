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

## Requirements

This requires MacOS 12.0, iOS 17.0 or higher.

## See also

* https://developer.apple.com/documentation/realitykit/photogrammetrysession
* https://github.com/sfomuseum/swift-photogrammetry-render-cli