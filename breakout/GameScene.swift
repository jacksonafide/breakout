//
//  GameScene.swift
//  breakout
//
//  Created by Jacek Chojnacki on 04/08/2020.
//  Copyright © 2020 Jacek Chojnacki. All rights reserved.
//

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let GameMessageName = "gameMessage"
let ScoreLabelName = "scoreLabel"

let BallCategory   : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4

class GameScene: SKScene, SKPhysicsContactDelegate {
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: " + String(score)
        }
    }
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [WaitingForTap(scene: self), Playing(scene: self), GameOver(scene: self)])
    
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNode(withName: GameMessageName) as! SKSpriteNode
            let textureName = gameWon ? "won" : "lost"
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture), SKAction.scale(to: 1.0, duration: 0.25)])
            
            gameOver.run(actionSequence)
        }
    }
    
    override func didMove(to view: SKView) {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.categoryBitMask = BorderCategory
        borderBody.friction = 0
        self.physicsBody = borderBody
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        scoreLabel.text = "Score: " + String(score)
        scoreLabel.position = CGPoint(x: frame.midX, y: 806)
        addChild(scoreLabel)
        
        let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
        ball.physicsBody!.categoryBitMask = BallCategory
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory
        
        let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)
        bottom.physicsBody!.categoryBitMask = BottomCategory
        
        let numberOfRows = Int.random(in: 10...15)
        let blockWidth = SKSpriteNode(imageNamed: "blockBlue").size.width
        let blockHeight = SKSpriteNode(imageNamed: "blockBlue").size.height
        
        for r in 0..<numberOfRows {
            let numberOfBlocks = Int.random(in: 1...7)
            let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
            let xOffset = (frame.size.width - totalBlocksWidth) / 2
            let color = getColor()
            for i in 0..<numberOfBlocks {
                let block = SKSpriteNode(imageNamed: color)
                block.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * blockWidth, y: frame.height * 0.85 - blockHeight * CGFloat(r))
                block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
                block.physicsBody?.allowsRotation = false
                block.physicsBody?.friction = 0.0
                block.physicsBody?.affectedByGravity = false
                block.physicsBody?.isDynamic = false
                block.name = BlockCategoryName
                block.physicsBody?.categoryBitMask = BlockCategory
                block.zPosition = 2
                addChild(block)
            }
        }
        
        let gameMessage = SKSpriteNode(imageNamed: "tapToPlay")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        gameMessage.zPosition = 3
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        gameState.enter(WaitingForTap.self)
    }
    
    func getColor() -> String {
        let randomNumber = Int.random(in: 1...100)
        if randomNumber <= 20 {
            return "blockBlue"
        } else if randomNumber >= 21 && randomNumber <= 40{
            return "blockRed"
        } else if randomNumber >= 41 && randomNumber <= 60{
            return "blockGreen"
        } else if randomNumber >= 61 && randomNumber <= 80 {
            return "blockYellow"
        } else {
            return "blockPurple"
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameState.currentState is Playing {
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
                gameState.enter(GameOver.self)
                gameWon = false
            }
            
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                breakBlock(node: secondBody.node!)
                if isGameWon() {
                    gameState.enter(GameOver.self)
                    gameWon = true
                }
            }
        }
    }
    
    func breakBlock(node: SKNode) {
        score += 100
        node.removeFromParent()
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodes(withName: BlockCategoryName) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            
        case is Playing:
            break
            
        case is GameOver:
            let newScene = GameScene(fileNamed: "GameScene")
            newScene?.scaleMode = .resizeFill
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
        default:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        let prevTouchLocation = touch!.previousLocation(in: self)
        
        let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
        
        var paddleX = paddle.position.x + (touchLocation.x - prevTouchLocation.x)
        paddleX = max(paddleX, paddle.size.width / 2)
        paddleX = min(paddleX, size.width - paddle.size.width / 2)
        
        paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
}
