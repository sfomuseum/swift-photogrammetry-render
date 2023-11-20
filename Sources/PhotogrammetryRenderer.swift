import Logging
import RealityKit
import Foundation

public enum RenderErrors: Error {
    case invalidDetail
    case photogrammetrySessionInitialization
    case invalidSample
}

@available(macOS 12.0, iOS 17.0, *)
public class PhotogrammetryRenderer {
    
    var inputFolderUrl: URL
    var outputFileUrl: URL
    var detail: PhotogrammetrySession.Request.Detail
    var logger: Logger
    
    public init(inputFolder: URL, outputFile: URL, detail: PhotogrammetrySession.Request.Detail, logger: Logger) {
        
        self.inputFolderUrl = inputFolder
        self.outputFileUrl = outputFile
        self.detail = detail
        self.logger = logger
    }
    
    public func Render(onprogress: @escaping (_ fractionComplete: Double) async -> (), oncomplete: @escaping (_ result: Result<URL, Error>) -> ()) {
        
        var config = PhotogrammetrySession.Configuration()
        config.featureSensitivity = .normal
        config.isObjectMaskingEnabled = true
        config.sampleOrdering = .unordered
        
        var optionalSession: PhotogrammetrySession? = nil
        
        do {
            optionalSession = try PhotogrammetrySession(
                input: self.inputFolderUrl,
                configuration: config)
        } catch {
            self.logger.error("Failed to create session, \(error)")
            completion(.failure(error))
            return
        }
        
        guard let session = optionalSession else {
            logger.error("Failed to initialize photogrammetry session")
            completion(.failure(RenderErrors.photogrammetrySessionInitialization))
            return
        }
        
        let waiter = Task {
            do {
                for try await output in session.outputs {
                    switch output {
                    case .requestProgressInfo:
                        // print("PROGRESS INFO")
                        ()
                    case .stitchingIncomplete:
                        self.logger.warning("Incomplete stitching")
                    case .processingComplete:
                        self.logger.info("Processing is complete")
                        completion(.success(outputFileUrl))
                        break
                    case .requestError(let request, let error):
                        logger.error("Request \(String(describing: request)) had an error: \(String(describing: error))")
                        completion(.failure(error))
                        break
                    case .requestComplete(let request, let result):
                        logger.info("Request \(String(describing: request)) had a result: \(String(describing: result))")
                        
                    case .requestProgress(_, let fractionComplete):
                        await onprogress(fractionComplete)
                    case .inputComplete:
                        logger.info("Data ingestion is complete, beginning processing...")
                    case .invalidSample(let id, let reason):
                        logger.error("Invalid Sample, id=\(id) reason=\"\(reason)\"")
                        completion(.failure(RenderErrors.invalidSample))
                        break
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
                completion(.failure(error))
            }
        }
        
        withExtendedLifetime((session, waiter)) {
            
            do {
                
                
                let request = PhotogrammetrySession.Request.modelFile(
                    url: self.outputFileUrl,
                    detail: self.detail
                )
                
                try session.process(requests: [request])
                
            } catch {
                logger.error("Failed to process session, \(error)")
                completion(.failure(error))
            }
            
        }
    }
}
