//
//  GameScene.swift
//  updown
//
//  Created by Willie Liwa Johnson on 3/18/22.
//

import SpriteKit
import GameplayKit

let PlayerCategory: UInt32 = 1 << 1
let EnemyCategory: UInt32 = 1 << 2
let BallCollisionCategory: UInt32 = 1 << 3
let BallContactCategory: UInt32 = 1 << 4
let WorldCategory: UInt32 = 1 << 5

class GameScene: SKScene {
    private let goalLine: CGFloat = 30.0
    private let playerYPosition: CGFloat = 50.0
    
    private var ball = SKShapeNode()
    private var player = SKShapeNode()
//    private var enemyScoreLabel = SKLabelNode()
//    private var playerScoreLabel = SKLabelNode()

    private var enemies = [Int: SKShapeNode]()
    private var currentEnemyIndex = 0
    
    private var enemyScore = 0
    private var playerScore = 0
    
    private var dragDistance: CGVector?
    
    private var playerIsMoving: Bool = false
    

    override func didMove(to view: SKView) {
        super.didMove(to: view)
//        enemyScoreLabel = childNode(withName: "enemyScoreLabel") as! SKLabelNode
//        playerScoreLabel = childNode(withName: "playerScoreLabel") as! SKLabelNode
//
        createWorld()
        createBall()
        createPlayer()
        createEnemy(size: CGSize(width: size.width, height: size.width))
        startGame()
    }


    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        ball.childNode(withName: "ball")!.position = .zero
        if !self.frame.contains(ball.position) {
            var nearestSide: CGPoint = self.frame.left
            var diffToBall = CGVector.zero
            for side in [frame.left, frame.right, frame.top, frame.bottom] {
                let currentDiff = CGVector(point: side) - CGVector(point: ball.position)
                let prevDiff = CGVector(point: nearestSide) - CGVector(point: ball.position)
                if currentDiff.length() < prevDiff.length() {
                    nearestSide = side
                    diffToBall = currentDiff
                }
            }
            ball.position = (nearestSide / 2) - (CGPoint(vector: diffToBall))
            ball.physicsBody?.velocity *= -0.8
        }
    }
}

// MARK: - Private Methods
private extension GameScene {
    func createWorld() {
        let border  = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 1
        physicsBody = border
        physicsBody!.categoryBitMask = WorldCategory
        physicsBody!.collisionBitMask = WorldCategory
        physicsBody!.usesPreciseCollisionDetection = true
        physicsWorld.contactDelegate = self
    }
    
    func createBall() {
        let ballSize = 15
        ball = SKShapeNode(rectOf: CGSize(width: ballSize, height: ballSize))
        ball.fillColor = .black
        ball.name = "ballShape"
        ball.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: ballSize, height: ballSize))
        ball.physicsBody!.isDynamic = true
        ball.physicsBody!.affectedByGravity = true
//        ball.physicsBody!.pinned = true
        ball.physicsBody!.collisionBitMask = WorldCategory | EnemyCategory | PlayerCategory
        ball.physicsBody!.contactTestBitMask = 0
        ball.physicsBody!.categoryBitMask = BallCollisionCategory
        ball.physicsBody!.usesPreciseCollisionDetection = true
        ball.physicsBody!.restitution = 1
        ball.physicsBody!.friction = 0
        
        let contactNode = SKShapeNode(circleOfRadius: 20)
        contactNode.name = "ball"
        contactNode.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0)
        contactNode.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        contactNode.physicsBody!.categoryBitMask = BallContactCategory
        contactNode.physicsBody!.contactTestBitMask = PlayerCategory | EnemyCategory
        contactNode.physicsBody!.collisionBitMask = 0
        contactNode.physicsBody!.isDynamic = false
        contactNode.physicsBody!.density = 0
