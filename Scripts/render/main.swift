import Foundation
import RealityKit
import ArgumentParser
import SFOMuseumLogger
import Progress

public enum RenderErrors: Error {
        case invalidDetail
        case photogrammetrySessionInitialization
}

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
    
    actor Bar {
       var progressBar = ProgressBar(count: 100)
       func setValue(_ value: Int) {
           progressBar.setValue(value)
       }
    }
         
    func run() throws {
        
        let log_label = "org.sfomuseum.render"
        
        let logger_opts = SFOMuseumLoggerOptions(
            label: log_label,
            console: true,
            logfile: logfile,
            verbose: verbose
        )
        
        let logger = try NewSFOMuseumLogger(logger_opts)
        
        let bar = Bar()
        
        var config = PhotogrammetrySession.Configuration()
        config.featureSensitivity = .normal
        config.isObjectMaskingEnabled = true
        config.sampleOrdering = .unordered
        
        let inputFolderURL = URL(fileURLWithPath: inputFolder,
                                 isDirectory: true)
        
        var optionalSession: PhotogrammetrySession? = nil
            
        do {
            optionalSession = try PhotogrammetrySession(
                input: inputFolderURL,
                configuration: config)
        } catch {
            logger.error("Failed to create session, \(error)")
            throw error
        }
        
        guard let session = optionalSession else {
            logger.error("Failed to initialize photogrammetry session")
            throw RenderErrors.photogrammetrySessionInitialization
        }
        
        let waiter = Task {
            do {
                for try await output in session.outputs {
                    switch output {
                    case .requestProgressInfo(_, _):
                        // print("PROGRESS INFO")
                        ()
                    case .stitchingIncomplete:
                        logger.warning("INCOMPLETE")
                    case .processingComplete:
                        logger.info("Processing is complete")
                        Foundation.exit(0)
                    case .requestError(let request, let error):
                        logger.error("Request \(String(describing: request)) had an error: \(String(describing: error))")
                    case .requestComplete(let request, let result):
                        logger.info("Request \(String(describing: request)) had a result: \(String(describing: result))")
                        
                    case .requestProgress(_, let fractionComplete):
                        await bar.setValue(Int(fractionComplete * 100))
                    case .inputComplete:
                        logger.info("Data ingestion is complete, beginning processing...")
                        
                    case .invalidSample(let id, let reason):
                        logger.error("Invalid Sample, id=\(id) reason=\"\(reason)\"")
                        
                    case .skippedSample(let id):
                        logger.debug("Sample id=\(id) was skipped by processing")
                        
                    case .automaticDownsampling:
                        logger.info("Automatic downsampling was applied")
                        
                    case .processingCancelled:
                        logger.info("Request of the session request was cancelled")
                        
                    @unknown default:
                        logger.warning("Unhandled output message: \(String(describing: output))")
                    }
                }
            } catch {
                logger.error("Failed to wait on task, \(error)")
                throw error
            }
        }
        
        try withExtendedLifetime((session, waiter)) {
            
            do {
                
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
                
                let request = PhotogrammetrySession.Request
                    .modelFile(url: URL(fileURLWithPath: outputFile),
                               detail: req_detail)
                
                try session.process(requests: [request])
                RunLoop.main.run()
            } catch {
                logger.error("Failed to process session, \(error)")
                throw error
            }

        }

    }
    
    
}

if #available(macOS 12.0, *) {
    Photogrammetry.main()
} else {
    fatalError("Requires macOS 12.0 or higher")
}
