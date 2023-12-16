//
//  ViewController.swift
//  Demo Add WaterMark
//
//  Created by Hammad Baig on 02/06/2023.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices


class SelectVideoViewController: UIViewController {
    
    @IBOutlet weak var buttonAttachVideo: UIButton!
    @IBOutlet weak var buttonAttachImage: UIButton!
    
    var videoPicker = UIImagePickerController()
    var sourceTypeImage: Bool = false
    var videoURL: URL?
    var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews(){
        self.navigationItem.title = "Demo Project"
        buttonAttachVideo.addTarget(self, action: #selector(tappedAttachVideo), for: .touchUpInside)
        buttonAttachImage.addTarget(self, action: #selector(tappedAttachImage), for: .touchUpInside)
    }
    
    //Ask User How they wanted to add video
    func presentSelectPickerType(){
        
        let alert = UIAlertController(title: "Attach", message: "How would you like to attach.", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) { _ in
            self.openCamera()
        }
        let photos = UIAlertAction(title: "Photos", style: .default) { _ in
            self.openPhotos()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(camera)
        alert.addAction(photos)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
    //Open Camera to recode Vide
    func openCamera(){
        videoPicker.sourceType = .camera
        videoPicker.delegate = self
        videoPicker.allowsEditing = true
        if sourceTypeImage {
            videoPicker.mediaTypes = [UTType.image.identifier]
            videoPicker.videoQuality = UIImagePickerController.QualityType.typeHigh
        }else{
            videoPicker.mediaTypes = [UTType.movie.identifier]
            videoPicker.videoQuality = UIImagePickerController.QualityType.typeHigh
        }
        present(videoPicker, animated: true, completion: nil)
       
    }
    
    //Open Gallery to add video
    func openPhotos(){
        videoPicker.delegate = self
        videoPicker.sourceType = .photoLibrary
        videoPicker.allowsEditing = true
        if sourceTypeImage {
            videoPicker.mediaTypes = [UTType.image.identifier]
            videoPicker.videoQuality = UIImagePickerController.QualityType.typeHigh
        }else{
            videoPicker.mediaTypes = [UTType.movie.identifier]
            videoPicker.videoQuality = UIImagePickerController.QualityType.typeHigh
        }
        present(videoPicker, animated: true, completion: nil)
    }
    
    //Move Add Water Mark
    func navigatToAddWatermark(){
        let vc = UIStoryboard(name: "Main", bundle: nil)
        let dVC = vc.instantiateViewController(withIdentifier: "AddWaterMarkViewController") as! AddWaterMarkViewController
       
        if sourceTypeImage {
            dVC.selectedImage = self.selectedImage
            dVC.sourceType = .image
        }else{
            dVC.videoURL = self.videoURL
            dVC.sourceType = .video
        }
        
        self.navigationController?.pushViewController(dVC, animated: true)
    }

}
//MARK: - Actions
extension SelectVideoViewController {
    
    @objc func tappedAttachVideo(){
        sourceTypeImage = false
        presentSelectPickerType()
    }
    
    @objc func tappedAttachImage(){
        sourceTypeImage = true
        presentSelectPickerType()
    }
    
}
//MARK: - UIImagePickerControllerDelegate
extension SelectVideoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
       
        if sourceTypeImage {
            let selectedImage = info[UIImagePickerController.InfoKey.editedImage]as? UIImage
            guard let selectedImage = selectedImage else{ return self.showAlert(title: "", message: "select another image.")}
            self.selectedImage = selectedImage
            self.dismiss(animated: true) {
                self.navigatToAddWatermark()
            }
        }else{
            let videoURL = info[UIImagePickerController.InfoKey.mediaURL]as? NSURL
            let convertedURL = URL(fileURLWithPath: videoURL?.path ?? "")
            self.videoURL = convertedURL
            guard let item = MediaItem(url: convertedURL) else {
                return print("Unable to get video URL") }
            
            if item.size.width > item.size.height {
                print("Landscape")
                self.dismiss(animated: true)
                self.showAlert(title: "", message: "In order to watermark on your video\n. Please add portrait video.")
            } else {
                print("Portrait")
                self.dismiss(animated: true) {
                    self.navigatToAddWatermark()
                 }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
       picker.dismiss(animated: true, completion: nil)
    }
    
}


