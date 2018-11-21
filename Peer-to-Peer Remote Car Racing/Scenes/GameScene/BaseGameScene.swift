//
//  GameScene.swift
//  race prototype
//
//  Created by Christopher Boyd on 2018-11-06.
//  Copyright © 2018 Christopher Boyd. All rights reserved.
//

import SpriteKit
import GameplayKit

@objc
protocol BaseGameSceneProtocol : class {
    func presentSubmitScoreSubview(gameScene: BaseGameScene);
}

class BaseGameScene: SKScene {
    
    weak var gameSceneDelegate : BaseGameSceneProtocol?
    
    private var lastUpdateTime : TimeInterval = 0
    
    public var joystickEnabled = false;
    var debugMode = false;
    
    var cam: SKCameraNode!
    
    var startPosition: CGPoint!;
    var player: Player!;
    
    var waypoints: Int = 0;
    var lap: Int = 1;
    var lastWaypoint: Int = 0;
    var totalLaps:Int = 3;
    var totalTime: TimeInterval = 0;
    var summedLapTimes: TimeInterval = 0;
    
    private var landBackground:SKTileMapNode!
    private var track:SKTileMapNode!
    
    var hud: UIHUD!;

    
    private let displaySize: CGRect = UIScreen.main.bounds;
    
    private var buttons: [ButtonNode] = [];
    
    var inputControl: InputControl!;
   
    var overlay: SceneOverlay? {
        didSet {
            buttons = [];
            oldValue?.backgroundNode.removeFromParent();
            
            if let overlay = overlay, let camera = camera {
                //showing overlay
               
                camera.addChild(overlay.backgroundNode);
                overlay.updateScale();
                
                buttons = findAllButtonsInScene();
                
            } else {
                //dismissing overlay

            }
        }
    }
    
    lazy var stateMachine: GKStateMachine = GKStateMachine(states: [
        GameActiveState(gameScene: self),
        GamePauseState(gameScene: self),
        //GameFailureState(gameScene: self),
        //GameSuccessState(gameScene: self)
        ])
    
    override func sceneDidLoad() {
       
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view);
        physicsWorld.contactDelegate = self;
        setupRace();
        setupCamera();
        setupHUD();

        stateMachine.enter(GameActiveState.self);
    }
    
    func setupCamera(){
        cam = SKCameraNode();
        self.camera = cam;
        cam.setScale(2);
        cam.position = player.position;
        self.addChild(cam!);
    }
    
    func setupRace(){
        guard let landBackground = childNode(withName: "Background") as? SKTileMapNode else {
            fatalError("Background node not loaded");
        }
        
        self.landBackground = landBackground;
        
        guard let track = childNode(withName: "Track") as? SKTileMapNode else {
            fatalError("Track node not loaded")
        }
        
        self.track = track;
        
        //Get start position for car
        for row in 0..<track.numberOfRows {
            for col in 0..<track.numberOfColumns {
                let tile = track.tileGroup(atColumn: col, row: row)
                if (tile != nil)
                {
                    if tile?.name == "AsphaltStartPosition1" {
                        startPosition = track.centerOfTile(atColumn: col, row: row);
                    }
                }
                
            }
        }
        
        //Count number of waypoint in this track
        self.enumerateChildNodes(withName: "Waypoint*"){
            (node, stop) in
            self.waypoints += 1;
            node.alpha = 0;
        }
        
        //Add the player car
        player = Player(position: startPosition);
        self.addChild(player!);
    }
    
    func setupHUD(){
        hud = UIHUD();
        cam.addChild(hud);
        
        let touchControls = UITouchControlsJoystick();
        inputControl = touchControls.inputControl;
        
        if(joystickEnabled){
            cam.addChild(touchControls);
        }
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        self.lastUpdateTime = currentTime

        if isPaused {
            return;
        }
        
        if let camera = cam, let pl = player {
            camera.position = pl.position;
            camera.zRotation = pl.zRotation;
            //print("cam: \(camera.position)");
            //print("player:  \(pl.position)");
        }
        if inputControl.velocity.y > 0 {
            player.accelForward(dt * Double(inputControl.velocity.y));
        }else{
            player.accelBackwards(dt * Double(inputControl.velocity.y));
        }
        if(abs(inputControl.velocity.x) > 0.15){
            player.turn(dt * Double(inputControl.velocity.x));
        }
        
         stateMachine.update(deltaTime: dt);
        
    }
    
    
    func previousWaypoint(_ index:Int) -> Int {
        var result = index - 1;
        if result < 0 {
            result = waypoints - 1;
        }
        return result;
    }
    
}

extension BaseGameScene: SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact) {
        
        for waypoint in 0..<waypoints {
            let waypointName = "Waypoint\(waypoint)";
            if(contact.bodyA.node?.name == waypointName ||
                contact.bodyB.node?.name == waypointName) {
               
                if(lastWaypoint == previousWaypoint(waypoint)) {
                     print("hit \(waypointName)");
                    //Update waypoint
                    lastWaypoint = waypoint;
                    if previousWaypoint(waypoint) > waypoint {
                        lap += 1;
                        //TODO: play lap sound
                        hud.bestLapNode.isHidden = false;
                        hud.bestLapTimeLabel.text = stringFromTimeInterval(interval: totalTime - summedLapTimes) as String;
                        summedLapTimes = totalTime;
                    }
                }
                break;
            }
        }
        


    }
}

