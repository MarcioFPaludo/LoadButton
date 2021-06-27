//
//  LoadButton.swift
//  
//
//  Created by Vinícius Dornelles Brandão on 08/05/21.
//

import UIKit

public enum IndicatorType {
    case dots(radius: CGFloat, color: UIColor)
    
    fileprivate var indicator: UIView & LoadButtonDelegate {
        switch self {
        case .dots(let radius, let color):
            return DotsIndicator(radius: radius, color: color)
        }
    }
}

open class LoadButton: UIButton {
    
    // MARK: - Private properties
    private(set) var isLoading: Bool = false
    private var shadowAdded: Bool = false
    private var indicatorType: IndicatorType?
    private var indicator: UIView & LoadButtonDelegate = UIActivityIndicatorView()
    
    // MARK: - Public variables
    open var cornerRadius: CGFloat = 12.0 {
        didSet {
            self.clipsToBounds = (self.cornerRadius > 0)
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    
    // MARK: - Private Properties
    private var imageAlpha: CGFloat = 1.0
    private var titleColor: UIColor?
    private var loaderWorkItem: DispatchWorkItem?
    private var originalButtonTitle: String?
    
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Loader
    
    open func loader(indicatorType: IndicatorType, userInteraction: Bool, completion: @escaping LoadingCompletion) {
        showLoader([titleLabel], indicatorType: indicatorType, userInteraction: userInteraction, completion: completion)
    }
    
    // MARK: - General Methods
    
    internal func showLoader(_ viewsToBeHidden: [UIView?], indicatorType: IndicatorType, userInteraction: Bool = false, completion: @escaping LoadingCompletion) {
        guard !self.subviews.contains(self.indicator) else { return }
        
        self.indicator = indicatorType.indicator
        
        originalButtonTitle = titleLabel?.text
        
        isLoading = true
        self.isUserInteractionEnabled = userInteraction
        indicator.radius = min(0.7 * self.frame.height / 2, indicator.radius)
        indicator.alpha = 0.0
        self.addSubview(indicator)
        
        loaderWorkItem?.cancel()
        loaderWorkItem = nil
        
        loaderWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self, let item = self.loaderWorkItem, !item.isCancelled else { return }
            UIView.transition(with: self, duration: 0.5, options: .curveEaseOut, animations: {
                viewsToBeHidden.forEach { view in
                    self.imageAlpha = 0.0
                    view?.alpha = 0.0
                }
                self.setTitle("")
                self.indicator.alpha = 1.0
            }) { _ in
                guard !item.isCancelled else { return }
                self.isLoading ? self.indicator.startAnimating() : self.hideLoader()
                completion(self.isLoading)
            }
        }
        loaderWorkItem?.perform()
    }
    
    open func hideLoader(_ completion: LoadButtonOptionalCompletion = nil) {
        DispatchQueue.main.async { [weak self] in
            guard
                let self = self,
                self.subviews.contains(self.indicator)
            else { return }
            
            self.isLoading = false
            self.isUserInteractionEnabled = true
            self.indicator.stopAnimating()
            
            self.indicator.removeFromSuperview()
            
            self.loaderWorkItem?.cancel()
            self.loaderWorkItem = nil
            
            self.loaderWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self, let item = self.loaderWorkItem, !item.isCancelled else { return }
                UIView.transition(with: self, duration: 0.5, options: .curveEaseIn, animations: { [weak self] in
                    guard let self = self else { return }
                    self.setTitle(self.originalButtonTitle)
                    self.titleLabel?.alpha = 1.0
                    self.imageView?.alpha = 1.0
                    self.imageAlpha = 1.0
                }) { _ in
                    guard !item.isCancelled else { return }
                    completion?()
                }
            }
            self.loaderWorkItem?.perform()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = imageView {
            imageView.alpha = imageAlpha
        }
        
        indicator.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
    }
}

// MARK: - UIActivityIndicatorView
extension UIActivityIndicatorView: LoadButtonDelegate {
    
    // MARK: - Properties
    public var radius: CGFloat {
        get {
            return self.frame.width/2
        }
        set {
            self.frame.size = CGSize(width: 2*newValue, height: 2*newValue)
            self.setNeedsDisplay()
        }
    }
    
    public var color: UIColor {
        get { return self.tintColor }
        set { self.tintColor = newValue }
    }
    
    // MARK: LoadingButtonDelegate
    public func setupAnimation(in layer: CALayer, size: CGSize) {}
}
