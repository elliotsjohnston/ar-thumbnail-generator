//
//  main.swift
//  ar-thumbnail-generator
//
//  Created by Elliot Johnston on 2/24/23.
//

import ArgumentParser
import QuickLookThumbnailing
import UniformTypeIdentifiers
import ImageIO

@main
struct CreateThumbnail: AsyncParsableCommand {
    @Argument(help: "The AR file to process.",
              completion: .file(),
              transform: URL.init(fileURLWithPath:))
    var inputFile: URL

    @Option(help: "The dimensions to use for the thumbnail image.",
            transform: { $0.components(separatedBy: ",").compactMap(Double.init(_:)) })
    var dimensions: [Double] = [1024, 1024]

    @Option(name: .shortAndLong,
            help: "Write thumbnail output to this file.",
            completion: .file(),
            transform: URL.init(fileURLWithPath:))
    var outputFile: URL? = nil

    @Option(name: .customLong("quality"),
            help: "The thumbnail quality to use.")
    var thumbnailQuality: ThumbnailQuality = .normal

    enum ThumbnailQuality: String, ExpressibleByArgument {
        case normal
        case low

        var representationTypes: QLThumbnailGenerator.Request.RepresentationTypes {
            switch self {
            case .normal:
                return .thumbnail
            case .low:
                return .lowQualityThumbnail
            }
        }
    }

    mutating func run() async throws {
        let thumbnailSize = CGSize(width: dimensions[0], height: dimensions[1])
        let request = QLThumbnailGenerator.Request(fileAt: inputFile,
                                                   size: thumbnailSize,
                                                   scale: 1.0,
                                                   representationTypes: thumbnailQuality.representationTypes)

        let thumbnailRepresentation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
        let outputFile = outputFile ?? inputFile
            .deletingPathExtension()
            .appendingPathExtension(UTType.jpeg.preferredFilenameExtension!)

        let thumbnailCreationError = ValidationError("An error occurred while saving the thumbnail image.")

        guard let destination = CGImageDestinationCreateWithURL(outputFile as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw thumbnailCreationError
        }

        CGImageDestinationAddImage(destination, thumbnailRepresentation.cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw thumbnailCreationError
        }
    }

    func validate() throws {
        let unsupportedInputError = ValidationError("The provided input file is not supported.")
        guard let inputFiletype = try inputFile.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            throw unsupportedInputError
        }

        guard inputFiletype.isSubtype(of: .threeDContent) || inputFiletype == .realityFile else {
            throw unsupportedInputError
        }

        guard dimensions.count == 2, dimensions[0] > 0.0, dimensions[1] > 0.0 else {
            throw ValidationError("The --dimensions flag expects exactly 2 numeric values.")
        }
    }
}
