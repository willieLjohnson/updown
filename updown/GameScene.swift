//
//  GameScene.swift
//  updown
//
//  Created by Willie Liwa Johnson on 3/18/22.
//

import SpriteKit
import Foundation

let NoCategory: UInt32 = 1 << 0
let PlayerCategory: UInt32 = 1 << 1
let EnemyCategory: UInt32 = 1 << 2
let BallCollisionCategory: UInt32 = 1 << 3
let BallContactCategory: UInt32 = 1 << 4
let WorldCategory: UInt32 = 1 << 5


class GameScene: SKScene {
    private var ball = SKShapeNode()
    private var player = SKShapeNode()
    private var scoreLabel = SKLabelNode()
    private var borderLine = SKShapeNode()

    private var enemies = [Int: Enemy]()
    private var currentEnemyIndex = 0
    
    private var sparksEmitter = SKEmitterNode()
    
    private var score = 0
    
    private var dragDistance: CGVector?
    private var playerIsMoving: Bool = false
    
    private let bounceSound = Sound(frequency: 1046 / 5, waveform: Oscillator.sine)
    private let hitSound = Sound(frequency: 1046 / 4.8, waveform: Oscillator.sine)
    private let playerBounceSound = Sound(frequency: 1046 / 4.5, waveform: Oscillator.triangle)
    private var soundQueue = [Sound]()
    
    private var worldSize = CGSize()
    private var worldFrame = CGRect()
    
    private var scoreLabelAttr = [
        NSAttributedString.Key.strokeColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.5),
        NSAttributedString.Key.foregroundColor: UIColor.black,
        NSAttributedString.Key.strokeWidth: -0.5,
        NSAttributedString.Key.font: UIFont(name: "Menlo-Bold", size: 150)!,
    ] as [NSAttributedString.Key : Any]
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        createWorld()
        createBall()
        createPlayer()
        createEnemy(size: CGSize(width: size.width, height: size.width))
        startGame()
        
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center
        scoreLabelAttr[NSAttributedString.Key.paragraphStyle] = centerStyle
    
        scoreLabel = childNode(withName: "scoreLabel") as! SKLabelNode
        scoreLabel.attributedText = NSMutableAttributedString(string: "\(score)", attributes: scoreLabelAttr)
        
        sparksEmitter = SKEmitterNode(fileNamed: "Sparks.sks")!
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(gameMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }


    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        ball.childNode(withName: "ball")!.position = .zero
        
        if !worldFrame.contains(ball.position) {
            var nearestSide: CGPoint = worldFrame.left
            var diffToBall = CGVector.zero
            for side in [frame.left, frame.right, frame.top, frame.bottom] {
                let currentDiff = CGVector(point: side) - CGVector(point: ball.position)
                let prevDiff = CGVector(point: nearestSide) - CGVector(point: ball.position)
                if currentDiff.length() < prevDiff.length() {
                    nearestSide = side
                    diffToBall = currentDiff
                }
            }
            ball.position = (nearestSide / 4) + (CGPoint(vector: diffToBall))
            ball.physicsBody?.velocity *= -1
        }
        
        if Synth.shared.volume > 0 {
            Synth.shared.volume *= 0.6
        }
        
        
        if enemies.count == 0 {
            currentEnemyIndex = 0
            ball.position = player.position
            for _ in 0...score {
                let sizeFactor = worldSize.width * 0.8 / CGFloat(score + 1)
                let size = CGSize(width: sizeFactor, height: sizeFactor)
                let position = CGPoint(x: CGFloat.random(in: -worldSize.width/2...worldSize.width/2), y: CGFloat.random(in: -worldSize.height/4...worldSize.height/2))

                createEnemy(size: size, position: position, color: .randomHue(saturation: 1, brightness: 1, alpha: 1))
            }
            randomStart()
            vibrate(.success)
            playSound(bounceSound)
        }
    }
}

// MARK: - Private Methods
private extension GameScene {
    @objc func gameMovedToBackground() {
        Synth.shared.volume = 0
    }
    
