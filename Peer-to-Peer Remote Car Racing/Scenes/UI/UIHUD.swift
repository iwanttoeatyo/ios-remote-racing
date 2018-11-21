//
//  HUDNode.swift
//  Peer-to-Peer Remote Car Racing
//
//  Created by user145437 on 11/19/18.
//  Copyright © 2018 Josh & Chris. All rights reserved.
//

import Foundation
import SpriteKit

class UIHUD : SceneRootNode {
    
    var lapLabel:SKLabelNode!;
    var timeLabel:SKLabelNode!;
    var bestLapTimeLabel:SKLabelNode!;
    var bestLapNode:SKNode!;
    var speedLabel:SKLabelNode!;
  
    init() {
        super.init(fileNamed: "UIHUD")!;
        
        lapLabel = (self.childNode(withName: "//lapLabel") as! SKLabelNode);
        timeLabel = (self.childNode(withName: "//timeLabel") as! SKLabelNode);
        
        bestLapNode = (self.childNode(withName: "//bestLap"));
        bestLapTimeLabel = (self.childNode(withName: "//bestLapLabel") as! SKLabelNode);
        bestLapNode.isHidden = true;
        speedLabel = (self.childNode(withName: "//speedLabel") as! SKLabelNode);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}