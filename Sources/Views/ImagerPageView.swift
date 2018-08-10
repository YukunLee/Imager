import UIKit

protocol ImagerPageViewDelegate: class {
    
    func pageViewDidZoom(_ pageView: ImagerPageView)
    func remoteImageDidLoad(_ image: UIImage?)
    func pageView(_ pageView: ImagerPageView, didTouchPlayButton videoURL: URL)
    func pageViewDidTouch(_ pageView: ImagerPageView)
    func pageViewDidLongPress(_ pageView: ImagerPageView)
}

open class ImagerPageView: UIScrollView {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 60, height: 60)
        button.setBackgroundImage(UIImage.image(named: "ImagerPlay"), for: UIControlState())
        button.addTarget(self, action: #selector(playButtonTouched(_:)), for: .touchUpInside)
        
        button.layer.shadowOffset = CGSize(width: 1, height: 1)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.masksToBounds = false
        button.layer.shadowOpacity = 0.8
        
        return button
    }()
    
    lazy var activityIndicator: ImagerLoadingIndicator = ImagerLoadingIndicator()
    
    var image: ImagerItem
    var contentFrame = CGRect.zero
    weak var pageViewDelegate: ImagerPageViewDelegate?
    
    var hasZoomed: Bool {
        return zoomScale != 1.0
    }
    
    // MARK: - Initializers
    
    init(image: ImagerItem) {
        self.image = image
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    func setup() {
        configure()
        activityIndicator.alpha = 1
        self.image.addImageTo(imageView) { image in
            self.isUserInteractionEnabled = true
            self.configureImageView()
            self.pageViewDelegate?.remoteImageDidLoad(image)
            
            UIView.animate(withDuration: 0.4) {
                self.activityIndicator.alpha = 0
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.image = ImagerItem(imageURL: URL(string: ImagerItem.defaultImageURL)!)
        super.init(coder: aDecoder)
        self.setup()
    }
    
    // MARK: - Configuration
    
    func configure() {
        addSubview(imageView)
        
        if image.videoURL != nil {
            addSubview(playButton)
        }
        
        addSubview(activityIndicator)
        
        delegate = self
        isMultipleTouchEnabled = true
        minimumZoomScale = ImagerConfiguration.Zoom.minimumScale
        maximumZoomScale = ImagerConfiguration.Zoom.maximumScale
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapped(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        addGestureRecognizer(tapRecognizer)
        
        tapRecognizer.require(toFail: doubleTapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(viewLongPressed(_:)))
        longPressRecognizer.numberOfTouchesRequired = 1
        longPressRecognizer.minimumPressDuration = 1
        longPressRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(longPressRecognizer)
        
        doubleTapRecognizer.require(toFail: longPressRecognizer)
    }
    
    // MARK: - Recognizers
    
    func scrollViewDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        let newZoomScale = zoomScale > minimumZoomScale
            ? minimumZoomScale
            : maximumZoomScale
        
        let width = contentFrame.size.width / newZoomScale
        let height = contentFrame.size.height / newZoomScale
        let x = pointInView.x - (width / 2.0)
        let y = pointInView.y - (height / 2.0)
        
        let rectToZoomTo = CGRect(x: x, y: y, width: width, height: height)
        
        zoom(to: rectToZoomTo, animated: true)
    }
    
    func viewTapped(_ recognizer: UITapGestureRecognizer) {
        pageViewDelegate?.pageViewDidTouch(self)
    }
    
    func viewLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        pageViewDelegate?.pageViewDidLongPress(self)
    }
    // MARK: - Layout
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        activityIndicator.center = imageView.center
        playButton.center = imageView.center
    }
    
    func configureImageView() {
        guard let image = imageView.image else { return }
        
        let imageViewSize = imageView.frame.size
        let imageSize = image.size
        let realImageViewSize: CGSize
        
        if imageSize.width / imageSize.height > imageViewSize.width / imageViewSize.height {
            realImageViewSize = CGSize(
                width: imageViewSize.width,
                height: imageViewSize.width / imageSize.width * imageSize.height)
        } else {
            realImageViewSize = CGSize(
                width: imageViewSize.height / imageSize.height * imageSize.width,
                height: imageViewSize.height)
        }
        
        imageView.frame = CGRect(origin: CGPoint.zero, size: realImageViewSize)
        
        centerImageView()
    }
    
    func centerImageView() {
        let boundsSize = contentFrame.size
        var imageViewFrame = imageView.frame
        
        if imageViewFrame.size.width < boundsSize.width {
            imageViewFrame.origin.x = (boundsSize.width - imageViewFrame.size.width) / 2.0
        } else {
            imageViewFrame.origin.x = 0.0
        }
        
        if imageViewFrame.size.height < boundsSize.height {
            imageViewFrame.origin.y = (boundsSize.height - imageViewFrame.size.height) / 2.0
        } else {
            imageViewFrame.origin.y = 0.0
        }
        
        imageView.frame = imageViewFrame
    }
    
    // MARK: - Action
    
    func playButtonTouched(_ button: UIButton) {
        guard let videoURL = image.videoURL else { return }
        
        pageViewDelegate?.pageView(self, didTouchPlayButton: videoURL as URL)
    }
    
    // MARK: - Controls
    
    func makeActivityIndicator() -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .white)
        ImagerConfiguration.ImagerLoadingIndicator.configure?(view)
        view.startAnimating()
        
        return view
    }
}

// MARK: - ImagerLayoutConfigurable

extension ImagerPageView: ImagerLayoutConfigurable {
    
    public func configureLayout() {
        contentFrame = frame
        contentSize = frame.size
        imageView.frame = frame
        zoomScale = minimumZoomScale
        
        configureImageView()
    }
}

// MARK: - UIScrollViewDelegate

extension ImagerPageView: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
        pageViewDelegate?.pageViewDidZoom(self)
    }
}
