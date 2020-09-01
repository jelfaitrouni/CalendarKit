#if os(iOS)
import UIKit

public protocol EventViewDelegate: AnyObject {
  func didClickOnEditButton(_ eventView: EventView)
  func didClickOnDeleteButton(_ eventView: EventView)
}

open class EventView: UIView {
  
  let buttonWidth: CGFloat = 30
  let buttonPadding: CGFloat = 8
  
  public var descriptor: EventDescriptor?
  public var color = UIColor.lightGray
  public weak var delegate: EventViewDelegate?
    
  public var contentHeight: CGFloat {
    return textView.frame.height
  }

  public lazy var textView: UITextView = {
    let view = UITextView()
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    view.isScrollEnabled = false
    return view
  }()

  /// Resize Handle views showing up when editing the event.
  /// The top handle has a tag of `0` and the bottom has a tag of `1`
  public lazy var eventResizeHandles = [EventResizeHandleView(), EventResizeHandleView()]
  
  var edit_btn: UIButton!
  var delete_btn: UIButton!

  override public init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configure()
  }

  private func configure() {
    clipsToBounds = false
    color = tintColor
    addSubview(textView)
    
    for (idx, handle) in eventResizeHandles.enumerated() {
      handle.tag = idx
      addSubview(handle)
    }
    
    let bundle = Bundle(for: EventView.self)
    
    edit_btn = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth))
    edit_btn.setImage(UIImage(named: "edit", in: bundle, compatibleWith: nil), for: .normal)
    edit_btn.addTarget(self, action: #selector(editAction), for: .touchUpInside)
    edit_btn.isUserInteractionEnabled = true
    addSubview(edit_btn)
    
    delete_btn = UIButton(frame: CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth))
    delete_btn.setImage(UIImage(named: "delete", in: bundle, compatibleWith: nil), for: .normal)
    delete_btn.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
    delete_btn.isUserInteractionEnabled = true
    addSubview(delete_btn)
    
  }

  public func updateWithDescriptor(event: EventDescriptor) {
    if let attributedText = event.attributedText {
      textView.attributedText = attributedText
    } else {
      textView.text = event.text
      textView.textColor = event.textColor
      textView.font = event.font
    }
    descriptor = event
    backgroundColor = event.backgroundColor
    color = event.color
    eventResizeHandles.forEach{
      $0.borderColor = event.color
      $0.isHidden = event.editedEvent == nil
    }
    drawsShadow = event.editedEvent != nil
    
    if event.isEditable && (event.startDate > Date() || Date() < event.endDate) {
      edit_btn.isHidden = false
      delete_btn.isHidden = false
    } else {
      edit_btn.isHidden = true
      delete_btn.isHidden = true
    }
   
    
    setNeedsDisplay()
    setNeedsLayout()
  }
  
  public func animateCreation() {
    transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    func scaleAnimation() {
      transform = .identity
    }
    UIView.animate(withDuration: 0.2,
                   delay: 0,
                   usingSpringWithDamping: 0.2,
                   initialSpringVelocity: 10,
                   options: [],
                   animations: scaleAnimation,
                   completion: nil)
  }

  /**
   Custom implementation of the hitTest method is needed for the tap gesture recognizers
   located in the ResizeHandleView to work.
   Since the ResizeHandleView could be outside of the EventView's bounds, the touches to the ResizeHandleView
   are ignored.
   In the custom implementation the method is recursively invoked for all of the subviews,
   regardless of their position in relation to the Timeline's bounds.
   */
//  public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//
//
////    for resizeHandle in eventResizeHandles {
////      if let subSubView = resizeHandle.hitTest(convert(point, to: resizeHandle), with: event) {
////        return subSubView
////      }
////    }
//
//    if descriptor?.isEditable == true {
//      return super.hitTest(point, with: event)
//    } else {
//      return nil
//    }
//
//  }

  override open func draw(_ rect: CGRect) {
    super.draw(rect)
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
    context.interpolationQuality = .none
    context.saveGState()
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(3)
    context.translateBy(x: 0, y: 0.5)
    let x: CGFloat = 0
    let y: CGFloat = 0
    context.beginPath()
    context.move(to: CGPoint(x: x, y: y))
    context.addLine(to: CGPoint(x: x, y: (bounds).height))
    context.strokePath()
    context.restoreGState()
  }

  private var drawsShadow = false

  override open func layoutSubviews() {
    super.layoutSubviews()
    textView.frame = bounds
    if frame.minY < 0 {
      var textFrame = textView.frame;
      textFrame.origin.y = frame.minY * -1;
      textFrame.size.height += frame.minY;
      textView.frame = textFrame;
    }
    let first = eventResizeHandles.first
    let last = eventResizeHandles.last
    let radius: CGFloat = 40
    let yPad: CGFloat =  -radius / 2
    let width = bounds.width
    let height = bounds.height
    let size = CGSize(width: radius, height: radius)
    first?.frame = CGRect(origin: CGPoint(x: width - radius - layoutMargins.right, y: yPad),
                          size: size)
    last?.frame = CGRect(origin: CGPoint(x: layoutMargins.left, y: height - yPad - radius),
                         size: size)
    
    if drawsShadow {
      applySketchShadow(alpha: 0.13,
                        blur: 10)
    }
    
    edit_btn.frame = CGRect(x: bounds.width - 2 * (buttonPadding + buttonWidth), y: buttonPadding, width: buttonWidth, height: buttonWidth)
    delete_btn.frame = CGRect(x: bounds.width - (buttonPadding + buttonWidth), y: buttonPadding, width: buttonWidth, height: buttonWidth)
    
  }

  private func applySketchShadow(
    color: UIColor = .black,
    alpha: Float = 0.5,
    x: CGFloat = 0,
    y: CGFloat = 2,
    blur: CGFloat = 4,
    spread: CGFloat = 0)
  {
    layer.shadowColor = color.cgColor
    layer.shadowOpacity = alpha
    layer.shadowOffset = CGSize(width: x, height: y)
    layer.shadowRadius = blur / 2.0
    if spread == 0 {
      layer.shadowPath = nil
    } else {
      let dx = -spread
      let rect = bounds.insetBy(dx: dx, dy: dx)
      layer.shadowPath = UIBezierPath(rect: rect).cgPath
    }
  }
  
  @objc func editAction() {
    delegate?.didClickOnEditButton(self)
  }
  
  @objc func deleteAction() {
    delegate?.didClickOnDeleteButton(self)
  }
}
#endif
