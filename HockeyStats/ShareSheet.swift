import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = controller.view
                popover.sourceRect = CGRect(
                    x: controller.view.bounds.midX,
                    y: controller.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            controller.present(activityVC, animated: true)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
