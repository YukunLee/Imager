
import UIKit

protocol ImagerHeaderViewDelegate: class {
    func headerView(_ headerView: ImagerHeaderView, didPressDeleteButton deleteButton: UIButton)
    func headerView(_ headerView: ImagerHeaderView, didPressCloseButton closeButton: UIButton)
}

open class ImagerHeaderView: UIView {
    
    var centerTextStyle: NSMutableParagraphStyle = {
        var style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }()
    
    open fileprivate(set) lazy var closeButton: UIButton = { [unowned self] in
        let title = NSAttributedString(
            string: ImagerConfiguration.CloseButton.text,
            attributes: ImagerConfiguration.CloseButton.textAttributes)
        
        let button = UIButton(type: .system)
        
        button.frame.size = ImagerConfiguration.CloseButton.size
        button.setAttributedTitle(title, for: UIControlState())
        button.addTarget(self, action: #selector(closeButtonDidPress(_:)),
                         for: .touchUpInside)
        
        if let image = ImagerConfiguration.CloseButton.image {
            button.setBackgroundImage(image, for: UIControlState())
        }
        
        button.isHidden = !ImagerConfiguration.CloseButton.enabled
        
        return button
        }()
    
    open fileprivate(set) lazy var deleteButton: UIButton = { [unowned self] in
        let title = NSAttributedString(
            string: ImagerConfiguration.DeleteButton.text,
            attributes: ImagerConfiguration.DeleteButton.textAttributes)
        
        let button = UIButton(type: .system)
        
        button.frame.size = ImagerConfiguration.DeleteButton.size
        button.setAttributedTitle(title, for: .normal)
        button.addTarget(self, action: #selector(deleteButtonDidPress(_:)),
                         for: .touchUpInside)
        
        if let image = ImagerConfiguration.DeleteButton.image {
            button.setBackgroundImage(image, for: UIControlState())
        }
        
        button.isHidden = !ImagerConfiguration.DeleteButton.enabled
        
        return button
        }()
    
    weak var delegate: ImagerHeaderViewDelegate?
    
    // MARK: - Initializers
    
    public init() {
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    func setup() {
        backgroundColor = UIColor.clear
        [closeButton, deleteButton].forEach { addSubview($0) }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    // MARK: - Actions
    
    func deleteButtonDidPress(_ button: UIButton) {
        delegate?.headerView(self, didPressDeleteButton: button)
    }
    
    func closeButtonDidPress(_ button: UIButton) {
        delegate?.headerView(self, didPressCloseButton: button)
    }
}

// MARK: - ImagerLayoutConfigurable

extension ImagerHeaderView: ImagerLayoutConfigurable {
    
    public func configureLayout() {
        closeButton.frame.origin = CGPoint(
            x: bounds.width - closeButton.frame.width - 17, y: 0)
        
        deleteButton.frame.origin = CGPoint(x: 17, y: 0)
    }
}
