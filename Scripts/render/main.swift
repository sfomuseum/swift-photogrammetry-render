import Foundation
import RealityKit
import ArgumentParser
import SFOMuseumLogger
import PhotogrammetryRenderer

@available(macOS 12.0, *)
struct Photogrammetry: ParsableCommand {
    
    @Argument(help:"The path to a source image file to extract image subjects from.")
    var inputFolder: String
    
    @Argument(help:"...")
    var outputFile: String
    
    @Option(help: "Log events to system log files")
    var logfile: Bool = false
    
    @Option(help: "Enable verbose logging")
    var verbose: Bool = false
    
    @Option(help: "...")
    var detail: String = "medium"
    
    func run() throws {
        
        let log_label = "org.sfomuseum.render"
        
        let logger_opts = SFOMuseumLoggerOptions(
            label: log_label,
            console: true,
            logfile: logfile,
            verbose: verbose
        )
        
        let logger = try NewSFOMuseumLogger(logger_opts)
        
        var req_detail: PhotogrammetrySession.Request.Detail
        
        switch detail {
        case "preview":
            req_detail = .preview
        case "reduced":
            req_detail = .reduced
        case "medium":
            req_detail = .medium
        case "full":
            req_detail = .full
        case "raw":
            req_detail = .raw
        default:
            throw RenderErrors.invalidDetail
        }
        
        let inputFolderURL = URL(fileURLWithPath: inputFolder,
                                 isDirectory: true)
        
        let outputFileURL = URL(fileURLWithPath: outputFile)
        
        let r = PhotogrammetryRenderer(
            inputFolder: inputFolderURL,
            outputFile: outputFileURL,
            detail: req_detail,
            logger: logger
        )
        
        r.Render(completion: { (result) in
            
            if case let .success(modelUrl) = result {
                print(modelUrl)
                Foundation.exit(0)
            } else if case let .failure(error) = result {
                logger.error("Failed to process model, \(error)")
                Foundation.exit(1)
            }
        })
        
        RunLoop.main.run()
    }
}

if #available(macOS 12.0, *) {
    Photogrammetry.main()
} else {
    fatalError("Requires macOS 12.0 or higher")
}
