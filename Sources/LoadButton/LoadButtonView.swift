//
//  LoadingButtonView.swift
//  
//
//  Created by Vinícius Dornelles Brandão on 08/05/21.
//

import UIKit

@IBDesignable
open class LoadButtonView: UIButton {
    
    // MARK: - Style (iOS 13+)
    /// Button style for light mode and dark mode use. Only available on iOS 13 or later.
    @available(iOS 13.0, *)
    public enum ButtonStyle {
        case fill
        case outline
    }
    
    public enum IndicatorType {
        case dots
    }
    
    // MARK: - Public variables
    /// Current loading state.
    public var isLoading: Bool = false
    
    /// The flag that indicate if the shadow is added to prevent duplicate drawing.
    public var shadowAdded: Bool = false
    
    // MARK: - Package-protected variables

    /// The loading indicator used with the button.
    open var indicator: UIView & LoadButtonDelegate = UIActivityIndicatorView()
    
    /// Set to true to add shadow to the button.
    @IBInspectable
    open var withShadow: Bool = false
    
    /// The corner radius of the button
    @IBInspectable
    open var cornerRadius: CGFloat = 12.0 {
        didSet {
            self.clipsToBounds = (self.cornerRadius > 0)
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    
    /// Button background color
    @IBInspectable
    public var bgColor: UIColor = .lightGray {
        didSet {
            backgroundColor = self.bgColor
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
    /**
     Convenience init of theme button with required information
     
     - Parameter icon:      the icon of the button, it is be nil by default.
     - Parameter text:      the title of the button.
     - Parameter textColor: the text color of the button.
     - Parameter textSize:  the text size of the button label.
     - Parameter bgColor:   the background color of the button, tint color will be automatically generated.
     */
    public init(
        frame: CGRect = .zero,
        icon: UIImage? = nil,
        text: String? = nil,
        textColor: UIColor? = .white,
        font: UIFont? = nil,
        bgColor: UIColor = .black,
        cornerRadius: CGFloat = 12.0,
        withShadow: Bool = false
    ) {
        super.init(frame: frame)
        // Set the icon of the button
        if let icon = icon {
            self.setImage(icon)
        }
        // Set the title of the button
        if let text = text {
            self.setTitle(text)
            self.setTitleColor(textColor, for: .normal)
            self.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        // Set button contents
        self.titleLabel?.font = font
        self.bgColor = bgColor
        self.backgroundColor = bgColor
        self.setBackgroundImage(UIImage(.lightGray), for: .disabled)
        self.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        self.setCornerBorder(cornerRadius: cornerRadius)
        self.withShadow = withShadow
        self.cornerRadius = cornerRadius
    }
    
    /**
     Convenience init of material design button using system default colors. This initializer
     reflects dark mode colors on iOS 13 or later platforms. However, it will ignore any custom
     colors set to the button.
     
     - Parameter icon:         the icon of the button, it is be nil by default.
     - Parameter text:         the title of the button.
     - Parameter font:         the font of the button label.
     - Parameter cornerRadius: the corner radius of the button. It is set to 12.0 by default.
     - Parameter withShadow:   set true to show the shadow of the button.
     - Parameter buttonStyle:  specify the button style. Styles currently available are fill and outline.
    */
    public convenience init(icon: UIImage? = nil,
                            text: String? = nil,
                            font: UIFont? = nil,
                            cornerRadius: CGFloat = 12.0,
                            withShadow: Bool = false) {
        self.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Display the loader inside the button.
     - Parameter userInteraction: Enable the user interaction while displaying the loader.
     - Parameter completion:      The completion handler.
     */
    open func showLoader(
        indicatorType: IndicatorType,
        indicatorColor: UIColor = UIColor.lightGray,
        indicatorRadius: CGFloat = 12,
        userInteraction: Bool,
        completion: LoadButtonOptionalCompletion = nil)
    {
        showLoader(
            [titleLabel, imageView],
            indicatorType: indicatorType,
            indicatorColor: indicatorColor,
            indicatorRadius: indicatorRadius,
            userInteraction: userInteraction,
            completion: completion)
    }
    
    /**
     Show a loader inside the button with image.
     
     - Parameter userInteraction: Enable user interaction while showing the loader.
     */
    open func showLoaderWithImage(
        indicatorType: IndicatorType,
        indicatorColor: UIColor = UIColor.lightGray,
        indicatorRadius: CGFloat = 12,
        userInteraction: Bool)
    {
        showLoader([titleLabel],
                   indicatorType: .dots,
                   indicatorColor: indicatorColor,
                   indicatorRadius: indicatorRadius,
                   userInteraction: userInteraction)
    }

    internal func showLoader(
        _ viewsToBeHidden: [UIView?],
        indicatorType: IndicatorType,
        indicatorColor: UIColor = .lightGray,
        indicatorRadius: CGFloat = 12,
        userInteraction: Bool = false,
        completion: LoadButtonOptionalCompletion = nil)
    {
        guard !self.subviews.contains(indicator) else { return }
        
        switch indicatorType {
        case .dots:
            indicator = DotsIndicator(radius: indicatorRadius, color: indicatorColor)
        }
        
        originalButtonTitle = titleLabel?.text
        // Set up loading indicator and update loading state
        isLoading = true
        self.isUserInteractionEnabled = userInteraction
        indicator.radius = min(0.7 * self.frame.height / 2, indicator.radius)
        indicator.alpha = 0.0
        self.addSubview(self.indicator)
        
        // Clean up
        loaderWorkItem?.cancel()
        loaderWorkItem = nil
        
        // Create a new work item
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
                completion?()
            }
        }
        loaderWorkItem?.perform()
    }
    /**
     Hide the loader displayed.
     
     - Parameter completion: The completion handler.
     */
    open func hideLoader(_ completion: LoadButtonOptionalCompletion = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.subviews.contains(self.indicator)
            else { return }
            
            // Update loading state
            self.isLoading = false
            self.isUserInteractionEnabled = true
            self.indicator.stopAnimating()
            // Clean up
            self.indicator.removeFromSuperview()
            self.loaderWorkItem?.cancel()
            self.loaderWorkItem = nil
            // Create a new work item
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
    /**
     Make the content of the button fill the button.
     */
    public func fillContent() {
        self.contentVerticalAlignment = .fill
        self.contentHorizontalAlignment = .fill
    }
    // layoutSubviews
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