//        contactNode.physicsBody!.pinned = true
        contactNode.physicsBody!.usesPreciseCollisionDetection = true
        ball.addChild(contactNode)
        
        ball.position = self.frame.bottom - CGPoint(x: 0, y: ball.frame.size.height * 4)
        addChild(ball)
    }
    
    func createPlayer() {
        player = SKShapeNode(rectOf: CGSize(width: 100, height: 15))
        player.name = "player"
        player.fillColor = .black
        

        let playerPhysicsBody = SKPhysicsBody(rectangleOf: player.frame.size)
        playerPhysicsBody.restitution = 2
        playerPhysicsBody.friction = 0
        playerPhysicsBody.isDynamic = false
        playerPhysicsBody.affectedByGravity = false
        playerPhysicsBody.usesPreciseCollisionDetection = true
        playerPhysicsBody.categoryBitMask = PlayerCategory
        playerPhysicsBody.collisionBitMask = WorldCategory | BallCollisionCategory | EnemyCategory
        playerPhysicsBody.contactTestBitMask = BallContactCategory
        player.physicsBody = playerPhysicsBody
        player.position.y = (-self.frame.height/2) + playerYPosition
        addChild(player)
    }
    

    
    func createEnemy(size: CGSize, position: CGPoint = .zero, color: SKColor = .red) {
        let enemy = SKShapeNode(rectOf: size)
        enemy.name = "enemy"
        enemy.fillColor = color
        let enemyPhysicsBody = SKPhysicsBody(rectangleOf: enemy.frame.size)
        enemyPhysicsBody.restitution = 1
        enemyPhysicsBody.friction = 0
        enemyPhysicsBody.affectedByGravity = false
        enemyPhysicsBody.usesPreciseCollisionDetection = true
        enemyPhysicsBody.categoryBitMask = EnemyCategory
        enemyPhysicsBody.contactTestBitMask = BallContactCategory
        enemyPhysicsBody.collisionBitMask = EnemyCategory
        enemy.physicsBody = enemyPhysicsBody
        enemy.zPosition = CGFloat(currentEnemyIndex)
        enemy.position = position
        enemies[currentEnemyIndex] = enemy
        addChild(enemy)
        currentEnemyIndex += 1
    }
    
    func startGame() {
        enemyScore = 0
        playerScore = 0
        updateScores()
        randomStart()
    }
    
    func addPoint(winner: SKShapeNode) {
        if winner == player {
            playerScore += 1
        }
        
        updateScores()
        let bvx = ball.physicsBody!.velocity.dx
        let bvy = ball.physicsBody!.velocity.dy
        ball.physicsBody?.velocity = CGVector(
            dx: Bool.random() ? -bvx * 0.5 : bvx * 0.5,
            dy: Bool.random() ? -bvy * 0.5 : bvy * 0.5
        )


        if enemies.count == 0 {
            currentEnemyIndex = 0
            ball.position = player.position
            for _ in 0...playerScore {
                let sizeFactor = self.size.width * 0.8 / CGFloat(playerScore + 1)
                let size = CGSize(width: sizeFactor, height: sizeFactor)
                let position = CGPoint(x: CGFloat.random(in: -self.size.width/2...self.size.width/2), y: CGFloat.random(in: -self.size.height/4...self.size.height/2))
                createEnemy(size: size, position: position, color: .random)
            }
            
        }
//        randomStart()
    }
    
    func randomStart() {
        ball.position = player.position
        ball.physicsBody?.velocity =  CGVector.zero
        randomVelocity()
    }
    
    func randomVelocity() {
        let randomX = Bool.random() ? Int.random(in: -10...5) : Int.random(in: 5...10)
        let randomY = Bool.random() ? 10 : -10
        ball.physicsBody?.applyImpulse(CGVector(dx: randomX, dy: randomY))
    }
    
    private func updateScores() {
        return
//        enemyScoreLabel.text = "\(enemyScore)"
//        playerScoreLabel.text = "\(playerScore)"
    }
    
}
 

// MARK: - Controls
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        for touch in touches {
            if self.ball.physicsBody?.velocity == CGVector.zero {
                randomVelocity()
            }
            let location = touch.location(in: self)
            player.position = location
            playerIsMoving = true
            player.fillColor = ball.fillColor
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            let location = touch.location(in: self) + CGPoint(x: 0, y: 30)
            player.zRotation = lerp(player.zRotation, CGVector(dx: location.y - player.position.y, dy: location.x - player.position.x).normalized().angle / 2, 0.05)
            player.position = location
//            player.position.y = player.position.y.clamped(to: -self.size.height...0)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        player.fillColor = .red
        playerIsMoving = false
    }
}

// MARK: - Collision Detection
extension GameScene: SKPhysicsContactDelegate {
    func onContact(edge: SKNode, other: SKNode, position: CGPoint) {
        if self.frame.contains(position) {
            other.position = position + other.frame.size

        } else {
            other.position = .zero
        }
    }
    
    func onContact(enemy: SKNode, other: SKNode, position: CGPoint) {
        switch(other.name) {
        case "ball":
            let ballCopy = ball.copy() as! SKShapeNode
            ballCopy.fillColor = .systemRed
            ballCopy.name = "enemyBall"
            ballCopy.physicsBody!.collisionBitMask = enemy.physicsBody!.collisionBitMask
            guard let index = enemies.index(forKey: Int(enemy.zPosition)) else { return }
            enemies.remove(at: index)
            enemy.removeFromParent()
//            addChild(ballCopy)
            self.addPoint(winner: self.player)
        case "edge":
            if self.frame.contains(position) {
                enemy.position = position + enemy.frame.size
            } else {
                enemy.position = .zero
            }
        default:
            return
        }
        
    }
    
    func onContact(player: SKNode, other: SKNode, position: CGPoint) {
        switch(other.name) {
        case "ball":
            if !playerIsMoving {
                ball.parent!.physicsBody?.velocity = CGVector.zero
            }
        case "enemyBall":
            if playerIsMoving {
//                self.addPoint(winner: enemy)
                other.removeFromParent()
            }
        default:
            return
        }
        
    }
    
    func onContact(ball: SKNode, other: SKNode, position: CGPoint) {
        switch(other.name) {
     
        default:
            return
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        print(nodeA.name)
        print(nodeB.name)
        switch(nodeA.name) {
        case "enemy":
            onContact(enemy: nodeA, other: nodeB, position: contact.contactPoint)
        case "player":
            onContact(player: nodeA, other: nodeB, position: contact.contactPoint)
        case "ball":
            onContact(ball: nodeA, other: nodeB, position: contact.contactPoint)
        case "edge":
            onContact(edge: nodeA, other: nodeB, position: contact.contactPoint)
        default:
            return
        }
        
    }
}
