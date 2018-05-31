//
//  BSChooseImageViewController.swift
//  firebasePlayground
//
//  Created by Kajornsak Peerapathananont on 30/5/2561 BE.
//  Copyright © 2561 Kajornsak Peerapathananont. All rights reserved.
//

import UIKit
import Firebase

class BSChooseImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    let frameSubLayer = CALayer()
    
    let picker = UIImagePickerController()
    lazy var vision = Vision.vision()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Barcode scanning"
        picker.delegate = self
        imageView.layer.addSublayer(frameSubLayer)
    }

    @IBAction func didTapCameraButton(_ sender: Any) {
        picker.sourceType = .camera
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func didTapLibraryButton(_ sender: Any) {
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
}

extension BSChooseImageViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            self.removeFrames()
            self.scaleImageView(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: Barcode scanning
extension BSChooseImageViewController{
    func scanBarcode(){
        guard let image = self.imageView.image else {return}
        let format = VisionBarcodeFormat.all
        let options = VisionBarcodeDetectorOptions(formats: format)
        let barcodeDetector = vision.barcodeDetector(options: options)
        let imageMetadata = VisionImageMetadata()
        imageMetadata.orientation = calculateImageOrientation(image.imageOrientation)
        let visionImage = VisionImage(image: image)
        visionImage.metadata = imageMetadata
        barcodeDetector.detect(in: visionImage){ (barcodes,error) in
            guard error == nil,let barcodes = barcodes, !barcodes.isEmpty else {
                print(error?.localizedDescription ?? "Can't detect barcode")
                return
            }
            self.imageView.image = image
            let _ = barcodes.map{
                self.displayBarcode($0)
                self.addFrameView(featureFrame: $0.frame, imageSize: image.size, viewFrame: self.imageView.frame)
            }
        }
    }

    func displayBarcode(_ barcode : VisionBarcode){
        if let calendar = barcode.calendarEvent{
            print(calendar)
        }
        if let wifi = barcode.wifi{
            print(wifi)
        }
        if let contact = barcode.contactInfo{
            print(contact)
        }
    }
}

//MARK: Image preparing
extension BSChooseImageViewController{
    
    func calculateImageOrientation(_ orientation : UIImageOrientation) -> VisionDetectorImageOrientation{
        switch orientation {
        case .up:
            return .topLeft
        case .down:
            return .bottomRight
        case .left:
            return .leftBottom
        case .right:
            return .rightTop
        case .upMirrored:
            return .topRight
        case .downMirrored:
            return .bottomLeft
        case .leftMirrored:
            return .leftTop
        case .rightMirrored:
            return .rightBottom
        }
    }
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) {
        print("Frame: \(featureFrame).")
        
        let viewSize = viewFrame.size
        
        // Find resolution for the view and image
        let rView = viewSize.width / viewSize.height
        let rImage = imageSize.width / imageSize.height
        
        // Define scale based on comparing resolutions
        var scale: CGFloat
        if rView > rImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        // Calculate scaled feature frame size
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        // Calculate scaled feature frame top-left point
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        // Define a rect for scaled feature frame
        let featureRectScaled = CGRect(x: featurePointXScaled,
                                       y: featurePointYScaled,
                                       width: featureWidthScaled,
                                       height: featureHeightScaled)
        
        drawFrame(featureRectScaled)
    }
    
    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = UIColor.red.cgColor
        rectLayer.fillColor = UIColor.clear.cgColor
        rectLayer.lineWidth = 3.0
        frameSubLayer.addSublayer(rectLayer)
    }
    
    /// Removes the frame results from the image.
    private func removeFrames() {
        guard let sublayers = frameSubLayer.sublayers else { return }
        for sublayer in sublayers {
            guard let frameLayer = sublayer as CALayer? else {
                print("Failed to remove frame layer.")
                continue
            }
            frameLayer.removeFromSuperlayer()
        }
    }
    private func scaleImageView(_ image: UIImage) {
        let orientation = UIApplication.shared.statusBarOrientation
        var scaledImageWidth: CGFloat = 0.0
        var scaledImageHeight: CGFloat = 0.0
        switch orientation {
        case .portrait, .portraitUpsideDown, .unknown:
            scaledImageWidth = imageView.bounds.size.width * UIScreen.main.scale
            scaledImageHeight = image.size.height * scaledImageWidth / image.size.width
        case .landscapeLeft, .landscapeRight:
            scaledImageWidth = image.size.width * scaledImageHeight / image.size.height
            scaledImageHeight = imageView.bounds.size.height * UIScreen.main.scale
        }
        DispatchQueue.global(qos: .default).async {
            // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
            var scaledImage = image.scaledImage(
                with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
            )
            scaledImage = scaledImage ?? image
            guard let finalImage = scaledImage else { return }
            DispatchQueue.main.async {
                self.imageView.image = finalImage
                self.scanBarcode()
            }
        }
    }
}
