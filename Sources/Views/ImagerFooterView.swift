
import UIKit

public protocol ImagerFooterViewDelegate: class {
    
    func footerView(_ footerView: ImagerFooterView, didExpand expanded: Bool)
    func footerView(_ footerView: ImagerFooterView, didPressSaveButton saveButton: UIButton)
    
}

open class ImagerFooterView: UIView {
    
    open fileprivate(set) lazy var infoLabel: ImagerInfoLabel = { [unowned self] in
        let label = ImagerInfoLabel(text: "")
        label.isHidden = !ImagerConfiguration.ImagerInfoLabel.enabled
        
        label.textColor = ImagerConfiguration.ImagerInfoLabel.textColor
        label.isUserInteractionEnabled = true
        label.delegate = self
        
        return label
        }()
    
    open fileprivate(set) lazy var pageLabel: UILabel = { [unowned self] in
        let label = UILabel(frame: CGRect.zero)
        label.isHidden = !ImagerConfiguration.PageIndicator.enabled
        label.numberOfLines = 1
        
        return label
        }()
    
    open fileprivate(set) lazy var separatorView: UIView = { [unowned self] in
        let view = UILabel(frame: CGRect.zero)
        view.isHidden = !ImagerConfiguration.PageIndicator.enabled
        view.backgroundColor = ImagerConfiguration.PageIndicator.separatorColor
        
        return view
        }()
    
    let gradientColors = [UIColor(hex: "040404").alpha(0.1), UIColor(hex: "040404")]
    open weak var delegate: ImagerFooterViewDelegate?
    
    // MARK: - Initializers
    
    public init() {
        super.init(frame: CGRect.zero)
        self.setup()
    }
    open fileprivate(set) lazy var saveButton: UIButton = { [unowned self] in
        
        
        let button = UIButton(type: .custom)
        
        //        button.setAttributedTitle(title, for: UIControlState())
        button.addTarget(self, action: #selector(SaveButtonDidPress(_:)),
                         for: .touchUpInside)
        button.setImage(#imageLiteral(resourceName: "saveScanner"), for: .normal)
        
        return button
        }()
    
    func SaveButtonDidPress(_ button: UIButton) {
        delegate?.footerView(self, didPressSaveButton: button)
        
    }
    
    func setup() {
        backgroundColor = UIColor.clear
        addGradientLayer(gradientColors)
        [saveButton].forEach { addSubview($0) }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    // MARK: - Helpers
    
    func expand(_ expand: Bool) {
        expand ? infoLabel.expand() : infoLabel.collapse()
    }
    
    func updatePage(_ page: Int, _ numberOfPages: Int) {
        let text = "\(page)/\(numberOfPages)"
        
        pageLabel.attributedText = NSAttributedString(string: text,
                                                      attributes: ImagerConfiguration.PageIndicator.textAttributes)
        pageLabel.sizeToFit()
    }
    
    func updateText(_ text: String) {
        infoLabel.fullText = text
        
        if text.isEmpty {
            _ = removeGradientLayer()
        } else if !infoLabel.expanded {
            _ = addGradientLayer(gradientColors)
        }
    }
    
    // MARK: - Layout
    
    fileprivate func resetFrames() {
        frame.size.height = infoLabel.frame.height + 40 + 0.5
        
        pageLabel.frame.origin = CGPoint(
            x: (frame.width - pageLabel.frame.width) / 2,
            y: frame.height - pageLabel.frame.height - 2)
        
        separatorView.frame = CGRect(x: 0, y: pageLabel.frame.minY - 2.5,
                                     width: frame.width, height: 0.5)
        
        infoLabel.frame.origin.y = separatorView.frame.minY - infoLabel.frame.height - 15
        
        resizeGradientLayer()
    }
    
    
    
    
}

// MARK: - ImagerLayoutConfigurable

extension ImagerFooterView: ImagerLayoutConfigurable {
    
    public func configureLayout() {
        infoLabel.frame = CGRect(x: 17, y: 0, width: frame.width - 17 * 2, height: 35)
        infoLabel.configureLayout()
    }
}

extension ImagerFooterView: ImagerInfoLabelDelegate {
    
    public func infoLabel(_ infoLabel: ImagerInfoLabel, didExpand expanded: Bool) {
        resetFrames()
        _ = expanded ? removeGradientLayer() : addGradientLayer(gradientColors)
        delegate?.footerView(self, didExpand: expanded)
    }
}
