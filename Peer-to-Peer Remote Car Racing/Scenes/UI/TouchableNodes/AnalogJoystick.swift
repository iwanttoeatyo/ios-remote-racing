//
//  AnalogStick.swift
//  Joystick
//
//  Created by Dmitriy Mitrophanskiy on 28.09.14.
//  https://github.com/MitrophD/Swift-SpriteKit-Analog-Stick
//
import SpriteKit

//MARK: AnalogJoystickData
public struct AnalogJoystickData: CustomStringConvertible {
    var velocity = CGPoint.zero,
    angular = CGFloat(0)
    
    mutating func reset() {
        velocity = CGPoint.zero
        angular = 0
    }
    
    public var description: String {
        return "AnalogStickData(velocity: \(velocity), angular: \(angular))"
    }
}

//MARK: - AnalogJoystickComponent
open class AnalogJoystickComponent: SKSpriteNode {
    private var kvoContext = UInt8(1)
    var borderWidth = CGFloat(0) {
        didSet {
            redrawTexture()
        }
    }
    
    var borderColor = UIColor.black {
        didSet {
            redrawTexture()
        }
    }
    
    var image: UIImage? {
        didSet {
            redrawTexture()
        }
    }
    
    var diameter: CGFloat {
        get {
            return max(size.width, size.height)
        }
        
        set(newSize) {
            size = CGSize(width: newSize, height: newSize)
        }
    }
    
    var radius: CGFloat {
        get {
            return diameter * 0.5
        }
        
        set(newRadius) {
            diameter = newRadius * 2
        }
    }
    
    override public init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size);
    }
    
    //MARK: - DESIGNATED
    init(diameter: CGFloat, color: UIColor? = nil, image: UIImage? = nil) {
        super.init(texture: nil, color: color ?? UIColor.black, size: CGSize(width: diameter, height: diameter))
        addObserver(self, forKeyPath: "color", options: NSKeyValueObservingOptions.old, context: &kvoContext)
        self.diameter = diameter
        self.image = image
        redrawTexture()
    }
    
    init(templateNode : SKSpriteNode) {
        super.init(texture: templateNode.texture, color: templateNode.color, size: templateNode.size);
        addObserver(self, forKeyPath: "color", options: NSKeyValueObservingOptions.old, context: &kvoContext)
        self.diameter = templateNode.size.width;
        self.image = UIImage(cgImage: templateNode.texture!.cgImage());
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObserver(self, forKeyPath: "color")
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        redrawTexture()
    }
    
    private func redrawTexture() {
        
        guard diameter > 0 else {
            print("Diameter should be more than zero")
            texture = nil
            return
        }
        
        let scale = UIScreen.main.scale
        let needSize = CGSize(width: self.diameter, height: self.diameter)
        UIGraphicsBeginImageContextWithOptions(needSize, false, scale)
        let rectPath = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: needSize))
        rectPath.addClip()
        
        if let img = image {
            img.draw(in: CGRect(origin: CGPoint.zero, size: needSize), blendMode: .normal, alpha: 1)
        } else {
            color.set()
            rectPath.fill()
        }
        
        let needImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        texture = SKTexture(image: needImage)
    }
}

//MARK: - AnalogJoystickSubstrate
open class AnalogJoystickSubstrate: AnalogJoystickComponent {
    // coming soon...
}

//MARK: - AnalogJoystickStick
open class AnalogJoystickStick: AnalogJoystickComponent {
    // coming soon...
}

//MARK: - AnalogJoystick
open class AnalogJoystick: SKNode {
    var trackingHandler: ((AnalogJoystickData) -> ())?
    var beginHandler: (() -> Void)?
    var stopHandler: (() -> Void)?
    var substrate: AnalogJoystickSubstrate!
    var stick: AnalogJoystickStick!
    private var tracking = false
    var data = AnalogJoystickData()
    var disabledYAxis: Bool = false;
    
    var disabled: Bool {
        get {
            return !isUserInteractionEnabled
        }
        
        set(isDisabled) {
            isUserInteractionEnabled = !isDisabled
            
            if isDisabled {
                resetStick()
            }
        }
    }
    
    var diameter: CGFloat {
        get {
            return substrate.diameter
        }
        
        set(newDiameter) {
            stick.diameter += newDiameter - diameter
            substrate.diameter = newDiameter
        }
    }
    
