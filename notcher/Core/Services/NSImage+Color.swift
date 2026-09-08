//
//  NSImage+Color.swift
//  notcher
//

import AppKit
import SwiftUI

extension NSImage {
    public func extractAverageColor() -> NSColor? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let width = 32
        let height = 32
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &rawData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
              ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var rTotal: UInt64 = 0
        var gTotal: UInt64 = 0
        var bTotal: UInt64 = 0
        let totalPixels = width * height
        
        for i in 0..<totalPixels {
            let offset = i * bytesPerPixel
            rTotal += UInt64(rawData[offset])
            gTotal += UInt64(rawData[offset + 1])
            bTotal += UInt64(rawData[offset + 2])
        }
        
        let avgR = CGFloat(rTotal) / CGFloat(totalPixels) / 255.0
        let avgG = CGFloat(gTotal) / CGFloat(totalPixels) / 255.0
        let avgB = CGFloat(bTotal) / CGFloat(totalPixels) / 255.0
        
        var color = NSColor(red: avgR, green: avgG, blue: avgB, alpha: 1.0)
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        
        // Ensure vibrant presentation against black notch
        let finalSat = max(0.55, min(1.0, sat * 1.3))
        let finalBri = max(0.70, min(1.0, bri * 1.2))
        return NSColor(hue: hue, saturation: finalSat, brightness: finalBri, alpha: 1.0)
    }
}
