//
//  Fastfile.swift
//  FastlaneRunner
//
//  Created by Vyacheslav Khorkov on 10/05/2019.
//

import Cocoa

class Fastfile: LaneFile {
	
    func imgDiffLane(withOptions options: [String: String]?) {
        desc("🚦 Compares two images and prints max pixel difference.")
        
        guard let sourcePath = options?["one"] else {
            logError("Need to pass an image path as argument one.")
            return
        }
        
        guard let targetPath = options?["two"] else {
            logError("Need to pass an image path as argument two.")
            return
        }
		
        let sourceURL = URL(fileURLWithPath: sourcePath)
        guard let sourceImage = NSImage(contentsOf: sourceURL) else {
            logError("Can't create an image from passed argument one.")
            return
        }
        
        let targetURL = URL(fileURLWithPath: targetPath)
        guard let targetImage = NSImage(contentsOf: targetURL) else {
            logError("Can't create an image from passed argument two.")
            return
        }
        
        do {
            let maxPixelDifference = try sourceImage.compare(targetImage)
            echo(message: "🚦 Max pixel difference: \(maxPixelDifference)")
        } catch {
            logError(error.localizedDescription)
        }
	}
}


// MARK: - Extensions

private func logError(_ error: Error) {
    logError(error.localizedDescription)
}

private func logError(_ message: String) {
    echo(message: "⚠️　\(message)")
}

extension NSImage {
    
    private enum CompareError: Error, LocalizedError {
        case differentSize(CGSize, CGSize)
        case bitmapRepresentation(label: String)
        case CGImage(label: String)
        case context(label: String)
        case bitmapData(label: String)
        case colorSpace(name: String)
        
        var errorDescription: String? {
            switch self {
            case let .differentSize(one, two):
                return "Images have different size: \(one) and \(two)."
            
            case let .bitmapRepresentation(label):
                return "Can't get NSBitmapImageRep for a \(label) image."
                
            case let .CGImage(label):
                return "Can't get CGImage from bitmap representation for a \(label) image."
                
            case let .context(label):
                return "Can't create context for a \(label) image."
                
            case let .bitmapData(label):
                return "Can't get bitmapData from context for a \(label) image."
                
            case let .colorSpace(name):
                return "Can't create \(name) color space."
            }
        }
    }
    
    fileprivate func compare(_ target: NSImage) throws -> CGFloat {
        guard size.equalTo(target.size) else {
            throw CompareError.differentSize(size, target.size)
        }
        
        let imageLabels = (first: "first", second: "second")
        
        // Get NSBitmapImageReps
        guard let representation = representations.first as? NSBitmapImageRep else {
            throw CompareError.bitmapRepresentation(label: imageLabels.first)
        }
        
        guard let targetRepresentation = target.representations.first as? NSBitmapImageRep else {
            throw CompareError.bitmapRepresentation(label: imageLabels.second)
        }
        
        // Get CGImages
        guard let sourceCGImage = representation.cgImage else {
            throw CompareError.CGImage(label: imageLabels.first)
        }
        
        guard let targetCGImage = targetRepresentation.cgImage else {
            throw CompareError.CGImage(label: imageLabels.second)
        }
        
        guard let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw CompareError.colorSpace(name: "sRGB")
        }
        
        // Create bitmap contexts
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let sourceContext = CGContext(data: nil,
                                            width: sourceCGImage.width,
                                            height: sourceCGImage.height,
                                            bitsPerComponent: sourceCGImage.bitsPerComponent,
                                            bytesPerRow: sourceCGImage.bytesPerRow,
                                            space: sRGBColorSpace,
                                            bitmapInfo: bitmapInfo)
        else {
            throw CompareError.context(label: imageLabels.first)
        }
        
        guard let targetContext = CGContext(data: nil,
                                            width: targetCGImage.width,
                                            height: targetCGImage.height,
                                            bitsPerComponent: targetCGImage.bitsPerComponent,
                                            bytesPerRow: targetCGImage.bytesPerRow,
                                            space: sRGBColorSpace,
                                            bitmapInfo: bitmapInfo)
        else {
            throw CompareError.context(label: imageLabels.second)
        }
        
        // Get BitmapData
        guard let sourceBitmapData = sourceContext.data else {
            throw CompareError.bitmapData(label: imageLabels.first)
        }
        
        guard let targetBitmapData = targetContext.data else {
            throw CompareError.bitmapData(label: imageLabels.second)
        }
        
        // Draw images in contexts
        let drawRect = CGRect(origin: .zero, size: CGSize(width: sourceCGImage.width,
                                                          height: sourceCGImage.height))
        sourceContext.draw(sourceCGImage, in: drawRect)
        targetContext.draw(targetCGImage, in: drawRect)
        
        // Get pixels data
        let capacity = sourceCGImage.width * sourceCGImage.height
        var sourcePixels = sourceBitmapData.bindMemory(to: UInt8.self, capacity: capacity)
        var targetPixels = targetBitmapData.bindMemory(to: UInt8.self, capacity: capacity)
        
        // Compare pixel by pixel
        var maxPixelDifference: CGFloat = 0.0
        for _ in 0..<representation.pixelsHigh {
            for _ in 0..<representation.pixelsWide {
                let components = sourcePixels.colorComponents
                let targetComponents = targetPixels.colorComponents
                
                let redDiff = abs(components.red - targetComponents.red)
                let greenDiff = abs(components.green - targetComponents.green)
                let blueDiff = abs(components.blue - targetComponents.blue)
                let alphaDiff = abs(components.alpha - targetComponents.alpha)
                
                let maxDiff = max(redDiff, greenDiff, blueDiff, alphaDiff)
                maxPixelDifference = max(maxPixelDifference, maxDiff)
                
                sourcePixels = sourcePixels.advanced(by: 4)
                targetPixels = targetPixels.advanced(by: 4)
            }
        }
        
        return maxPixelDifference
    }
}

extension UnsafeMutablePointer where Pointee == UInt8 {
    
    fileprivate var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var bitmapData = self
        let max = CGFloat(UInt8.max)
        let red = CGFloat(bitmapData.pointee) / max
        bitmapData = bitmapData.successor()
        let green = CGFloat(bitmapData.pointee) / max
        bitmapData = bitmapData.successor()
        let blue = CGFloat(bitmapData.pointee) / max
        bitmapData = bitmapData.successor()
        let alpha = CGFloat(bitmapData.pointee) / max
        bitmapData = bitmapData.successor()
        return (CGFloat(red), CGFloat(green), CGFloat(blue), CGFloat(alpha))
    }
}
