//
//  ShareVideoExporter.swift
//  DontGoMart
//
//  공유 카드를 짧은 세로/4:5 동영상(MP4, H.264, 30fps)으로 만든다.
//  카드가 차례로 나타나는 애니메이션 4초 + 완성 화면 3초 정지.
//  인스타 릴스·스토리, 카카오톡 등에 그대로 올릴 수 있다.
//

import AVFoundation
import SwiftUI
import UIKit

enum ShareVideoExporter {
    static let fps: Int32 = 30
    static let animationDuration: Double = 4
    static let duration: Double = 7
    /// 포인트 → 픽셀 배율 (360pt → 1080px)
    static let scale: CGFloat = 3

    enum ExportError: Error { case setup, render, write }

    @MainActor
    static func renderImage(payload: ShareCardPayload, format: ShareFormat, progress: Double) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(payload: payload, format: format, progress: progress))
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    @MainActor
    static func export(payload: ShareCardPayload, format: ShareFormat,
                       onProgress: @escaping (Double) -> Void) async throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DontGoMart-\(format.rawValue)-\(UUID().uuidString.prefix(8)).mp4")
        let width = Int(format.size.width * scale)
        let height = Int(format.size.height * scale)

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 6_000_000],
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ])
        guard writer.canAdd(input) else { throw ExportError.setup }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? ExportError.setup }
        writer.startSession(atSourceTime: .zero)

        let totalFrames = Int(duration * Double(fps))
        var lastImage: CGImage?
        for frame in 0..<totalFrames {
            try Task.checkCancellation()
            let progress = min(Double(frame) / Double(fps) / animationDuration, 1)

            // 애니메이션이 끝난 뒤는 같은 그림 — 다시 그리지 않는다.
            if progress < 1 || lastImage == nil {
                guard let image = renderImage(payload: payload, format: format, progress: progress)?.cgImage else {
                    throw ExportError.render
                }
                lastImage = image
            }
            guard let image = lastImage, let buffer = pixelBuffer(from: image, pool: adaptor.pixelBufferPool,
                                                                 width: width, height: height) else {
                throw ExportError.render
            }
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(5))
            }
            guard adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: fps)) else {
                throw writer.error ?? ExportError.write
            }
            onProgress(Double(frame + 1) / Double(totalFrames))
            // 화면(진행 막대)이 멈추지 않도록 틈틈이 양보
            if frame % 3 == 0 { await Task.yield() }
        }

        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? ExportError.write }
        return url
    }

    private static func pixelBuffer(from image: CGImage, pool: CVPixelBufferPool?, width: Int, height: Int) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        if let pool {
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        } else {
            CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &buffer)
        }
        guard let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                      width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                                          | CGBitmapInfo.byteOrder32Little.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}
