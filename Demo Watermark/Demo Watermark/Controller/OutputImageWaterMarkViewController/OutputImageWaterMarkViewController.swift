//
//  OutputImageWaterMarkViewController.swift
//  Demo Watermark
//
//  Created by Hammad Baig on 19/07/2023.
//

import UIKit

class OutputImageWaterMarkViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var outPutImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let image = outPutImage else{return}
        self.imageView.image = image
    }

}