    var radius: CGFloat {
        get {
            return diameter * 0.5
        }
        
        set(newRadius) {
            diameter = newRadius * 2
        }
    }
    
    override init() {
        super.init();
    }
    
    init(substrate: AnalogJoystickSubstrate, stick: AnalogJoystickStick) {
        super.init()
        self.substrate = substrate
        substrate.zPosition = 0
        addChild(substrate)
        self.stick = stick
        stick.zPosition = substrate.zPosition + 1
        addChild(stick)
        disabled = false
        let velocityLoop = CADisplayLink(target: self, selector: #selector(listen))
        velocityLoop.add(to: RunLoop.current, forMode: RunLoop.Mode(rawValue: RunLoop.Mode.common.rawValue))
    }
    
    convenience init(diameters: (substrate: CGFloat, stick: CGFloat?), colors: (substrate: UIColor?, stick: UIColor?)? = nil, images: (substrate: UIImage?, stick: UIImage?)? = nil) {
        let stickDiameter = diameters.stick ?? diameters.substrate * 0.6,
        jColors = colors ?? (substrate: nil, stick: nil),
        jImages = images ?? (substrate: nil, stick: nil),
        substrate = AnalogJoystickSubstrate(diameter: diameters.substrate, color: jColors.substrate, image: jImages.substrate),
        stick = AnalogJoystickStick(diameter: stickDiameter, color: jColors.stick, image: jImages.stick)
        self.init(substrate: substrate, stick: stick)
    }
    
    convenience init(diameter: CGFloat, colors: (substrate: UIColor?, stick: UIColor?)? = nil, images: (substrate: UIImage?, stick: UIImage?)? = nil) {
        self.init(diameters: (substrate: diameter, stick: nil), colors: colors, images: images)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let stickNode = self.childNode(withName: "//stick") as? SKSpriteNode else {
            fatalError("stick SKSpriteNode missing. Cannot init AnalogJoystick")
        }
        stickNode.removeFromParent();
        guard let substrateNode = self.childNode(withName: "//substrate") as? SKSpriteNode else {
            fatalError("substrate SKSpriteNode missing. Cannot init AnalogJoystick")
        }
        substrateNode.removeFromParent();
        
        self.substrate = AnalogJoystickSubstrate(templateNode: substrateNode);
        self.stick = AnalogJoystickStick(templateNode: stickNode);

        substrate.zPosition = 0
        addChild(substrate)
        stick.zPosition = substrate.zPosition + 1
        addChild(stick)
        disabled = false
        stick.position = .zero;

        let velocityLoop = CADisplayLink(target: self, selector: #selector(listen))
        velocityLoop.add(to: RunLoop.current, forMode: RunLoop.Mode(rawValue: RunLoop.Mode.common.rawValue))
    }
    
    @objc func listen() {
        
        if tracking {
            trackingHandler?(data)
        }
    }
    
    //MARK: - Overrides
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first, stick == atPoint(touch.location(in: self)) {
            tracking = true
            beginHandler?()
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            
            guard tracking else {
                return
            }
            
            let maxDistantion = substrate.radius;
            let realDistantion = sqrt(pow(location.x, 2) + pow(location.y, 2));
            var position = realDistantion <= maxDistantion ? CGPoint(x: location.x, y: location.y) : CGPoint(x: location.x / realDistantion * maxDistantion, y: location.y / realDistantion * maxDistantion)
            if disabledYAxis {
                stick.position.x = position.x;
                stick.position.y = 0;
                position /= maxDistantion;
                data = AnalogJoystickData(velocity: CGPoint(x: position.x, y: data.velocity.y), angular: -atan2(position.x, 0));
            } else {
                stick.position = position;
                position /= maxDistantion;
                data = AnalogJoystickData(velocity: position, angular: -atan2(position.x, position.y))
            }

        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }
    
    // CustomStringConvertible protocol
    open override var description: String {
        return "AnalogJoystick(data: \(data), position: \(position))"
    }
    
    // private methods
    private func resetStick() {
        tracking = false
        let moveToBack = SKAction.move(to: CGPoint.zero, duration: TimeInterval(0.1))
        moveToBack.timingMode = .easeOut
        
        //  BUG: This action doesnt run until after the app is minimized
        stick.run(moveToBack);
        // workaround
        stick.position = .zero;
        
        if disabledYAxis {
            data.velocity.x = 0;
        } else {
            data.reset();
        }
        
        stopHandler?();
    }
}

typealias 🕹 = AnalogJoystick
