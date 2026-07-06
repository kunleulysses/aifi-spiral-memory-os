import AIFiCreatureCore
import SpriteKit

final class CreatureScene: SKScene {
    private enum PixelSpecies {
        case foxKit
        case moonCat
        case orchardBunny
        case emberDragon
    }

    private let tile: CGFloat = 10
    private let spritePixel: CGFloat = 5.5
    private var petState: PetState

    init(size: CGSize, state: PetState) {
        self.petState = state
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1)
    }

    required init?(coder: NSCoder) {
        self.petState = PetState()
        super.init(coder: coder)
    }

    static func makeScene(state: PetState) -> CreatureScene {
        let scene = CreatureScene(size: CGSize(width: 900, height: 560), state: state)
        scene.configure()
        return scene
    }

    private func configure() {
        removeAllChildren()
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        drawTextureRoom()
        drawRoomState()
        drawCreature()
    }

    private func drawTextureRoom() {
        let texture = SKTexture(imageNamed: "room_observatory")
        texture.filteringMode = .nearest
        let node = SKSpriteNode(texture: texture)
        node.size = CGSize(width: 880, height: 552)
        node.position = .zero
        node.zPosition = 1
        addChild(node)

        let vignette = SKShapeNode(rectOf: CGSize(width: 880, height: 552))
        vignette.fillColor = .clear
        vignette.strokeColor = outline(alpha: 1)
        vignette.lineWidth = 8
        vignette.zPosition = 30
        vignette.isAntialiased = false
        addChild(vignette)
    }

    private func drawRoom() {
        tileRect(x: -44, y: -27, width: 88, height: 54, color: outline(alpha: 1), z: 0)
        tileRect(x: -43, y: -26, width: 86, height: 52, color: wallColor(0), z: 1)

        for x in -42...42 {
            let shade = x.isMultiple(of: 2) ? CGFloat(0.06) : CGFloat(-0.03)
            tileRect(x: x, y: 4, width: 1, height: 20, color: wallColor(shade), z: 2)
        }

        for y in -25...4 {
            for x in -42...42 {
                let checker = (x + y).isMultiple(of: 2)
                tileRect(x: x, y: y, width: 1, height: 1, color: floorColor(checker ? 0.05 : -0.04), z: 3)
            }
        }

        for x in stride(from: -40, through: 40, by: 5) {
            tileRect(x: x, y: -25, width: 1, height: 30, color: outline(alpha: 0.10), z: 4)
        }
        for y in stride(from: -22, through: 2, by: 4) {
            tileRect(x: -42, y: y, width: 84, height: 1, color: outline(alpha: 0.12), z: 4)
        }

        tileRect(x: -38, y: 15, width: 13, height: 7, color: outline(alpha: 0.95), z: 7)
        tileRect(x: -37, y: 16, width: 11, height: 5, color: SKColor(red: 0.35, green: 0.80, blue: 0.92, alpha: 1), z: 8)
        tileRect(x: -36, y: 19, width: 10, height: 1, color: SKColor.white.withAlphaComponent(0.45), z: 9)

        tileRect(x: 23, y: 14, width: 13, height: 8, color: outline(alpha: 0.95), z: 7)
        tileRect(x: 24, y: 15, width: 11, height: 6, color: SKColor(red: 0.21, green: 0.24, blue: 0.36, alpha: 1), z: 8)
        tileRect(x: 25, y: 18, width: 9, height: 1, color: SKColor(red: 0.60, green: 0.97, blue: 0.88, alpha: 1), z: 9)

        tileRect(x: -40, y: -24, width: 80, height: 5, color: SKColor(red: 0.14, green: 0.21, blue: 0.26, alpha: 1), z: 6)
        tileRect(x: -37, y: -20, width: 22, height: 6, color: SKColor(red: 0.12, green: 0.17, blue: 0.22, alpha: 1), z: 7)
        tileRect(x: -36, y: -19, width: 20, height: 4, color: SKColor(red: 0.34, green: 0.45, blue: 0.46, alpha: 1), z: 8)
        tileRect(x: -33, y: -18, width: 14, height: 2, color: SKColor(red: 0.86, green: 0.74, blue: 0.45, alpha: 1), z: 9)
        tileRect(x: 22, y: -20, width: 14, height: 3, color: SKColor(red: 0.26, green: 0.16, blue: 0.10, alpha: 1), z: 8)
        tileRect(x: 24, y: -17, width: 10, height: 2, color: SKColor(red: 0.83, green: 0.68, blue: 0.38, alpha: 1), z: 9)
        tileRect(x: 27, y: -15, width: 4, height: 2, color: SKColor(red: 0.25, green: 0.72, blue: 0.45, alpha: 1), z: 10)
    }

    private func drawRoomState() {
        let plantCount = Int((petState.roomGenome.plantLife * 6).rounded())
        for index in 0..<plantCount {
            let x = -37 + index * 6
            tileRect(x: x, y: -22, width: 4, height: 2, color: SKColor(red: 0.30, green: 0.18, blue: 0.12, alpha: 1), z: 16)
            tileRect(x: x + 1, y: -20, width: 1, height: 5, color: SKColor(red: 0.10, green: 0.42, blue: 0.22, alpha: 1), z: 17)
            tileRect(x: x - 1, y: -17, width: 3, height: 1, color: SKColor(red: 0.38, green: 0.78, blue: 0.36, alpha: 1), z: 18)
            tileRect(x: x + 2, y: -16, width: 3, height: 1, color: SKColor(red: 0.27, green: 0.66, blue: 0.42, alpha: 1), z: 18)
        }

        if petState.roomGenome.hiddenDoorProgress > 0.18 {
            let alpha = CGFloat(0.30 + petState.roomGenome.hiddenDoorProgress * 0.55)
            tileRect(x: 31, y: -9, width: 8, height: 14, color: outline(alpha: alpha), z: 11)
            tileRect(x: 32, y: -7, width: 6, height: 10, color: SKColor(red: 0.42, green: 0.92, blue: 0.86, alpha: alpha), z: 12)
            tileRect(x: 36, y: -2, width: 1, height: 1, color: SKColor(red: 1.0, green: 0.82, blue: 0.30, alpha: alpha), z: 13)
        }

        for (index, crystal) in petState.memoryCrystals.prefix(7).enumerated() {
            let x = -4 + index * 3
            let color = crystal.valence >= 0
                ? SKColor(red: 0.18, green: 0.94, blue: 0.92, alpha: 1)
                : SKColor(red: 0.78, green: 0.34, blue: 0.94, alpha: 1)
            tileRect(x: x, y: 14, width: 2, height: 3, color: outline(alpha: 0.95), z: 18)
            tileRect(x: x, y: 15, width: 2, height: 1, color: color, z: 19)
            tileRect(x: x + 1, y: 16, width: 1, height: 1, color: .white, z: 20)
        }

        let clutter = Int((petState.roomGenome.clutter * 7).rounded())
        for index in 0..<clutter {
            tileRect(
                x: 19 + index * 3,
                y: -23 + (index % 4),
                width: 2,
                height: 2,
                color: SKColor(red: 0.77, green: 0.38, blue: 0.28, alpha: 1),
                z: 18
            )
        }
    }

    private func drawCreature() {
        let species = resolvedSpecies()
        let container = SKNode()
        container.position = CGPoint(x: -18, y: -96 + CGFloat(petState.livingGenome.posture) * 18)
        container.zPosition = 40
        addChild(container)

        drawSprite(lines: shadowSprite, palette: ["s": SKColor.black.withAlphaComponent(0.26)], pixelSize: spritePixel, parent: container, z: 0, yOffset: -95)
        drawCreatureTexture(species: species, parent: container)
        drawDynamicMarkings(species: species, parent: container)
        drawMoodParticles(parent: container)

        let bobDistance = 4 + CGFloat(petState.livingGenome.movementCuriosity) * 4
        let bob = SKAction.sequence([
            .moveBy(x: 0, y: bobDistance, duration: 0.50),
            .moveBy(x: 0, y: -bobDistance, duration: 0.50)
        ])
        container.run(.repeatForever(bob))
    }

    private func drawCreatureTexture(species: PixelSpecies, parent: SKNode) {
        let texture = SKTexture(imageNamed: textureName(for: species))
        texture.filteringMode = .nearest
        let node = SKSpriteNode(texture: texture)
        node.size = CGSize(width: 218, height: 218)
        node.position = CGPoint(x: 0, y: 0)
        node.zPosition = 3
        parent.addChild(node)
    }

    private func textureName(for species: PixelSpecies) -> String {
        switch species {
        case .foxKit: "fox_kit"
        case .moonCat: "moon_cat"
        case .orchardBunny: "orchard_bunny"
        case .emberDragon: "ember_dragon"
        }
    }

    private var shadowSprite: [String] {
        [
            "......ssssssssssssssss......",
            "...ssssssssssssssssssssss...",
            "......ssssssssssssssss......"
        ]
    }

    private func spriteLines(for species: PixelSpecies) -> [String] {
        switch species {
        case .foxKit:
            return [
                "..................KAAK................",
                ".................KAOOAK...............",
                "................KAOOOAK...............",
                "...............KOOOOOOOK..............",
                "..............KOOOWKOOOOK.............",
                ".............KOOOODKOOOOK.............",
                ".............KOOOOOOCCOOOK............",
                "............KOOOOOOOCCOOOOK...........",
                "....KKKK...KOOOOOOOOOOOOOOK...........",
                "...KOOOOKKKOOOOOOOOOOOOOOOOOK.........",
                "..KOOOOOOOOOOOOOCCCCCCCCCOOOOK........",
                ".KOOOOOOOOOOOOCCCCCCCCCCCCOOOOK.......",
                "KOOOOOOOOOOOOOCCCCCCCCCCCCCOOOOK......",
                "KOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOK......",
                ".KOOOOKKKOOOOOOOOOOOOOOOOOOOOK........",
                "..KKK...KOOOKOOOOOOOOOOOKOOOK.........",
                "........KOOOKOOOOOOOOOOOKOOOK.........",
                "........KOOOK..........KOOOK..........",
                ".........KKK............KKK..........."
            ]
        case .moonCat:
            return [
                "...........K......K............",
                "..........KLK....KLK...........",
                ".........KLLLLKKLLLLK..........",
                "........KLLLLLLLLLLLLK.........",
                ".......KLLLWKLLLLWKLLLK........",
                "......KLLLDKLLLLLDKLLLK........",
                "......KLLLLLLLCCLLLLLLK........",
                ".....KLLLLLLLLCCLLLLLLLK.......",
                "....KLLLLLLLLLLLLLLLLLLK.......",
                "...KLLLLLCCCCCCCCCCCLLLLK......",
                "..KLLLLCCCCCCCCCCCCCCLLLLK.....",
                "..KLLLLCCCCCCCCCCCCCCLLLLK.....",
                "...KLLLLLLLLLLLLLLLLLLLLK......",
                "....KLLLKLLLLLLLLLLKLLLK.......",
                "....KLLLKLLLLLLLLLLKLLLK.......",
                "....KLLLK..........KLLLK.......",
                ".....KKK............KKK........",
                "....................KLLK.......",
                "....................KLLK.......",
                "...................KLLLK.......",
                "..................KLLLK........",
                "..................KKKK........."
            ]
        case .orchardBunny:
            return [
                ".........KCCK....KCCK..........",
                ".........KCCK....KCCK..........",
                ".........KCCK....KCCK..........",
                ".........KBBK....KBBK..........",
                "........KBBBBKKKKBBBBK.........",
                ".......KBBBBBBBBBBBBBBK........",
                "......KBBBWKBBBBBBWKBBBK.......",
                "......KBBBDKBBBBBBDKBBBK.......",
                ".....KBBBBBBBCCBBBBBBBBK.......",
                "....KBBBBBBBBCCBBBBBBBBBK......",
                "...KBBBBBCCCCCCCCCCCBBBBK......",
                "..KBBBBCCCCCCCCCCCCCCCBBBK.....",
                "..KBBBBCCCCCCCCCCCCCCCBBBK.....",
                "...KBBBBBBBBBBBBBBBBBBBBK......",
                "....KBBBKBBBBBBBBBBKBBBK.......",
                "....KBBBKBBBBBBBBBBKBBBK.......",
                "....KBBBK..........KBBBK.......",
                ".....KKK............KKK........",
                "....................KCCK.......",
                "....................KCCK.......",
                ".....................KK........"
            ]
        case .emberDragon:
            return [
                "..........KAAK..KAAK............",
                ".........KARRKKRRAK............",
                "........KRRRRRRRRRRK...........",
                ".......KRRRRWRRRWRRRK..........",
                "......KRRRRDRRRRDRRRK..........",
                ".....KRRRRRRCCRRRRRRRK.........",
                "...KKKRRRRRRCCRRRRRRRKKK.......",
                "..KAAAKRRRRRRRRRRRRRKAAAK......",
                "..KAAAKRRRCCCCCCCCRRKAAAK......",
                "...KKKRRCCCCCCCCCCRRKKK........",
                "....KRRRRRRRRRRRRRRRRK.........",
                "....KRRRKRRRRRRRRKRRRK.........",
                "....KRRRKRRRRRRRRKRRRK.........",
                ".....KKK..........KKK..........",
                "..................KRRRRK.......",
                "...................KRRRAK......",
                "....................KRAAK......",
                ".....................KKK......."
            ]
        }
    }

    private func palette(for species: PixelSpecies) -> [Character: SKColor] {
        let glow = CGFloat(petState.livingGenome.glow)
        let line = outline(alpha: 1)
        switch species {
        case .foxKit:
            return [
                "K": line,
                "O": SKColor(red: 0.93 + glow * 0.04, green: 0.42 + glow * 0.08, blue: 0.12, alpha: 1),
                "A": SKColor(red: 1.0, green: 0.80, blue: 0.42, alpha: 1),
                "C": SKColor(red: 1.0, green: 0.88, blue: 0.64, alpha: 1),
                "D": SKColor(red: 0.02, green: 0.03, blue: 0.04, alpha: 1),
                "W": .white
            ]
        case .moonCat:
            return [
                "K": line,
                "L": SKColor(red: 0.50, green: 0.58 + glow * 0.12, blue: 0.88, alpha: 1),
                "C": SKColor(red: 0.78, green: 0.90, blue: 1.0, alpha: 1),
                "D": SKColor(red: 0.02, green: 0.03, blue: 0.04, alpha: 1),
                "W": .white
            ]
        case .orchardBunny:
            return [
                "K": line,
                "B": SKColor(red: 0.92, green: 0.78 + glow * 0.08, blue: 0.58, alpha: 1),
                "C": SKColor(red: 1.0, green: 0.92, blue: 0.78, alpha: 1),
                "D": SKColor(red: 0.02, green: 0.03, blue: 0.04, alpha: 1),
                "W": .white
            ]
        case .emberDragon:
            return [
                "K": line,
                "R": SKColor(red: 0.84, green: 0.20 + glow * 0.10, blue: 0.16, alpha: 1),
                "A": SKColor(red: 1.0, green: 0.76, blue: 0.18, alpha: 1),
                "C": SKColor(red: 1.0, green: 0.60, blue: 0.30, alpha: 1),
                "D": SKColor(red: 0.02, green: 0.03, blue: 0.04, alpha: 1),
                "W": .white
            ]
        }
    }

    private func drawDynamicMarkings(species: PixelSpecies, parent: SKNode) {
        guard petState.livingGenome.markings > 0.28 else { return }
        let markColor = palette(for: species)["A"] ?? SKColor(red: 0.25, green: 0.95, blue: 0.88, alpha: 1)
        spriteRect(x: -46, y: 24, width: 14, height: 7, color: markColor, z: 6, parent: parent)
        spriteRect(x: 28, y: 24, width: 14, height: 7, color: markColor, z: 6, parent: parent)
        if petState.livingGenome.markings > 0.48 {
            spriteRect(x: -10, y: 46, width: 20, height: 7, color: markColor, z: 6, parent: parent)
        }
    }

    private func drawMoodParticles(parent: SKNode) {
        let color: SKColor
        let count: Int
        switch petState.mood {
        case .radiant:
            color = SKColor(red: 1.0, green: 0.86, blue: 0.22, alpha: 1)
            count = 8
        case .curious:
            color = SKColor(red: 0.18, green: 0.94, blue: 0.92, alpha: 1)
            count = 7
        case .repairing:
            color = SKColor(red: 0.50, green: 0.96, blue: 0.50, alpha: 1)
            count = 6
        case .calm:
            color = SKColor(red: 0.74, green: 0.90, blue: 1.0, alpha: 1)
            count = 4
        case .lonely, .guarded, .overwhelmed:
            color = SKColor(red: 0.68, green: 0.44, blue: 0.94, alpha: 1)
            count = 5
        }

        for index in 0..<count {
            let x = CGFloat(-90 + index * 28)
            let y = CGFloat(106 + (index % 3) * 8)
            spriteRect(x: x, y: y, width: 7, height: 7, color: color, z: 10, parent: parent)
        }
    }

    private func resolvedSpecies() -> PixelSpecies {
        let profile = petState.treatmentProfile
        if max(profile.chaos, profile.stress) > 0.56 { return .emberDragon }
        if profile.comfort + profile.consistency > 1.22 { return .orchardBunny }
        if profile.curiosity >= 0.48 { return .foxKit }
        return .moonCat
    }

    private func drawSprite(
        lines: [String],
        palette: [Character: SKColor],
        pixelSize: CGFloat,
        parent: SKNode,
        z: CGFloat,
        yOffset: CGFloat = 0
    ) {
        let width = CGFloat(lines.map(\.count).max() ?? 0)
        let height = CGFloat(lines.count)

        for (row, line) in lines.enumerated() {
            for (column, character) in line.enumerated() {
                guard character != ".", let color = palette[character] else { continue }
                let x = (CGFloat(column) - width / 2 + 0.5) * pixelSize
                let y = (height / 2 - CGFloat(row) - 0.5) * pixelSize + yOffset
                spriteRect(x: x, y: y, width: pixelSize, height: pixelSize, color: color, z: z, parent: parent)
            }
        }
    }

    private func tileRect(x: Int, y: Int, width: Int, height: Int, color: SKColor, z: CGFloat) {
        let node = SKSpriteNode(color: color, size: CGSize(width: CGFloat(width) * tile, height: CGFloat(height) * tile))
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.position = CGPoint(
            x: (CGFloat(x) + CGFloat(width) / 2) * tile,
            y: (CGFloat(y) + CGFloat(height) / 2) * tile
        )
        node.zPosition = z
        addChild(node)
    }

    private func spriteRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: SKColor, z: CGFloat, parent: SKNode) {
        let node = SKSpriteNode(color: color, size: CGSize(width: width, height: height))
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.position = CGPoint(x: x, y: y)
        node.zPosition = z
        parent.addChild(node)
    }

    private func wallColor(_ brightnessOffset: CGFloat) -> SKColor {
        color(
            hue: 0.53,
            saturation: 0.20 + CGFloat(petState.roomGenome.musicComplexity) * 0.14,
            brightness: (0.43 + CGFloat(petState.roomGenome.lightWarmth) * 0.25 + brightnessOffset).clamped(to: 0...1),
            alpha: 1
        )
    }

    private func floorColor(_ brightnessOffset: CGFloat) -> SKColor {
        color(
            hue: 0.58,
            saturation: 0.25 + CGFloat(petState.roomGenome.weatherIntensity) * 0.12,
            brightness: (0.33 + CGFloat(petState.roomGenome.lightWarmth) * 0.18 + brightnessOffset).clamped(to: 0...1),
            alpha: 1
        )
    }

    private func outline(alpha: CGFloat) -> SKColor {
        SKColor(red: 0.025, green: 0.030, blue: 0.045, alpha: alpha)
    }

    private func color(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) -> SKColor {
        SKColor(
            hue: hue.truncatingRemainder(dividingBy: 1),
            saturation: saturation.clamped(to: 0...1),
            brightness: brightness.clamped(to: 0...1),
            alpha: alpha.clamped(to: 0...1)
        )
    }
}

private extension CGFloat {
    func clamped(to limits: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound)
    }
}
