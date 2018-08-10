
import UIKit
import Hue

public protocol ImagerDelegate: class {
    func imagerController(_ controller: ImagerController, didMoveTo page: Int)
    func imagerController(_ controller: ImagerController, didLongPressedAt page: Int)
    func imagerControllerWillDismiss(_ controller: ImagerController)
    func imagerControllerShowReslut(_ controller: ImagerController, _ isLoad: Bool)
    
}

open class ImagerController: UIViewController {
    
    // MARK: - Internal views
    
    lazy var scrollView: UIScrollView = { [unowned self] in
        let scrollView = UIScrollView()
        scrollView.frame = self.screenBounds
        scrollView.isPagingEnabled = false
        scrollView.delegate = self
        scrollView.isUserInteractionEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        
        return scrollView
        }()
    
    lazy var overlayTapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.cancelsTouchesInView = false
        gesture.addTarget(self, action: #selector(overlayViewDidTap(_:)))
        
        return gesture
        }()
    
    lazy var effectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }()
    
    lazy var backgroundView: UIImageView = {
        let view = UIImageView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }()
    
    // MARK: - Public views
    
    open fileprivate(set) lazy var headerView: ImagerHeaderView = { [unowned self] in
        let view = ImagerHeaderView()
        view.delegate = self
        
        return view
        }()
    
    open fileprivate(set) lazy var footerView: ImagerFooterView = { [unowned self] in
        let view = ImagerFooterView()
        view.delegate = self
        
        return view
        }()
    
    open fileprivate(set) lazy var overlayView: UIView = { [unowned self] in
        let view = UIView(frame: CGRect.zero)
        let gradient = CAGradientLayer()
        let colors = [UIColor(hex: "090909").alpha(0), UIColor(hex: "040404")]
        
        _ = view.addGradientLayer(colors)
        view.alpha = 0
        
        return view
        }()
    
    var screenBounds: CGRect {
        return self.view.bounds//UIScreen.main.bounds
    }
    
    // MARK: - Properties
    
    open fileprivate(set) var currentPage = 0 {
        didSet {
            currentPage = min(numberOfPages - 1, max(0, currentPage))
            footerView.updatePage(currentPage + 1, numberOfPages)
            footerView.updateText(pageViews[currentPage].image.text)
            
            if currentPage == numberOfPages - 1 {
                seen = true
            }
            
            delegate?.imagerController(self, didMoveTo: currentPage)
            
            if let image = pageViews[currentPage].imageView.image , dynamicBackground {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.125) {
                    self.loadDynamicBackground(image)
                }
            }
        }
    }
    
    open var numberOfPages: Int {
        return pageViews.count
    }
    
    open var dynamicBackground: Bool = false {
        didSet {
            if dynamicBackground == true {
                effectView.frame = view.frame
                backgroundView.frame = effectView.frame
                view.insertSubview(effectView, at: 0)
                view.insertSubview(backgroundView, at: 0)
            } else {
                effectView.removeFromSuperview()
                backgroundView.removeFromSuperview()
            }
        }
    }
    
    open var spacing: CGFloat = 20 {
        didSet {
            configureLayout()
        }
    }
    
    open var images: [ImagerItem] {
        get {
            return pageViews.map { $0.image }
        }
        set(value) {
            configurePages(value)
        }
    }
    
    open weak var delegate: ImagerDelegate?
    open internal(set) var presented = false
    open fileprivate(set) var seen = false
    
    lazy var transitionManager: ImagerTransition = ImagerTransition()
    var pageViews = [ImagerPageView]()
    var statusBarHidden = false
    
    fileprivate let initialImages: [ImagerItem]
    fileprivate let initialPage: Int
    
    // MARK: - Initializers
    
    public init(images: [ImagerItem] = [], startIndex index: Int = 0) {
        self.initialImages = images
        self.initialPage = index
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.initialImages = []
        self.initialPage = 0
        super.init(coder: aDecoder)
    }
    
    // MARK: - View lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        statusBarHidden = UIApplication.shared.isStatusBarHidden
        
        view.backgroundColor = UIColor.black
        transitionManager.imagerController = self
        transitionManager.scrollView = scrollView
        transitioningDelegate = transitionManager
        
        [scrollView, overlayView, headerView, footerView].forEach { view.addSubview($0) }
        overlayView.addGestureRecognizer(overlayTapGestureRecognizer)
        
        configurePages(initialImages)
        currentPage = initialPage
        
        goTo(currentPage, animated: false)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if ImagerConfiguration.hideStatusBar {
            UIApplication.shared.setStatusBarHidden(true, with: .fade)
        }
        
        if !presented {
            presented = true
            configureLayout()
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if ImagerConfiguration.hideStatusBar {
            UIApplication.shared.setStatusBarHidden(statusBarHidden, with: .fade)
        }
    }
    
    // MARK: - Rotation
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.configureLayout(size)
        }, completion: nil)
    }
    
    // MARK: - Configuration
    
    func configurePages(_ images: [ImagerItem]) {
        pageViews.forEach { $0.removeFromSuperview() }
        pageViews = []
        
        for image in images {
            let pageView = ImagerPageView(image: image)
            pageView.pageViewDelegate = self
            
            scrollView.addSubview(pageView)
            pageViews.append(pageView)
        }
        
        configureLayout()
    }
    
    // MARK: - Pagination
    
    open func goTo(_ page: Int, animated: Bool = true) {
        guard page >= 0 && page < numberOfPages else {
            return
        }
        
        currentPage = page
        
        var offset = scrollView.contentOffset
        offset.x = CGFloat(page) * (scrollView.frame.width + spacing)
        
        scrollView.setContentOffset(offset, animated: animated)
    }
    
    open func next(_ animated: Bool = true) {
        goTo(currentPage + 1, animated: animated)
    }
    
    open func previous(_ animated: Bool = true) {
        goTo(currentPage - 1, animated: animated)
    }
    
    // MARK: - Actions
    
    func overlayViewDidTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        footerView.expand(false)
    }
    
    // MARK: - Layout
    
    open func configureLayout(_ s: CGSize? = nil) {//UIScreen.main.bounds.size) {
        let size: CGSize
        if let s2 = s {
            size = s2
        } else {
            if let ws = UIApplication.shared.keyWindow?.bounds.size {
                size = ws
            } else {
                size = UIScreen.main.bounds.size
            }
        }
        scrollView.frame.size = size
        scrollView.contentSize = CGSize(
            width: size.width * CGFloat(numberOfPages) + spacing * CGFloat(numberOfPages - 1),
            height: size.height)
        scrollView.contentOffset = CGPoint(x: CGFloat(currentPage) * (size.width + spacing), y: 0)
        
        for (index, pageView) in pageViews.enumerated() {
            var frame = scrollView.bounds
            frame.origin.x = (frame.width + spacing) * CGFloat(index)
            pageView.frame = frame
            pageView.configureLayout()
            if index != numberOfPages - 1 {
                pageView.frame.size.width += spacing
            }
        }
        
        let bounds = scrollView.bounds
        let headerViewHeight = headerView.closeButton.frame.height > headerView.deleteButton.frame.height
            ? headerView.closeButton.frame.height
            : headerView.deleteButton.frame.height
        
        headerView.frame = CGRect(x: 0, y: 16, width: bounds.width, height: headerViewHeight)
        footerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 120)
        footerView.saveButton.frame = CGRect(x: footerView.frame.size.width / 2 - 25, y: 10, width: 50, height:50)
        [headerView, footerView].forEach { ($0 as AnyObject).configureLayout() }
        
        footerView.frame.origin.y = bounds.height - footerView.frame.height
        
        overlayView.frame = scrollView.frame
        overlayView.resizeGradientLayer()
    }
    
    fileprivate func loadDynamicBackground(_ image: UIImage) {
        backgroundView.image = image
        backgroundView.layer.add(CATransition(), forKey: kCATransitionFade)
    }
    
    func toggleControls(pageView: ImagerPageView?, visible: Bool, duration: TimeInterval = 0.1, delay: TimeInterval = 0) {
        let alpha: CGFloat = visible ? 1.0 : 0.0
        
        pageView?.playButton.isHidden = !visible
        
        UIView.animate(withDuration: duration, delay: delay, options: [], animations: {
            self.headerView.alpha = alpha
            self.footerView.alpha = alpha
            pageView?.playButton.alpha = alpha
        }, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate

extension ImagerController: UIScrollViewDelegate {
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var speed: CGFloat = velocity.x < 0 ? -2 : 2
        
        if velocity.x == 0 {
            speed = 0
        }
        
        let pageWidth = scrollView.bounds.width + spacing
        var x = scrollView.contentOffset.x + speed * 60.0
        
        if speed > 0 {
            x = ceil(x / pageWidth) * pageWidth
        } else if speed < -0 {
            x = floor(x / pageWidth) * pageWidth
        } else {
            x = round(x / pageWidth) * pageWidth
        }
        
        targetContentOffset.pointee.x = x
        currentPage = Int(x / screenBounds.width)
    }
}

// MARK: - ImagerPageViewDelegate

extension ImagerController: ImagerPageViewDelegate {
    
    func remoteImageDidLoad(_ image: UIImage?) {
        guard let image = image , dynamicBackground else { return }
        loadDynamicBackground(image)
    }
    
    func pageViewDidZoom(_ pageView: ImagerPageView) {
        let duration = pageView.hasZoomed ? 0.1 : 0.5
        toggleControls(pageView: pageView, visible: !pageView.hasZoomed, duration: duration, delay: 0.5)
    }
    
    func pageView(_ pageView: ImagerPageView, didTouchPlayButton videoURL: URL) {
        ImagerConfiguration.handleVideo(self, videoURL)
    }
    
    func pageViewDidTouch(_ pageView: ImagerPageView) {
        guard !pageView.hasZoomed else { return }
        
        let visible = (headerView.alpha == 1.0)
        toggleControls(pageView: pageView, visible: !visible)
    }
    
    func pageViewDidLongPress(_ pageView: ImagerPageView) {
        delegate?.imagerController(self, didLongPressedAt: currentPage)
    }
}

// MARK: - ImagerHeaderViewDelegate

extension ImagerController: ImagerHeaderViewDelegate {
    
    func headerView(_ headerView: ImagerHeaderView, didPressDeleteButton deleteButton: UIButton) {
        deleteButton.isEnabled = false
        
        guard numberOfPages != 1 else {
            pageViews.removeAll()
            self.headerView(headerView, didPressCloseButton: headerView.closeButton)
            return
        }
        
        let prevIndex = currentPage
        
        if currentPage == numberOfPages - 1 {
            previous()
        } else {
            next()
            currentPage -= 1
        }
        
        self.pageViews.remove(at: prevIndex).removeFromSuperview()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.configureLayout()
            self.currentPage = Int(self.scrollView.contentOffset.x / self.screenBounds.width)
            deleteButton.isEnabled = true
        }
    }
    
    func headerView(_ headerView: ImagerHeaderView, didPressCloseButton closeButton: UIButton) {
        closeButton.isEnabled = false
        presented = false
        delegate?.imagerControllerWillDismiss(self)
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - ImagerFooterViewDelegate

extension ImagerController: ImagerFooterViewDelegate {
    
    public func footerView(_ footerView: ImagerFooterView, didExpand expanded: Bool) {
        footerView.frame.origin.y = screenBounds.height - footerView.frame.height
        
        UIView.animate(withDuration: 0.25, animations: {
            self.overlayView.alpha = expanded ? 1.0 : 0.0
            self.headerView.deleteButton.alpha = expanded ? 0.0 : 1.0
        })
    }
    public func footerView(_ footerView: ImagerFooterView, didPressSaveButton saveButton: UIButton) {
        if images.count > 0 {
            UIImageWriteToSavedPhotosAlbum(images[0].image!, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    func image(image:UIImage,didFinishSavingWithError error:NSError?,contextInfo:AnyObject) {
        if error == nil {
            print("success")
            delegate?.imagerControllerShowReslut(self, true)
            
            
        }else{
            delegate?.imagerControllerShowReslut(self, false)
            
        }
    }
}