    func createWorld() {
        worldSize = size * 0.92
        worldFrame = CGRect(origin: CGPoint(x: -worldSize.width / 2, y: -worldSize.height / 2), size: worldSize)
        self.name = "world"
        
        self.physicsWorld.gravity = self.physicsWorld.gravity / 4
        borderLine = SKShapeNode(rect: worldFrame, cornerRadius: 10)
        borderLine.strokeColor = SKColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        borderLine.lineWidth = 2
        borderLine.addGlow()
        
        let border = SKPhysicsBody(edgeLoopFrom: worldFrame)
        
        border.friction = 0
        border.restitution = 1
        physicsBody = border
        physicsBody!.categoryBitMask = WorldCategory
        physicsBody!.collisionBitMask = WorldCategory
        physicsBody!.contactTestBitMask = BallCollisionCategory | BallContactCategory
        physicsBody!.usesPreciseCollisionDetection = true
        physicsWorld.contactDelegate = self
        addChild(borderLine)

    }
    
    func createBall() {
        let ballSize = 17
        ball = SKShapeNode(rectOf: CGSize(width: ballSize, height: ballSize))
        ball.fillColor = .black
        ball.strokeColor = .white
        ball.name = "ball"
        ball.addGlow()
        
        ball.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: ballSize, height: ballSize))
        ball.physicsBody!.isDynamic = true
        ball.physicsBody!.affectedByGravity = true
        ball.physicsBody!.collisionBitMask = WorldCategory | EnemyCategory | PlayerCategory
        ball.physicsBody!.contactTestBitMask = BallCollisionCategory
        ball.physicsBody!.categoryBitMask = BallCollisionCategory
        ball.physicsBody!.usesPreciseCollisionDetection = true
        ball.physicsBody!.restitution = 1
        ball.physicsBody!.friction = 0
        ball.physicsBody!.angularDamping = 0.7
        
        // TODO: - Turn the circle radius of the contact node into an upgradable stat.
        let contactNode = SKShapeNode(circleOfRadius: 20)
        contactNode.name = "ball"
        contactNode.addGlow()
        contactNode.fillColor = .clear
        contactNode.strokeColor = .white
        contactNode.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        contactNode.physicsBody!.categoryBitMask = BallContactCategory
        contactNode.physicsBody!.contactTestBitMask = PlayerCategory | EnemyCategory
        contactNode.physicsBody!.collisionBitMask = NoCategory
        contactNode.physicsBody!.isDynamic = false
        contactNode.physicsBody!.density = 0
        contactNode.physicsBody!.usesPreciseCollisionDetection = true
        ball.addChild(contactNode)
        
        ball.position = worldFrame.bottom - CGPoint(x: 0, y: ball.frame.size.height * 4)
        addChild(ball)

    }
    
    func createPlayer() {
        player = SKShapeNode(rectOf: CGSize(width: 115, height: 15), cornerRadius: 2.5)
        player.name = "player"
        player.fillColor = .white
        player.strokeColor = .white

        
        let playerPhysicsBody = SKPhysicsBody(rectangleOf: player.frame.size)
        playerPhysicsBody.restitution = 2
        playerPhysicsBody.friction = 0
        playerPhysicsBody.isDynamic = false
        playerPhysicsBody.affectedByGravity = false
        playerPhysicsBody.usesPreciseCollisionDetection = true
        playerPhysicsBody.categoryBitMask = PlayerCategory
        playerPhysicsBody.collisionBitMask = WorldCategory | BallCollisionCategory | EnemyCategory
        playerPhysicsBody.contactTestBitMask = BallContactCategory | BallCollisionCategory
        player.physicsBody = playerPhysicsBody
        player.position.y = (-worldFrame.height/2) + 50
        addChild(player)
    }
    

    // TODO: - Create new enemy types or make enemy shape easier to adjust.
    func createEnemy(size: CGSize, position: CGPoint = .zero, color: SKColor = .red) {
        let numberOfSides = Int(Double((score + 100) / 25).rounded())
        let enemy = Enemy(name: "enemy", shape: SKShapeNode(polygonOfRadius: size.width / 2, vertices: numberOfSides), color: color, position: position)
        enemies[currentEnemyIndex] = enemy
        enemy.zPosition = CGFloat(currentEnemyIndex)
        addChild(enemy.shape)
        currentEnemyIndex += 1
    }
    
    func startGame() {
        score = 0
        updateScores()
        randomStart()
    }
    
    func addPoint() {
        score += 1
        updateScores()
        let bvx = ball.physicsBody!.velocity.dx
        let bvy = ball.physicsBody!.velocity.dy
        ball.physicsBody?.velocity = CGVector(
            dx: Bool.random() ? -bvx  : bvx,
            dy: Bool.random() ? -bvy : bvy
        ) 
        vibrate(.heavy)
    }
    
    func randomStart() {
        ball.position = player.position
        ball.physicsBody?.velocity =  CGVector.zero
        randomVelocity(node: ball)
    }
    
    func randomVelocity(node: SKShapeNode) {
        let randomX = Bool.random() ? Int.random(in: -10...5) : Int.random(in: 5...10)
        let randomY = Bool.random() ? 10 : -10
        node.physicsBody?.applyImpulse(CGVector(dx: randomX, dy: randomY))
    }
    
    private func updateScores() {
        scoreLabel.attributedText = NSMutableAttributedString(string: "\(score)", attributes: scoreLabelAttr)
        scoreLabel.run(.shake(initialPosition: .zero, duration: 0.1, amplitudeX: .random(in: 20...50), amplitudeY: .random(in: 20...50)))
    }
    
    func playSound(_ sound: Sound, volume: Float = 1) {
        Oscillator.amplitude = 1
        Synth.shared.frequency = sound.frequency
        Synth.shared.setWaveformTo(sound.waveform)
        Synth.shared.volume = volume
    }
    
}
 

