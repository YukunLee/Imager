
import UIKit

public let ImagerLoadingIndicatorFrame = CGRect(x: 0, y: 0, width: 60, height: 60)

open class ImagerLoadingIndicator: UIView {
    
    var indicator: UIActivityIndicatorView!
    
    init() {
        super.init(frame: ImagerLoadingIndicatorFrame)
        self.setup()
    }
    
    func setup() {
        backgroundColor = UIColor.darkGray
        layer.cornerRadius = bounds.size.width / 2
        clipsToBounds = true
        alpha = 0
        
        indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.startAnimating()
        
        addSubview(indicator)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame = ImagerLoadingIndicatorFrame
        self.setup()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        indicator.center = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
    }
}
