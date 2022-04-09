//
//  Enemy.swift
//  updown
//
//  Created by Willie Liwa Johnson on 4/3/22.
//

import Foundation
import SpriteKit



class Enemy {
    public let id = UUID()
    public var shape: SKShapeNode
    public var body: SKPhysicsBody {
        get {
            guard let physicsBody = shape.physicsBody else {
                shape.physicsBody = SKPhysicsBody()
                return shape.physicsBody!
            }
            return physicsBody
        }
    }
    
    public var position: CGPoint {
        get {
            return self.shape.position
        }
        set {
            self.shape.position = newValue
        }
    }
    
    public var zPosition: CGFloat {
        get {
            return self.shape.zPosition
        }
        
        set {
            self.shape.zPosition = newValue
        }
    }
    
    init(name: String, shape: SKShapeNode, color: SKColor, position: CGPoint) {
        self.shape = shape
        self.shape.name = "enemy"
        self.shape.fillColor = color
        self.shape.strokeColor = color.hueWith(saturation: 0.5, brightness: 1, alpha: 1)
        self.shape.addGlow()

        let enemyPhysicsBody = SKPhysicsBody(rectangleOf: self.shape.frame.size)
        enemyPhysicsBody.restitution = 1
        enemyPhysicsBody.friction = 0
        enemyPhysicsBody.density = 0
        enemyPhysicsBody.affectedByGravity = false
        enemyPhysicsBody.usesPreciseCollisionDetection = true
        enemyPhysicsBody.categoryBitMask = EnemyCategory
        enemyPhysicsBody.contactTestBitMask = BallContactCategory
        enemyPhysicsBody.collisionBitMask = EnemyCategory | BallCollisionCategory | WorldCategory | PlayerCategory
        self.shape.physicsBody = enemyPhysicsBody
        self.shape.position = position
    }
}
