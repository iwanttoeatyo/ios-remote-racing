/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
import GameplayKit

class GameOverlayState: GKState {
  
unowned let gameScene: BaseGameScene;
  
  var overlay: SceneOverlay!
  var overlaySceneFileName: String { fatalError("Unimplemented overlaySceneName") }
  
  init(gameScene: BaseGameScene) {
    self.gameScene = gameScene
    super.init()
    
    overlay = SceneOverlay(overlaySceneFileName: overlaySceneFileName, zPosition: 5)
    
    //Hide the overlay buttons for display
    if gameScene.gameMode == .DISPLAY {
        overlay.contentNode.childNode(withName: ".//buttons")?.isHidden = true;
    } else {
        //If this function runs the buttons will unhide
        //Turns the buttons into button nodes that are touchable with textures
        ButtonNode.parseButtonInNode(containerNode: overlay.contentNode)
    }
  }
  
  override func didEnter(from previousState: GKState?) {
    super.didEnter(from: previousState)
    //Disabled inputControl so it cant be used when game is paused
    gameScene.inputControl.disabled = true;
    gameScene.isPaused = true
    gameScene.overlay = overlay
  }
  
  override func willExit(to nextState: GKState) {
    super.willExit(to: nextState)
    gameScene.inputControl.disabled = false;
    gameScene.isPaused = false
    gameScene.overlay = nil
  }
}
