import SwiftUI
import UIKit
import VisionKit
import RegexBuilder

struct CameraScannerViewController: UIViewControllerRepresentable {
    
    // https://blog.devgenius.io/documentscannerviewcontroller-discussion-and-tutorial-5bf988f716f2
    // https://github.com/jkeen/tracking_number_data/blob/main/couriers/dhl.json
    // https://github.com/jkeen/tracking_number_data/issues/30
    // https://www.paketda.de/paketverfolgung.php?carrier=deutschepost
    
    @Binding var startScanning: Bool
    @Binding var scanResult: String
        
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: false)
        
        viewController.delegate = context.coordinator

        return viewController
    }
    
    func updateUIViewController(_ viewController: DataScannerViewController, context: Context) {
        if startScanning {
            try? viewController.startScanning()
        } else {
            viewController.stopScanning()
        }
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: CameraScannerViewController
        private var itemHighlightViews: [RecognizedItem.ID: UIView] = [:]
        
        init(_ parent: CameraScannerViewController) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            let trackingNumber = Reference(String.self)
            
            let dhlRegex = Regex {
                TryCapture(as: trackingNumber) {
                    "R"
                    ("A"..."Z")
                    One(.whitespace)
                    Repeat(count: 4) {
                        ("0"..."9")
                    }
                    One(.whitespace)
                    Repeat(count: 4) {
                        ("0"..."9")
                    }
                    One(.whitespace)
                    ("0"..."9")
                    Repeat(count: 2) {
                        ("A"..."Z")
                    }
                } transform: { match in
                    match.replacingOccurrences(of: " ", with: "")
                }
              }
              .anchorsMatchLineEndings()

            for item in addedItems {
                guard case let .text(text) = item, let result = text.transcript.firstMatch(of: dhlRegex) else {
                    continue
                }
                
                let newView = UIView()
                let rect = CGRect(origin: item.bounds.bottomLeft,
                                  size: CGSize(width: item.bounds.topRight.x - item.bounds.topLeft.x,
                                               height: item.bounds.topRight.y - item.bounds.bottomRight.y))
                
                newView.backgroundColor = UIColor.clear
                newView.layer.borderColor = UIColor.blue.cgColor
                newView.layer.borderWidth = 2
                newView.layer.cornerRadius = 5
                newView.layer.masksToBounds = true
                
                newView.frame = rect

                itemHighlightViews[item.id] = newView
                
                dataScanner.overlayContainerView.addSubview(newView)
                parent.scanResult = result[trackingNumber]
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in updatedItems {
                if let view = itemHighlightViews[item.id] {
                    let rect = CGRect(origin: item.bounds.bottomLeft,
                                      size: CGSize(width: item.bounds.topRight.x - item.bounds.topLeft.x,
                                                   height: item.bounds.topRight.y - item.bounds.bottomRight.y))
                    view.frame = rect
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in removedItems {
                if let view = itemHighlightViews[item.id] {
                    itemHighlightViews.removeValue(forKey: item.id)
                    view.removeFromSuperview()
                }
            }
        }
    }
}
