//
//  BSRealTimeScanningViewController.swift
//  firebasePlayground
//
//  Created by Kajornsak Peerapathananont on 31/5/2561 BE.
//  Copyright © 2561 Kajornsak Peerapathananont. All rights reserved.
//

import UIKit
import AVKit
import Firebase

class BSRealTimeScanningViewController: UIViewController {
    
    var session = AVCaptureSession()
    lazy var vision = Vision.vision()
    var isDetecting = false
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var outputView: UIVisualEffectView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputView.layer.cornerRadius = 15.0
        startLiveVideo()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopLiveVideo()
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    func startLiveVideo(){
        session.sessionPreset = .hd1920x1080
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))
        deviceOutput.connection(with: .video)?.videoOrientation = .portrait
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.videoGravity = .resizeAspectFill
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
        session.startRunning()
        
    }
    
    func stopLiveVideo(){
        session.stopRunning()
        session = AVCaptureSession()
    }
    func showBarcodeResult(_ result : String){
        isDetecting = true
        let alert = UIAlertController(title: "Result", message: result, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default){ _ in
            self.isDetecting = false
            alert.dismiss(animated: true, completion: nil)
        })
        self.present(alert, animated: true, completion: nil)
    }
}

extension BSRealTimeScanningViewController : AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if(!isDetecting){
            isDetecting = true
            let barcodeFormat = VisionBarcodeFormat.all
            let options = VisionBarcodeDetectorOptions(formats: barcodeFormat)
            let barcodeDetector = vision.barcodeDetector(options: options)
            let visionImage = VisionImage(buffer: sampleBuffer)
            let metadata = VisionImageMetadata()
            metadata.orientation = .rightTop
            visionImage.metadata = metadata
            barcodeDetector.detect(in: visionImage){ (barcodes, error) in
                guard error == nil , let barcodes = barcodes, !barcodes.isEmpty else {
                    self.resultLabel.textColor = UIColor.red
                    self.resultLabel.text = error?.localizedDescription
                    self.isDetecting = false
                    return
                }
                self.resultLabel.textColor = UIColor.white
                let result = barcodes.map({
                    return $0.rawValue ?? ""
                }).joined(separator: "\n")
                self.resultLabel.text = result
                self.isDetecting = false
                self.showBarcodeResult(result)
            }
        }
    }
}
