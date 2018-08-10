
import UIKit

open class ImagerItem {
    
    open static var defaultImageURL = "https://meniny.cn/assets/images/default.jpg"
    
    open fileprivate(set) var image: UIImage?
    open fileprivate(set) var imageURL: URL?
    open fileprivate(set) var videoURL: URL?
    open var text: String
    
    // MARK: - Initialization
    
    public init(image: UIImage, text: String = "", videoURL: URL? = nil) {
        self.image = image
        self.text = text
        self.videoURL = videoURL
    }
    
    public init(imageURL: URL, text: String = "", videoURL: URL? = nil ) {
        self.imageURL = imageURL
        self.text = text
        self.videoURL = videoURL
    }
    
    public init(imageURLString: String, text: String = "", videoURL: URL? = nil ) {
        self.imageURL = URL(string: imageURLString) ?? URL(string: ImagerItem.defaultImageURL)!
        self.text = text
        self.videoURL = videoURL
    }
    
    open func addImageTo(_ imageView: UIImageView, completion: ((_ image: UIImage?) -> Void)? = nil) {
        if let image = image {
            imageView.image = image
            completion?(image)
        } else if let imageURL = imageURL {
            ImagerConfiguration.loadImage(imageView, imageURL) { error, image in
                completion?(image)
            }
        }
    }
}
