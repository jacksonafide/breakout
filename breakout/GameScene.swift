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
let BlockBlueCategoryName = "blockBlue"
let BlockRedCategoryName = "blockRed"
let BlockGreenCategoryName = "blockGreen"
let BlockYellowCategoryName = "blockYellow"
let BlockPurpleCategoryName = "blockPurple"
let GameMessageName = "gameMessage"
let ScoreLabelName = "scoreLabel"
let PowerUpLName = "powerUpLength"
let PowerDownLName = "powerDownLength"
let PowerUpSName = "powerUpSpeed"
let PowerDownSName = "powerDownSpeed"
let PowerUpLifeName = "powerUpLife"

let BallCategory   : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let PowerUpCategory : UInt32 = 0x1 << 4
let BorderCategory : UInt32 = 0x1 << 5

class GameScene: SKScene, SKPhysicsContactDelegate {
    let scoreText = SKLabelNode(fontNamed: "Chalkduster")
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    let livesLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    var isInvul: Bool = false
    var isInvulTime: TimeInterval = 0
    
    var lives: Int = 0 {
        didSet {
            livesLabel.text = "Lives: " + String(lives)
        }
    }
    
    var score: Int = 0 {
        didSet {
            if score > 1000 {
                scoreLabel.position = CGPoint(x: (frame.width / 4) * 2 - 30, y: frame.height * 0.9)
                scoreLabel.text = String(score)
            } else {
                scoreLabel.position = CGPoint(x: (frame.width / 4) * 2 - 30, y: frame.height * 0.9)
                scoreLabel.text = String(score)
            }
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
    
    override func didMove(to view: SKView) {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.categoryBitMask = BorderCategory
        borderBody.friction = 0
        self.physicsBody = borderBody
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        scoreText.text = "Score: "
        scoreText.fontSize = 28
        scoreText.position = CGPoint(x: (frame.width / 4) - 25, y: frame.height * 0.9)
        addChild(scoreText)
        
        scoreLabel.text = String(score)
        scoreLabel.fontSize = 28
        scoreLabel.position = CGPoint(x: (frame.width / 4) * 2 - 50, y: frame.height * 0.9)
        addChild(scoreLabel)
        
        livesLabel.text = "Lives: " + String(lives)
        livesLabel.fontSize = 28
        livesLabel.position = CGPoint(x: (frame.width / 4) * 3, y: frame.height * 0.9)
        addChild(livesLabel)
        
        let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
        ball.physicsBody!.categoryBitMask = BallCategory
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory
        ball.physicsBody!.collisionBitMask = 46
        ball.physicsBody!.usesPreciseCollisionDetection = true
        
        let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        paddle.physicsBody!.contactTestBitMask = PowerUpCategory
        
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        bottom.physicsBody!.categoryBitMask = BottomCategory
        bottom.physicsBody!.usesPreciseCollisionDetection = true
        addChild(bottom)
        
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
                block.name = color
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
    
    func genPaddlePhysics(paddle: SKSpriteNode) {
        paddle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: paddle.size.width, height: paddle.size.height))
        paddle.physicsBody!.isDynamic = false
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        paddle.physicsBody!.contactTestBitMask = PowerUpCategory
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
                if isInvul == false {
                    if lives == 0 {
                        gameState.enter(GameOver.self)
                        gameWon = false
                    } else {
                        lives -= 1
                        isInvul = true
                    }
                }
            }
            
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                breakBlock(node: secondBody.node!)
                if isGameWon() {
                    gameState.enter(GameOver.self)
                    gameWon = true
                }
            }
            
            if firstBody.categoryBitMask == PaddleCategory && secondBody.categoryBitMask == PowerUpCategory {
                if secondBody.node!.name == PowerUpLName {
                    let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
                    if paddle.size.width < frame.size.width * 0.4 {
                        paddle.size.width = paddle.size.width * 1.25
                        genPaddlePhysics(paddle: paddle)
                    }
                } else if secondBody.node!.name == PowerDownLName {
                    let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
                    if paddle.size.width > 40.0 {
                        paddle.size.width = paddle.size.width * 0.75
                        genPaddlePhysics(paddle: paddle)
                    }
                } else if secondBody.node!.name == PowerUpSName {
                    let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
                    ball.physicsBody?.velocity = CGVector(dx: ball.physicsBody!.velocity.dx * 1.25, dy: ball.physicsBody!.velocity.dy * 1.25)
                } else if secondBody.node!.name == PowerDownSName {
                    let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
                    ball.physicsBody?.velocity = CGVector(dx: ball.physicsBody!.velocity.dx * 0.75, dy: ball.physicsBody!.velocity.dy * 0.75)
                } else if secondBody.node!.name == PowerUpLifeName {
                    lives += 1
                }
                breakObject(node: secondBody.node!)
            }
        }
    }
    
    func choosePowerUp(number: Int, node: SKNode) {
        switch number {
        case 1...22:
            generatePowerUp(node: node, imageName: "powerUpLength", name: PowerUpLName)
        case 23...45:
            generatePowerUp(node: node, imageName: "powerDownLength", name: PowerDownLName)
        case 46...66:
            generatePowerUp(node: node, imageName: "powerUpSpeed", name: PowerUpSName)
        case 67...90:
            generatePowerUp(node: node, imageName: "powerDownSpeed", name: PowerDownSName)
        case 91...100:
            generatePowerUp(node: node, imageName: "powerUpLife", name: PowerUpLifeName)
        default:
            break
        }
    }
    
    func generatePowerUp(node: SKNode, imageName: String, name: String) {
        let powerUp = SKSpriteNode(imageNamed: imageName)
        powerUp.scale(to: CGSize(width: powerUp.size.width * 1.35, height: powerUp.size.height * 1.35))
        powerUp.name = name
        powerUp.position = node.position
        powerUp.zPosition = 3
        powerUp.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: powerUp.size.width, height: powerUp.size.height))
        powerUp.physicsBody?.allowsRotation = false
        powerUp.physicsBody?.friction = 0.0
        powerUp.physicsBody?.categoryBitMask = PowerUpCategory
        powerUp.physicsBody?.collisionBitMask = 8
        powerUp.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: -2.0))
        powerUp.physicsBody?.velocity = CGVector(dx: 0.0, dy: -500.0)
        addChild(powerUp)
    }

    func chance(percent: Int) -> Bool {
        let random = Int.random(in: 0...100)
        if random < percent {
            return true
        } else {
            return false
        }
    }
    
    func breakBlock(node: SKNode) {
        score += 100
        if chance(percent: 10) {
            choosePowerUp(number: Int.random(in: 1...100), node: node)
        }
        node.removeFromParent()
    }
    
    func breakObject(node: SKNode) {
        node.removeFromParent()
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        let listOfBlocks = [BlockBlueCategoryName, BlockRedCategoryName, BlockGreenCategoryName, BlockYellowCategoryName, BlockPurpleCategoryName]
        for block in listOfBlocks {
            self.enumerateChildNodes(withName: block) {
                node, stop in
                numberOfBricks = numberOfBricks + 1
            }
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
        if isInvul == true {
            isInvulTime += currentTime
        }
        if isInvulTime > 3 {
            isInvul = false
            isInvulTime = 0
        }
        gameState.update(deltaTime: currentTime)
    }
}
