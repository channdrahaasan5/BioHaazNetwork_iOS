//
//  UIImageView+BioHaazNetwork.swift
//  BioHaazNetwork
//
//  Extension for loading images from URL with placeholder, error image, and retry support
//

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
private let bh_imageCache = NSCache<NSString, UIImage>()

public extension UIImageView {
    func bh_setImage(
        from urlString: String,
        placeholder: UIImage? = nil,
        errorImage: UIImage? = nil,
        enableRetry: Bool = false
    ) {
        self.image = placeholder
        let cacheKey = NSString(string: urlString)
        if let cached = bh_imageCache.object(forKey: cacheKey) {
            self.image = cached
            return
        }
        guard let url = URL(string: urlString) else {
            self.image = errorImage
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let data = data, let img = UIImage(data: data) {
                    bh_imageCache.setObject(img, forKey: cacheKey)
                    self.image = img
                } else {
                    self.image = errorImage
                    if enableRetry {
                        self.isUserInteractionEnabled = true
                        let tap = UITapGestureRecognizer(target: self, action: #selector(self.bh_retryTap(_:)))
                        self.addGestureRecognizer(tap)
                        self.bh_retryURL = urlString
                        self.bh_retryPlaceholder = placeholder
                        self.bh_retryErrorImage = errorImage
                    }
                }
            }
        }
        task.resume()
    }
    
    // Associated objects for retry
//    private struct AssociatedKeys {
//        static var retryURL = "bh_retryURL"
//        static var retryPlaceholder = "bh_retryPlaceholder"
//        static var retryErrorImage = "bh_retryErrorImage"
//    }
    private struct AssociatedKeys {
        static var retryURL: UInt8 = 0
        static var retryPlaceholder: UInt8 = 0
        static var retryErrorImage: UInt8 = 0
    }
    private var bh_retryURL: String? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.retryURL) as? String }
        set { objc_setAssociatedObject(self, &AssociatedKeys.retryURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var bh_retryPlaceholder: UIImage? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.retryPlaceholder) as? UIImage }
        set { objc_setAssociatedObject(self, &AssociatedKeys.retryPlaceholder, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var bh_retryErrorImage: UIImage? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.retryErrorImage) as? UIImage }
        set { objc_setAssociatedObject(self, &AssociatedKeys.retryErrorImage, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    @objc private func bh_retryTap(_ sender: UITapGestureRecognizer) {
        self.isUserInteractionEnabled = false
        self.gestureRecognizers?.forEach { self.removeGestureRecognizer($0) }
        if let url = bh_retryURL {
            self.bh_setImage(from: url, placeholder: bh_retryPlaceholder, errorImage: bh_retryErrorImage, enableRetry: true)
        }
    }
}
#endif