// MARK: - Controls
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        for touch in touches {
            if self.ball.physicsBody?.velocity == CGVector.zero {
                randomVelocity(node: ball)
            }
            let location = touch.location(in: self)
            player.position = location
            playerIsMoving = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            let location = touch.location(in: self) + CGPoint(x: 0, y: 30)
            player.zRotation = lerp(player.zRotation, CGVector(dx: location.y - player.position.y, dy: location.x - player.position.x).normalized().angle / 4, 0.1)
            player.position = location
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
//        player.fillColor = .black
        playerIsMoving = false
    }
}

// MARK: - Collision Detection
extension GameScene: SKPhysicsContactDelegate {
    func onContact(edge: SKNode, other: SKNode, position: CGPoint) {
        if worldFrame.contains(position) {
            other.position = position + other.frame.size

        } else {
            other.position = .zero
        }
    }
    
    func onContact(enemy: SKNode, other: SKNode, position: CGPoint) {
        guard let enemy = enemy as? SKShapeNode else { return }
        let enemyColor = enemy.fillColor
        
        switch(other.name) {
        case "ball":
            enemyCollisionEffect(enemy: enemy)
            enemy.removeGlow()

            enemy.physicsBody!.categoryBitMask = 0
            enemy.physicsBody!.collisionBitMask = 0
            enemy.physicsBody!.contactTestBitMask = 0
            enemy.physicsBody!.affectedByGravity = true
            enemy.physicsBody!.velocity = ball.physicsBody!.velocity * 0.5
            enemy.physicsBody!.angularVelocity = ball.physicsBody!.velocity.dx * 0.01
            guard let index = self.enemies.index(forKey: Int(enemy.zPosition)) else { return }
            enemies.remove(at: index)
            enemy.run(.sequence([.wait(forDuration: 5), .run({
                enemy.removeFromParent()
            })]))
            
            
            guard let ball = other as? SKShapeNode else { return }
            guard let parent = ball.parent as? SKShapeNode else { return }


            scoreLabelAttr[NSAttributedString.Key.strokeColor] = enemyColor.hueWith(saturation: 0.5, brightness: 1, alpha: 0.5)
            borderLine.strokeColor = enemyColor.hueWith(saturation: 0.5, brightness: 1, alpha: 1)
            player.fillColor = enemyColor.hueWith(saturation: 1, brightness: 0.2, alpha: 0.5)
            player.strokeColor = enemyColor.hueWith(saturation: 0.5, brightness: 1, alpha: 1)

            ball.run(
                .sequence([
                    .run({
                        ball.fillColor = enemyColor.hueWith(saturation: 1, brightness: 1, alpha: 0.5)
                        parent.fillColor = enemyColor.hueWith(saturation: 1, brightness: 1, alpha: 1)
                   
                    }),
                    .wait(forDuration: 0.1),
                    .run({
                        ball.fillColor = enemyColor.hueWith(saturation: 1, brightness: 0.2, alpha: 0.5)
                        parent.fillColor = .clear
                        
                        ball.strokeColor = enemyColor.hueWith(saturation: 0.5, brightness: 1, alpha: 1)
                        parent.strokeColor = enemyColor.hueWith(saturation: 0.5, brightness: 1, alpha: 1)
                    })
            ]))
            
            enemy.fillColor = enemy.fillColor.hueWith(saturation: 1, brightness: 1, alpha: 0.2)
            enemy.strokeColor = enemy.strokeColor.hueWith(saturation: 1, brightness: 1, alpha: 0.5)
            self.addPoint()

        case "edge":
            if worldFrame.contains(position) {
                enemy.position = position + enemy.frame.size
            } else {
                enemy.position = .zero
            }
        default:
            return
        }
        
    }
    
