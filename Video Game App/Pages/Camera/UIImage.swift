//
//  UIImage.swift
//  Video Game App
//
//  Created by Mike K on 8/21/25.
//

import UIKit

extension UIImage {
    // 1) Strip EXIF orientation by redrawing pixels upright.
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out ?? self
    }

    // 2a) Center-crop to a target aspect (e.g., 3:4 portrait)
    func centerCropped(toAspect targetAspect: CGFloat) -> UIImage {
        let w = size.width, h = size.height
        let currentAspect = w / h
        var cropRect: CGRect
        if currentAspect > targetAspect {
            // too wide -> crop width
            let newW = h * targetAspect
            cropRect = CGRect(x: (w - newW)/2, y: 0, width: newW, height: h)
        } else {
            // too tall -> crop height
            let newH = w / targetAspect
            cropRect = CGRect(x: 0, y: (h - newH)/2, width: w, height: newH)
        }
        guard let cg = cgImage?.cropping(to: CGRect(
            x: cropRect.origin.x * scale,
            y: cropRect.origin.y * scale,
            width: cropRect.size.width * scale,
            height: cropRect.size.height * scale
        )) else { return self }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }

    // 2b) (optional) Resize to a friendly pixel size (helps consistency)
    func resized(maxLongSide: CGFloat) -> UIImage {
        let w = size.width, h = size.height
        let scaleFactor = maxLongSide / max(w, h)
        if scaleFactor >= 1 { return self }
        let newSize = CGSize(width: w * scaleFactor, height: h * scaleFactor)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out ?? self
    }
}
