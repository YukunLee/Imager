import UIKit

public protocol ImagerInfoLabelDelegate: class {
    
    func infoLabel(_ infoLabel: ImagerInfoLabel, didExpand expanded: Bool)
}

open class ImagerInfoLabel: UILabel {
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(labelDidTap(_:)))
        
        return gesture
        }()
    
    open var numberOfVisibleLines = 2
    
    var ellipsis: String {
        return "... \(ImagerConfiguration.ImagerInfoLabel.ellipsisText)"
    }
    
    open weak var delegate: ImagerInfoLabelDelegate?
    fileprivate var shortText = ""
    
    var fullText: String {
        didSet {
            shortText = truncatedText
            updateText(fullText)
            configureLayout()
        }
    }
    
    var expandable: Bool {
        return shortText != fullText
    }
    
    fileprivate(set) var expanded = false {
        didSet {
            delegate?.infoLabel(self, didExpand: expanded)
        }
    }
    
    fileprivate var truncatedText: String {
        var truncatedText = fullText
        
        guard numberOfLines(fullText) > numberOfVisibleLines else {
            return truncatedText
        }
        
        truncatedText += ellipsis
        
        let start = truncatedText.characters.index(truncatedText.endIndex, offsetBy: -(ellipsis.characters.count + 1))
        let end = truncatedText.characters.index(truncatedText.endIndex, offsetBy: -ellipsis.characters.count)
        var range = start..<end
        
        while numberOfLines(truncatedText) > numberOfVisibleLines {
            truncatedText.removeSubrange(range)
            range = truncatedText.index(range.lowerBound, offsetBy: -1)..<truncatedText.index(range.upperBound, offsetBy: -1)
        }
        
        return truncatedText
    }
    
    // MARK: - Initialization
    
    public init(text: String, expanded: Bool = false) {
        self.fullText = text
        super.init(frame: CGRect.zero)
        self.setup(text: text, expanded: expanded)
    }
    
    func setup(text: String, expanded: Bool = false) {
        numberOfLines = 0
        updateText(text)
        self.expanded = expanded
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.fullText = ""
        super.init(coder: aDecoder)
        self.setup(text: "", expanded: false)
    }
    
    // MARK: - Actions
    
    func labelDidTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        shortText = truncatedText
        expanded ? collapse() : expand()
    }
    
    func expand() {
        frame.size.height = heightForString(fullText)
        updateText(fullText)
        
        expanded = expandable
    }
    
    func collapse() {
        frame.size.height = heightForString(shortText)
        updateText(shortText)
        
        expanded = false
    }
    
    fileprivate func updateText(_ string: String) {
        let attributedString = NSMutableAttributedString(string: string,
                                                         attributes: ImagerConfiguration.ImagerInfoLabel.textAttributes)
        
        if string.range(of: ellipsis) != nil {
            let range = (string as NSString).range(of: ellipsis)
            attributedString.addAttribute(NSForegroundColorAttributeName,
                                          value: ImagerConfiguration.ImagerInfoLabel.ellipsisColor, range: range)
        }
        
        attributedText = attributedString
    }
    
    // MARK: - Helper methods
    
    fileprivate func heightForString(_ string: String) -> CGFloat {
        return string.boundingRect(
            with: CGSize(width: bounds.size.width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [NSFontAttributeName : font],
            context: nil).height
    }
    
    fileprivate func numberOfLines(_ string: String) -> Int {
        let lineHeight = "A".size(attributes: [NSFontAttributeName: font]).height
        let totalHeight = heightForString(string)
        
        return Int(totalHeight / lineHeight)
    }
}

// MARK: - ImagerLayoutConfigurable

extension ImagerInfoLabel: ImagerLayoutConfigurable {
    
    public func configureLayout() {
        shortText = truncatedText
        expanded ? expand() : collapse()
    }
}
