//
//  ResultViewController.swift
//  firebasePlayground
//
//  Created by Kajornsak Peerapathananont on 11/5/2561 BE.
//  Copyright © 2561 Kajornsak Peerapathananont. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {

    var image : UIImage?
    var resultString : String?
    
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Result"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let image = self.image,let resultString = self.resultString else{
            return
        }
        resultImageView.image = image
        resultLabel.text = resultString
    }
}