    func onContact(player: SKNode, other: SKNode, position: CGPoint) {
        player.run(.shake(initialPosition: player.position, duration: 0.1, amplitudeX: .random(in: 5...10), amplitudeY: .random(in: 20...50)))
        switch(other.name) {
        case "ball":
            vibrate(.medium)

        case "enemyBall":
            if playerIsMoving {
                other.removeFromParent()
            }
        default:
            return
        }
        
    }
    
    func onContact(ball: SKNode, other: SKNode, position: CGPoint) {

        switch(other.name) {
        case "world":
            vibrate(.light)
            borderLine.run(.shake(initialPosition: .zero, duration: 0.1, amplitudeX: .random(in: 10...15), amplitudeY: .random(in: 10...15)))
        default:
            return
        }
        

        
    }
    
    func ballCollisionEffect(position: CGPoint) {
        guard let sparksEmitter = sparksEmitter.copy() as? SKEmitterNode else { return }
        
//        sparksEmitter.particleSize = CGSize(width: 5, height: 5)
        sparksEmitter.position = position
//        sparksEmitter.particleScale = 1
        sparksEmitter.zRotation = ball.position.angle(to: position)
//        sparksEmitter.particleLifetime = 1
//        sparksEmitter.particleLifetimeRange = 6
//        spark
        sparksEmitter.run(.sequence([.wait(forDuration: 0.5), .run({
            sparksEmitter.removeFromParent()
        })]))
        sparksEmitter.particleColor = ball.strokeColor
        sparksEmitter.particleColorSequence = nil

        addChild(sparksEmitter)
    }
    
    func enemyCollisionEffect(enemy: SKShapeNode) {
        guard let sparksEmitter = sparksEmitter.copy() as? SKEmitterNode else { return }
        
        sparksEmitter.particleSize = enemy.frame.size * 2
        sparksEmitter.position = enemy.position
//        sparksEmitter.particleScale = 0.4
        sparksEmitter.zRotation = ball.position.angle(to: enemy.position)
        sparksEmitter.run(.sequence([.wait(forDuration: 0.5), .run({
            sparksEmitter.removeFromParent()
        })]))
        sparksEmitter.particleColor = enemy.fillColor
        sparksEmitter.particleColorSequence = nil

        addChild(sparksEmitter)
    }
    
    func onContact(world: SKNode, other: SKNode, position: CGPoint) {
        switch(other.name) {
        case "ball":
            vibrate(.light)

            borderLine.run(.shake(initialPosition: .zero, duration: 0.1, amplitudeX: .random(in: 5...10), amplitudeY: .random(in: 0...10)))
            
        case "player":
            player.run(.shake(initialPosition: player.position, duration: 0.1, amplitudeX: .random(in: 5...10), amplitudeY: .random(in: 20...50)))
        default:
            return
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
    
        
        vibrate()
        playSound(bounceSound, volume: 1)
        
        
        if nodeA.name == "ball" || nodeB.name == "ball" {
            ballCollisionEffect(position: contact.contactPoint)
        }
        
//        print(nodeA.name)
//        print(nodeB.name)
//
        switch(nodeA.name) {
        case "enemy":
            onContact(enemy: nodeA, other: nodeB, position: contact.contactPoint)
        case "player":
            onContact(player: nodeA, other: nodeB, position: contact.contactPoint)
        case "ball":
            onContact(ball: nodeA, other: nodeB, position: contact.contactPoint)
        case "edge":
            onContact(edge: nodeA, other: nodeB, position: contact.contactPoint)
        case "world":
            onContact(world: nodeA, other: nodeB, position: contact.contactPoint)
        default:
            return
        }
    }
}

