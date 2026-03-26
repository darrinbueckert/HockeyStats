import Foundation
import UIKit
import SwiftData

enum PDFExport {
    static func makeGameReportPDF(for game: Game) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 40
        let contentWidth = pageRect.width - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 22)
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let bodyFont = UIFont.systemFont(ofSize: 11)
            let smallFont = UIFont.systemFont(ofSize: 10)
            let monoBold = UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)
            let monoRegular = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)

            var y: CGFloat = margin

            func drawText(_ text: String, font: UIFont, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font]
                let nsText = NSString(string: text)

                let size = nsText.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                ).size

                nsText.draw(
                    in: CGRect(x: x, y: y, width: width, height: ceil(size.height)),
                    withAttributes: attrs
                )

                return ceil(size.height)
            }

            func drawLine(y: CGFloat) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                UIColor.lightGray.setStroke()
                path.lineWidth = 1
                path.stroke()
            }

            let teamName = game.team?.name ?? "Team"
            let opponent = game.opponent
            let dateText = game.date.formatted(date: .abbreviated, time: .shortened)

            y += drawText("Game Report", font: titleFont, x: margin, y: y, width: contentWidth)
            y += 6
            y += drawText(teamName, font: headerFont, x: margin, y: y, width: contentWidth)
            y += drawText("vs \(opponent)", font: bodyFont, x: margin, y: y, width: contentWidth)
            y += drawText(dateText, font: smallFont, x: margin, y: y, width: contentWidth)
            y += 12
            drawLine(y: y)
            y += 12

            let goalieName: String = {
                if let goalie = game.goalie {
                    return "#\(goalie.number) \(goalie.name)"
                }
                return "None selected"
            }()

            let goalsAgainst = game.events.filter { $0.type == .goalAgainst }.count
            let shotsAgainstUsed = game.shotsAgainst > 0
                ? game.shotsAgainst
                : game.events.filter { $0.type == .opponentShot }.count
            let saves = max(shotsAgainstUsed - goalsAgainst, 0)

            let svText: String = {
                guard shotsAgainstUsed > 0 else { return ".000" }
                let value = Double(saves) / Double(shotsAgainstUsed)
                return String(format: "%.3f", value)
            }()

            y += drawText("Goalie", font: headerFont, x: margin, y: y, width: contentWidth)
            y += 6
            y += drawText("Goalie: \(goalieName)", font: bodyFont, x: margin, y: y, width: contentWidth)
            y += drawText("Shots Against: \(shotsAgainstUsed)", font: bodyFont, x: margin, y: y, width: contentWidth)
            y += drawText("Goals Against: \(goalsAgainst)", font: bodyFont, x: margin, y: y, width: contentWidth)
            y += drawText("Saves: \(saves)", font: bodyFont, x: margin, y: y, width: contentWidth)
            y += drawText("Save %: \(svText)", font: bodyFont, x: margin, y: y, width: contentWidth)
            y += 12
            drawLine(y: y)
            y += 12

            y += drawText("Player Stats", font: headerFont, x: margin, y: y, width: contentWidth)
            y += 8

            let sortedPlayers = (game.team?.players ?? []).sorted {
                if $0.number == $1.number { return $0.name < $1.name }
                return $0.number < $1.number
            }

            y += drawText("Player                  G   A   P   S   PIM  +/-", font: monoBold, x: margin, y: y, width: contentWidth)

            for player in sortedPlayers {
                let goals = game.events.filter {
                    $0.type == .goalFor &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let assists = game.events.filter {
                    $0.type == .goalFor &&
                    ($0.secondaryPlayer?.persistentModelID == player.persistentModelID ||
                     $0.tertiaryPlayer?.persistentModelID == player.persistentModelID)
                }.count

                let shots = game.events.filter {
                    $0.type == .shot &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let pim = game.events
                    .filter {
                        $0.type == .penalty &&
                        $0.primaryPlayer?.persistentModelID == player.persistentModelID
                    }
                    .compactMap(\.pimMinutes)
                    .reduce(0, +)

                let plus = game.events.filter {
                    $0.type == .plus &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                let minus = game.events.filter {
                    $0.type == .minus &&
                    $0.primaryPlayer?.persistentModelID == player.persistentModelID
                }.count

                if goals == 0 && assists == 0 && shots == 0 && pim == 0 && plus == 0 && minus == 0 {
                    continue
                }

                let points = goals + assists
                let plusMinus = plus - minus

                let name = "#\(player.number) \(player.name)"
                let shortName = String(name.prefix(22))
                let row = String(
                    format: "%-22@ %3d %3d %3d %3d %5d %4d",
                    shortName, goals, assists, points, shots, pim, plusMinus
                )

                if y > pageRect.height - margin - 30 {
                    context.beginPage()
                    y = margin
                }

                y += drawText(row, font: monoRegular, x: margin, y: y, width: contentWidth)
            }
        }

        return data
    }
}
