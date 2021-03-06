//
//  GameViewController.swift
//  race prototype
//
//  Created by Christopher Boyd on 2018-11-06.
//  Copyright © 2018 Christopher Boyd. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    var carType:String = "";
    var track:String = "Track1";
    var scene : BaseGameScene?;
    var gameMode : GameMode = .SOLO;
    weak var networkService: NetworkService?;
    weak var trackSelectionViewController: TrackSelectionViewController?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load the correct track scene
        if let scene = BaseGameScene(fileNamed: self.track) {
            self.scene = scene;
            //setup the scene
            
            scene.name = self.track;
            scene.carType = carType;
            
            //Set the gameMode because it affects what is displaying
            //in the scene
            scene.gameMode = gameMode;
            
            //This view will act the game scenes delegate
            scene.gameSceneDelegate = self;
            
            //Pass the network service to the game scene
            scene.networkService = networkService;
            //set the gameScene as the network service delegate
            networkService?.delegate = scene;
            
            //debug
            scene.debugMode = true;
            
            // Present the scene
            if let view = self.view as! SKView? {
                view.presentScene(scene)
                view.ignoresSiblingOrder = true
                
                //Debug stuff
                //view.showsFPS = true
                //view.showsNodeCount = true
                //view.showsPhysics = true;
            }
            
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.scene?.resize();
        }
    }
}


extension GameViewController: BaseGameSceneProtocol {
    @objc func presentSubmitScoreSubview(gameScene: BaseGameScene) {
        let controller = storyboard!.instantiateViewController(withIdentifier: "SubmitScoreViewController") as! SubmitScoreViewController;
        
        scene?.buttonsEnabled = false;
        controller.time = gameScene.totalTime;
        controller.trackName = self.track;
        controller.closeCallback = { self.scene?.buttonsEnabled = true;}
        
        view.addSubview(controller.view);
        self.addChild(controller);
        controller.didMove(toParent: self);
        
    }
    
    func quitToMenu() {
        _ = navigationController?.popToRootViewController(animated: false)
    }
    
    func quitToTrackSelection() {
        //set the network service delegate back to track selection controller
        //before popping view and going back to that controller
        trackSelectionViewController?.networkService?.delegate = trackSelectionViewController;
        _ = navigationController?.popViewController(animated: true)
    }
}

