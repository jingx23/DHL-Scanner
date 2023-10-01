import SwiftUI
import VisionKit

struct ContentView: View {
    
    @State private var showCameraScannerView = false
    @State private var isDataScannerSupported = false
    @State private var showDatascannerNotSupportedAlert = false
    @State private var scanResults: String = ""
    
    var body: some View {
        VStack {
            Text(scanResults)
                .padding()
            
            Button {
                if isDataScannerSupported {
                    self.showCameraScannerView = true
                } else {
                    self.showDatascannerNotSupportedAlert = true
                }
            } label: {
                Text("Tap to Scan Documents")
                    .foregroundColor(.white)
                    .frame(width: 300, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showCameraScannerView) {
            CameraScanner(startScanning: $showCameraScannerView, scanResult: $scanResults)
        }
        .alert("Scanner Unavailable", isPresented: $showDatascannerNotSupportedAlert, actions: {})
        .onAppear {
            isDataScannerSupported = (DataScannerViewController.isSupported &&
                                DataScannerViewController.isAvailable)
        }
    }
}

#Preview {
    ContentView()
}
