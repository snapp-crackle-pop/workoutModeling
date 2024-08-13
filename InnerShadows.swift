import UIKit

import SwiftUI

struct InnerShadowRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> InnerShadowView {
        let view = InnerShadowView()
        return view
    }

    func updateUIView(_ uiView: InnerShadowView, context: Context) {
        // Update the view as needed
    }
}


class InnerShadowView: UIView {
    private var shadowLayer: CALayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        drawShadow()
    }

    private func drawShadow() {
        if shadowLayer == nil {
            let size = self.frame.size
            self.clipsToBounds = true
            let layer = CALayer()
            layer.backgroundColor = UIColor.lightGray.cgColor
            layer.position = CGPoint(x: size.width / 2, y: size.height / 2)
            layer.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            layer.shadowColor = UIColor.darkGray.cgColor
            layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
            layer.shadowOpacity = 0.8
            layer.shadowRadius = 5.0
            layer.cornerRadius = 25 // Match the corner radius of your RoundedRectangle

            self.shadowLayer = layer
            self.layer.addSublayer(layer)
        }
    }
}
