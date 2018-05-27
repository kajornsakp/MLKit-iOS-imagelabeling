//
//  ChooseImageViewController.swift
//  firebasePlayground
//
//  Created by Kajornsak Peerapathananont on 11/5/2561 BE.
//  Copyright © 2561 Kajornsak Peerapathananont. All rights reserved.
//

import UIKit
import Firebase

class ChooseImageViewController: UIViewController {

    let picker = UIImagePickerController()
    lazy var vision = Vision.vision()
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        self.title = "Image Labeling"
        
    }

    @IBAction func didTapCameraButton(_ sender: Any) {
        picker.sourceType = .camera
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func didTapLibraryButton(_ sender: Any) {
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
}

// MARK: ML Kit label detect
extension ChooseImageViewController{
    func labelImage(image : UIImage){
        let labelDetector = vision.labelDetector()
        let visionImage = VisionImage(image: image)
        labelDetector.detect(in: visionImage){ (labels, error) in
            guard error == nil , let labels = labels, !labels.isEmpty else {
                self.showError(errorMessage: error?.localizedDescription ?? "Something went wrong")
                return
            }
            let result = labels.map({
                return "\($0.label) : \($0.confidence)"
            }).joined(separator: "\n")
            self.showResultScreen(image: image, resultString: result)
        }
    }
}

//MARK: UIImagePickerController's delegate
extension ChooseImageViewController : UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            self.labelImage(image: image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: UI
extension ChooseImageViewController{
    func showError(errorMessage : String){
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: "dismiss", style: .default)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showResultScreen(image : UIImage,resultString : String){
        let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
        vc.image = image
        vc.resultString = resultString
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
