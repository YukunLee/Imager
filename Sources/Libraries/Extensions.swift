
import UIKit

extension UIView {
    
    @discardableResult public func addGradientLayer(_ colors: [UIColor]) -> CAGradientLayer {
        if let gradientLayer = gradientLayer { return gradientLayer }
        
        let gradient = CAGradientLayer()
        
        gradient.frame = bounds
        gradient.colors = colors.map { $0.cgColor }
        layer.insertSublayer(gradient, at: 0)
        
        return gradient
    }
    
    @discardableResult public func removeGradientLayer() -> CAGradientLayer? {
        gradientLayer?.removeFromSuperlayer()
        
        return gradientLayer
    }
    
    public func resizeGradientLayer() {
        gradientLayer?.frame = bounds
    }
    
    fileprivate var gradientLayer: CAGradientLayer? {
        return layer.sublayers?.first as? CAGradientLayer
    }
}

public extension UIImage {
    static func image(named: String) -> UIImage? {
        let bundle = Bundle(for: ImagerController.self)
        return UIImage(named: "Imager.bundle/\(named)", in: bundle, compatibleWith: nil)
    }
}
