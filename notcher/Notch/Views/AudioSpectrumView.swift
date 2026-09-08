//
//  AudioSpectrumView.swift
//  notcher
//

import AppKit
import SwiftUI

final class AudioSpectrum: NSView {
    private var barLayers: [CAShapeLayer] = []
    private var barScales: [CGFloat] = []
    private var isPlaying: Bool = false
    private var animationTimer: Timer?
    var barColor: NSColor = .white {
        didSet {
            for bar in barLayers {
                bar.fillColor = barColor.cgColor
            }
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBars()
    }

    private func setupBars() {
        let barWidth: CGFloat = 2.5
        let barCount = 4
        let spacing: CGFloat = 2
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
        let totalHeight: CGFloat = 13
        frame.size = CGSize(width: totalWidth, height: totalHeight)

        for i in 0 ..< barCount {
            let xPosition = CGFloat(i) * (barWidth + spacing)
            let barLayer = CAShapeLayer()
            barLayer.frame = CGRect(x: xPosition, y: 0, width: barWidth, height: totalHeight)
            barLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            barLayer.position = CGPoint(x: xPosition + barWidth / 2, y: totalHeight / 2)
            barLayer.fillColor = barColor.cgColor
            barLayer.masksToBounds = true
            let path = NSBezierPath(roundedRect: CGRect(x: 0, y: 0, width: barWidth, height: totalHeight),
                                    xRadius: barWidth / 2,
                                    yRadius: barWidth / 2)
            barLayer.path = path.cgPath
            barLayers.append(barLayer)
            barScales.append(0.35)
            layer?.addSublayer(barLayer)
        }
    }
    
    func setPlaying(_ playing: Bool) {
        guard isPlaying != playing else { return }
        isPlaying = playing
        if isPlaying {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
    
    private func startAnimating() {
        guard animationTimer == nil else { return }
        updateBars()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateBars()
        }
    }
    
    private func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
        resetBars()
    }
    
    private func updateBars() {
        guard isPlaying else { return }
        for (i, barLayer) in barLayers.enumerated() {
            let currentScale = barScales[i]
            let targetScale = CGFloat.random(in: 0.3 ... 1.0)
            barScales[i] = targetScale
            
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = currentScale
            animation.toValue = targetScale
            animation.duration = 0.25
            animation.autoreverses = true
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            barLayer.add(animation, forKey: "scaleY")
        }
    }
    
    private func resetBars() {
        for (i, barLayer) in barLayers.enumerated() {
            barLayer.removeAllAnimations()
            barLayer.transform = CATransform3DMakeScale(1, 0.25, 1)
            barScales[i] = 0.25
        }
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}

struct AudioSpectrumView: NSViewRepresentable {
    var isPlaying: Bool
    var color: Color = .white
    
    func makeNSView(context: Context) -> AudioSpectrum {
        let spectrum = AudioSpectrum()
        spectrum.barColor = NSColor(color)
        spectrum.setPlaying(isPlaying)
        return spectrum
    }
    
    func updateNSView(_ nsView: AudioSpectrum, context: Context) {
        nsView.barColor = NSColor(color)
        nsView.setPlaying(isPlaying)
    }
}
