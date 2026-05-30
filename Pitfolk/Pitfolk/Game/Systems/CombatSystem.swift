import SpriteKit

class CombatSystem {
    private var combatTimer: TimeInterval = 0
    private let tickInterval: TimeInterval = GameConstants.Combat.combatTickInterval
    private let aggroRadius: CGFloat = GameConstants.Combat.aggroRadius
    private let meleeRange: CGFloat  = GameConstants.Combat.meleeRange
    private let math: IsometricMath

    var isNight: Bool = false
    private let waveSystem: WaveSystem

    init(math: IsometricMath, waveSystem: WaveSystem) {
        self.math       = math
        self.waveSystem = waveSystem
    }

    // MARK: - Main Update
    func update(deltaTime: TimeInterval,
                pitfolk: [PitfolkEntity],
                enemies: [EnemyEntity],
                buildings: [BuildingEntity],
                buildingSystem: BuildingSystem) {
        combatTimer += deltaTime
        guard combatTimer >= tickInterval else { return }
        combatTimer = 0

        moveEnemies(enemies: enemies, pitfolk: pitfolk, buildings: buildings)
        resolveAttacks(pitfolk: pitfolk, enemies: enemies, buildingSystem: buildingSystem)
        movePitfolkWarriors(pitfolk: pitfolk, enemies: enemies)
    }

    // MARK: - Enemy Movement
    private func moveEnemies(enemies: [EnemyEntity], pitfolk: [PitfolkEntity], buildings: [BuildingEntity]) {
        for enemy in enemies where enemy.isAlive {
            // Find target
            let target = findEnemyTarget(enemy: enemy, pitfolk: pitfolk, buildings: buildings)
            move(enemy: enemy, toward: target, buildings: buildings)
        }
    }

    private func findEnemyTarget(enemy: EnemyEntity,
                                  pitfolk: [PitfolkEntity],
                                  buildings: [BuildingEntity]) -> CGPoint {
        let enemyPos = enemy.screenPosition

        // Building-targeting enemies prefer buildings
        if enemy.type.prioritizesBuildings {
            if let nearestBuilding = buildings.filter({ $0.isAlive }).min(by: {
                $0.node.position.distance(to: enemyPos) < $1.node.position.distance(to: enemyPos)
            }) {
                return nearestBuilding.node.position
            }
        }

        // Otherwise target nearest Pitfolk warrior first, then any Pitfolk
        let warriors = pitfolk.filter { $0.isAlive && $0.role == .warrior }
        let targets  = warriors.isEmpty ? pitfolk.filter { $0.isAlive } : warriors

        if let nearest = targets.min(by: {
            $0.node.position.distance(to: enemyPos) < $1.node.position.distance(to: enemyPos)
        }) {
            return nearest.node.position
        }

        // Head for center if no targets
        return .zero
    }

    private func move(enemy: EnemyEntity, toward target: CGPoint, buildings: [BuildingEntity]) {
        let currentPos = enemy.screenPosition
        let direction  = (target - currentPos).normalized()
        let speed      = enemy.moveSpeed * CGFloat(tickInterval)

        let newPos = currentPos + direction * speed
        enemy.screenPosition = newPos
        enemy.node.position  = newPos

        // Update tile coord
        enemy.tileCoord = math.tileCoord(for: newPos)

        // Flip sprite based on movement direction
        if direction.x < 0 { enemy.node.xScale = -abs(enemy.node.xScale) }
        else                { enemy.node.xScale =  abs(enemy.node.xScale) }
    }

    // MARK: - Attack Resolution
    private func resolveAttacks(pitfolk: [PitfolkEntity], enemies: [EnemyEntity],
                                 buildingSystem: BuildingSystem) {
        // Enemies attack Pitfolk/buildings in range
        for enemy in enemies where enemy.isAlive {
            let enemyPos = enemy.screenPosition

            // Try to attack Pitfolk in melee range
            var attacked = false
            for pf in pitfolk where pf.isAlive {
                if enemyPos.distance(to: pf.node.position) <= meleeRange {
                    let damage = enemy.damage * (isNight ? 1.1 : 1.0)
                    pf.takeDamage(damage)
                    attacked = true
                    break
                }
            }

            // If no Pitfolk in range, try buildings
            if !attacked {
                for building in buildingSystem.buildings.values where building.isAlive {
                    if enemyPos.distance(to: building.node.position) <= meleeRange * 1.5 {
                        buildingSystem.applyDamage(to: building, amount: enemy.damage * 0.7)
                        attacked = true
                        break
                    }
                }
            }
        }

        // Warriors attack enemies in range
        let defenseBonus = buildingSystem.totalDefenseBonus
        for pf in pitfolk where pf.isAlive && pf.role == .warrior {
            for enemy in enemies where enemy.isAlive {
                if pf.node.position.distance(to: enemy.screenPosition) <= aggroRadius {
                    pf.isFighting = true
                    if pf.node.position.distance(to: enemy.screenPosition) <= meleeRange {
                        let baseDamage = pf.attack * pf.attackMultiplier
                        let bonusDamage = defenseBonus * 0.05
                        enemy.takeDamage(baseDamage + bonusDamage)
                        if !enemy.isAlive {
                            pf.killCount += 1
                            waveSystem.reportEnemyKilled()
                        }
                    }
                    break
                }
            }
        }

        // Auto-combat: non-warriors fight back if attacked (cowards flee instead)
        for pf in pitfolk where pf.isAlive && pf.role != .warrior {
            let underAttack = enemies.contains { $0.isAlive &&
                $0.screenPosition.distance(to: pf.node.position) <= meleeRange }
            if underAttack {
                pf.isFighting = true
                if pf.traits.contains(.cowardly) && pf.health < pf.maxHealth * 0.4 {
                    // Flee toward center
                    let flee = pf.node.position.normalized() * -20
                    pf.node.position = pf.node.position + flee * CGFloat(tickInterval * 60)
                } else {
                    // Defend
                    if let attacker = enemies.filter({ $0.isAlive &&
                        $0.screenPosition.distance(to: pf.node.position) <= meleeRange }).first {
                        let counterDamage = pf.attack * 0.5 * pf.attackMultiplier
                        attacker.takeDamage(counterDamage)
                        if !attacker.isAlive {
                            pf.killCount += 1
                            waveSystem.reportEnemyKilled()
                        }
                    }
                }
            } else {
                pf.isFighting = false
            }
        }
    }

    // MARK: - Warrior AI
    private func movePitfolkWarriors(pitfolk: [PitfolkEntity], enemies: [EnemyEntity]) {
        let aliveEnemies = enemies.filter { $0.isAlive }
        guard !aliveEnemies.isEmpty else {
            pitfolk.filter { $0.role == .warrior }.forEach { $0.isFighting = false }
            return
        }

        for warrior in pitfolk where warrior.isAlive && warrior.role == .warrior {
            guard let nearest = aliveEnemies.min(by: {
                $0.screenPosition.distance(to: warrior.node.position) <
                $1.screenPosition.distance(to: warrior.node.position)
            }) else { continue }

            let dist = nearest.screenPosition.distance(to: warrior.node.position)
            if dist > meleeRange {
                let dir   = (nearest.screenPosition - warrior.node.position).normalized()
                let speed = GameConstants.Combat.aggroRadius * 0.8 * CGFloat(tickInterval)
                warrior.node.position = warrior.node.position + dir * speed
                warrior.tileCoord = math.tileCoord(for: warrior.node.position)
            }
            warrior.isFighting = dist <= aggroRadius
        }
    }
}
