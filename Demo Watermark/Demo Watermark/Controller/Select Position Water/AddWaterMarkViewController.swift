//
//  AddWaterMarkViewController.swift
//  Demo Add WaterMark
//
//  Created by Hammad Baig on 02/06/2023.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import Foundation


enum WaterMarkPostioningOption{
    case topCenter
    case bottomCenter
}

enum SourceType{
    case image
    case video
}

class AddWaterMarkViewController: UIViewController {
    
    @IBOutlet weak var buttonTopCenter: UIButton!
    @IBOutlet weak var buttonBottomCenter: UIButton!
    @IBOutlet weak var buttonConfirm: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var videoURL: URL?
    var remainingURL: URL?
    var selctedPosition: WaterMarkPostioningOption = .topCenter
    var waterMarkTimer: Double = 5// change water mark availbility timer by default set 5 sec
    var sourceType: SourceType = .video
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews(){
        self.navigationItem.title = "Add Water Mark"
        activityIndicator.isHidden = true
        //guard let _ = self.videoURL else{return}
        buttonTopCenter.addTarget(self, action: #selector(selectTopcenter), for: .touchUpInside)
        buttonBottomCenter.addTarget(self, action: #selector(selectBottomcenter), for: .touchUpInside)
        buttonConfirm.addTarget(self, action: #selector(tappedConfirm), for: .touchUpInside)
        updateUIOnSelection()
    }
    
    ///Updating UI As per selection
    func updateUIOnSelection(){
        switch selctedPosition {
        case .topCenter:
            buttonTopCenter.backgroundColor = UIColor(hexString: "#000E91")
            buttonTopCenter.setTitleColor(.white, for: .normal)
            buttonBottomCenter.backgroundColor = UIColor(hexString: "#EAEAEA")
            buttonBottomCenter.setTitleColor(.black, for: .normal)
        case .bottomCenter:
            buttonBottomCenter.backgroundColor = UIColor(hexString: "#000E91")
            buttonBottomCenter.setTitleColor(.white, for: .normal)
            buttonTopCenter.backgroundColor = UIColor(hexString: "#EAEAEA")
            buttonTopCenter.setTitleColor(.black, for: .normal)
        }
    }
    
}


//MARK: - Action
extension AddWaterMarkViewController {
    
    ///Set top Center and update UI
    @objc func selectTopcenter(){
        selctedPosition = .topCenter
        updateUIOnSelection()
    }
    
    ///Set Bottom Center and update UI
    @objc func selectBottomcenter(){
        selctedPosition = .bottomCenter
        updateUIOnSelection()
    }
    
    @objc func tappedConfirm(){
        generateWaterMark()
    }
    
    func generateWaterMark(){
        switch sourceType {
        case .video:
            guard let videoURL = videoURL else{return}
            let videoDuration = self.getVideoDuration(url: videoURL) ?? 0
            activityIndicator.isHidden = false
            if videoDuration > waterMarkTimer {
                splitVideo(url: videoURL, startTime: 0, endTime: waterMarkTimer) { (firstSegmentURL, remainingURL, error) in
                    if let error = error {
                        print("Error splitting video: \(error.localizedDescription)")
                        return
                    }

                    if let firstSegmentURL = firstSegmentURL {
                        print("First segment URL: \(firstSegmentURL)")
                        self.processVideo(url: firstSegmentURL)
                    }

                    if let remainingURL = remainingURL {
                        self.remainingURL = remainingURL
                        print("Remaining part URL: \(remainingURL)")
                    }
                }
            }else{
                self.processVideo(url: videoURL)
            }

        case .image:
            print("add watermark On image")
            guard let selectedImage = selectedImage else{return}
            self.processImage(image: selectedImage)
        }
        
    }
    
    func navigateToOutputImage(resultImage: UIImage){
        let vc = UIStoryboard(name: "Main", bundle: nil)
        let dVC = vc.instantiateViewController(withIdentifier: "OutputImageWaterMarkViewController") as! OutputImageWaterMarkViewController
        dVC.outPutImage = resultImage
        self.navigationController?.pushViewController(dVC, animated: true)
    }
   
}

//MARK: - Generat Water For Video
extension AddWaterMarkViewController {
    
    func processVideo(url: URL) {
        if let item = MediaItem(url: url) {
            let elements = configureAddWaterMark(item: item)
            item.add(elements: elements)

            let mediaProcessor = MediaProcessor()

            mediaProcessor.processElements(item: item) { [weak self] (result, error) in
                DispatchQueue.main.async {

                    guard let processedURL = result.processedUrl else {
                        self?.showAlert(title: "", message: "Unable to add watermark to the video.")
                        return
                    }
                    guard let videoURL = self?.videoURL else{return}
                    let videoDuration = self?.getVideoDuration(url: videoURL) ?? 0

                    // check original video size if great than watermark timer then merge also remaing part
                    if videoDuration > (self?.waterMarkTimer ?? 0) {
                        //merge Remaining part then play video
                        guard let remainingURL = self?.remainingURL else{return}
                        let videoAsset1 = AVAsset(url: processedURL)
                        let videoAsset2 = AVAsset(url: remainingURL)
                        self?.mergeVideos(arrayVideos: [videoAsset1,videoAsset2 ], completion: { videoURL, error in
                            DispatchQueue.main.async {
                                self?.activityIndicator.isHidden = true
                                if let videoURl =  videoURL {
                                    self?.playOutputVideo(videoURl)
                                    //self?.saveVideoToLibrary(videoURL: processedURL)//uncomment if you also wants to save on photos
                                }else{
                                    print("error : \(error?.localizedDescription ?? "")")
                                }
                            }

                        })
                    }else{
                        self?.activityIndicator.isHidden = true
                        self?.playOutputVideo(processedURL)
                        //self?.saveVideoToLibrary(videoURL: processedURL)//uncomment if you also wants to save on photos
                    }
                }
            }
        }
    }
    
    func processImage(image: UIImage){
        let item = MediaItem(image: image)
        let elements = configureAddWaterMark(item: item)
        item.add(elements: elements)

        let mediaProcessor = MediaProcessor()
        self.activityIndicator.isHidden = false
        mediaProcessor.processElements(item: item) { [weak self] (result, error) in
            DispatchQueue.main.async {
                self?.activityIndicator.isHidden = true
                if error == nil {
                    guard let image = result.image else{return}
                    self?.navigateToOutputImage(resultImage: image)
                }
            }
            
        }
    }
    
    ///Old Configuration to add water mark and return media to process video
//    func configureAddWaterMark( item: MediaItem) -> [MediaElement] {
//        // Video
//        let videoHeight = item.size.height
//        let videoWidth = item.size.width
//
//        // First Watermark
//        let firstWatermark = UIImage(named: "waterMark1")
//        let firstElement = MediaElement(image: firstWatermark!)
//        let firstWatermarkWidth = self.calculatePercentage(value: videoWidth, percentageVal: 20) // Adjust the watermark width as desired
//        let firstWatermarkHeight =  firstWatermarkWidth / 2 //firstWatermark!.size.height * 0.4
//
//        // Second Watermark
//        let secondWatermark = UIImage(named: "waterMark2")
//        let secondElement = MediaElement(image: secondWatermark!)
//        let secondWatermarkWidth =  self.calculatePercentage(value: videoWidth, percentageVal: 24) // Adjust the watermark width as desired
//        let secondWatermarkHeight = secondWatermarkWidth / 2 //secondWatermark!.size.height * 0.4
//
//        switch selctedPosition {
//        case .bottomCenter:
//            switch sourceType {
//            case .image:
//                // Position watermarks at the top center
//                let totalWidth = firstWatermarkWidth + secondWatermarkWidth
//                let spacing: CGFloat = 20 // Adjust the spacing value as desired
//                let xOffset = (videoWidth - totalWidth - spacing) / 2
//                let yOffset = (videoHeight - secondWatermarkHeight) - 20
//
//                firstElement.frame = CGRect(x: xOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
//                secondElement.frame = CGRect(x: xOffset + secondWatermarkWidth + spacing, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
//            case .video:
//                // Position watermarks at the bottom center
//                let totalWidth = firstWatermarkWidth + secondWatermarkWidth
//                let spacing: CGFloat = 20 // Adjust the spacing value as desired
//                let xOffset = (videoWidth - totalWidth - spacing) / 2
//                let yOffset: CGFloat = 10
//
//                firstElement.frame = CGRect(x: xOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
//                secondElement.frame = CGRect(x: xOffset + secondWatermarkWidth + spacing, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
//            }
//
//
//        case .topCenter:
//            switch sourceType {
//            case .image:
//                // Position watermarks at the bottom center
//                let totalWidth = firstWatermarkWidth + secondWatermarkWidth
//                let spacing: CGFloat = 20 // Adjust the spacing value as desired
//                let xOffset = (videoWidth - totalWidth - spacing) / 2
//                let yOffset: CGFloat = 10
//
//                firstElement.frame = CGRect(x: xOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
//                secondElement.frame = CGRect(x: xOffset + secondWatermarkWidth + spacing, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
//
//            case .video:
//                // Position watermarks at the top center
//                let totalWidth = firstWatermarkWidth + secondWatermarkWidth
//                let spacing: CGFloat = 20 // Adjust the spacing value as desired
//                let xOffset = (videoWidth - totalWidth - spacing) / 2
//                let yOffset = (videoHeight - secondWatermarkHeight) - 20
//
//                firstElement.frame = CGRect(x: xOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
//                secondElement.frame = CGRect(x: xOffset + secondWatermarkWidth + spacing, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
//            }
//        }
//        return [firstElement, secondElement]
//    }
    
    func configureAddWaterMark( item: MediaItem) -> [MediaElement] {
        let videoHeight = item.size.height
        let videoWidth = item.size.width

//        // First Watermark
        let firstWatermark = UIImage(named: "waterMark2")
        let firstElement = MediaElement(image: firstWatermark!)
        let firstWatermarkWidth = self.calculatePercentage(value: videoWidth, percentageVal: 36) // Adjust the watermark width as desired
        let firstWatermarkHeight = (firstWatermarkWidth / 4) + 5 //firstWatermark!.size.height * 0.4
//
//        // Second Watermark
        let secondWatermark = UIImage(named: "waterMark1")
        let secondElement = MediaElement(image: secondWatermark!)
        let secondWatermarkWidth = self.calculatePercentage(value: videoWidth, percentageVal: 32) // Adjust the watermark width as desired
        let secondWatermarkHeight = (firstWatermarkWidth / 4) + 5   //secondWatermark!.size.height * 0.4
       
        
        switch selctedPosition {
        case .bottomCenter:
            switch sourceType {
            case .image:
                // Position watermarks at the bottom leading (left) and bottom trailing (right) corners with spacing
                let leadingXOffset: CGFloat = 25
                let trailingXOffset = videoWidth - secondWatermarkWidth - 25
                let yOffset: CGFloat = videoHeight - firstWatermarkHeight - 25 // Adjust the yOffset to position the watermarks at the bottom

                firstElement.frame = CGRect(x: leadingXOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
                secondElement.frame = CGRect(x: trailingXOffset, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
            case .video:
                // Position watermarks at the top leading (left) and top trailing (right) corners with spacing
                let leadingXOffset: CGFloat = 25
                let trailingXOffset = videoWidth - secondWatermarkWidth - 25
                let yOffset: CGFloat = 25

                firstElement.frame = CGRect(x: leadingXOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
                secondElement.frame = CGRect(x: trailingXOffset, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
            }


        case .topCenter:
            switch sourceType {
            case .image:
                // Position watermarks at the top leading (left) and top trailing (right) corners with spacing
                let leadingXOffset: CGFloat = 25
                let trailingXOffset = videoWidth - secondWatermarkWidth - 25
                let yOffset: CGFloat = 25

                firstElement.frame = CGRect(x: leadingXOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
                secondElement.frame = CGRect(x: trailingXOffset, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)

            case .video:
                // Position watermarks at the bottom leading (left) and bottom trailing (right) corners with spacing
                let leadingXOffset: CGFloat = 25
                let trailingXOffset = videoWidth - secondWatermarkWidth - 25
                let yOffset: CGFloat = videoHeight - firstWatermarkHeight - 25 // Adjust the yOffset to position the watermarks at the bottom

                firstElement.frame = CGRect(x: leadingXOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
                secondElement.frame = CGRect(x: trailingXOffset, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
            }
        }
        return [firstElement, secondElement]
    }
    
    ///for image top and video bottom
//    func configureAddWaterMark(item: MediaItem) -> [MediaElement] {
//        // Video or image dimensions
//        let videoHeight = item.size.height
//        let videoWidth = item.size.width
//
//        // First Watermark
//        let firstWatermark = UIImage(named: "waterMark2")
//        let firstElement = MediaElement(image: firstWatermark!)
//        let firstWatermarkWidth = self.calculatePercentage(value: videoWidth, percentageVal: 24) // Adjust the watermark width as desired
//        let firstWatermarkHeight = firstWatermarkWidth / 2 //firstWatermark!.size.height * 0.4
//
//        // Second Watermark
//        let secondWatermark = UIImage(named: "waterMark1")
//        let secondElement = MediaElement(image: secondWatermark!)
//        let secondWatermarkWidth = self.calculatePercentage(value: videoWidth, percentageVal: 20) // Adjust the watermark width as desired
//        let secondWatermarkHeight = secondWatermarkWidth / 2 //secondWatermark!.size.height * 0.4
//
//        // Position watermarks at the top leading (left) and top trailing (right) corners with spacing
//        let leadingXOffset: CGFloat = 20
//        let trailingXOffset = videoWidth - secondWatermarkWidth - 20
//        let yOffset: CGFloat = 20
//
//        firstElement.frame = CGRect(x: leadingXOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
//        secondElement.frame = CGRect(x: trailingXOffset, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
//
//        return [firstElement, secondElement]
//    }

    ///for image bottom and video top
//    func configureAddWaterMark(item: MediaItem) -> [MediaElement] {
//        // Video or image dimensions
//        let videoHeight = item.size.height
//        let videoWidth = item.size.width
//
//        // First Watermark
//        let firstWatermark = UIImage(named: "waterMark2")
//        let firstElement = MediaElement(image: firstWatermark!)
//        let firstWatermarkWidth = self.calculatePercentage(value: videoWidth, percentageVal: 24) // Adjust the watermark width as desired
//        let firstWatermarkHeight = firstWatermarkWidth / 2 //firstWatermark!.size.height * 0.4
//
//        // Second Watermark
//        let secondWatermark = UIImage(named: "waterMark1")
//        let secondElement = MediaElement(image: secondWatermark!)
//        let secondWatermarkWidth = self.calculatePercentage(value: videoWidth, percentageVal: 20) // Adjust the watermark width as desired
//        let secondWatermarkHeight = secondWatermarkWidth / 2 //secondWatermark!.size.height * 0.4
//
//        // Position watermarks at the bottom leading (left) and bottom trailing (right) corners with spacing
//        let leadingXOffset: CGFloat = 20
//        let trailingXOffset = videoWidth - secondWatermarkWidth - 20
//        let yOffset: CGFloat = videoHeight - firstWatermarkHeight - 20 // Adjust the yOffset to position the watermarks at the bottom
//
//        firstElement.frame = CGRect(x: leadingXOffset, y: yOffset, width: firstWatermarkWidth, height: firstWatermarkHeight)
//        secondElement.frame = CGRect(x: trailingXOffset, y: yOffset, width: secondWatermarkWidth, height: secondWatermarkHeight)
//
//        return [firstElement, secondElement]
//    }


    ///Get duration of video
    func getVideoDuration(url: URL) -> Double? {
        let asset = AVURLAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        return durationSeconds.isFinite ? durationSeconds : nil
    }
    
    ///Calculate percentage of video width in order set dynamic width of watermarks as per video width
    func calculatePercentage(value:Double,percentageVal:Double)->Double{
        let val = value * percentageVal
        return val / 100.0
    }
    
    ///Spliting video to in sure that only waterMarkTimer sec of video will be process for water mark
    func splitVideo(url: URL, startTime: Double, endTime: Double, completion: @escaping (URL?, URL?, Error?) -> Void) {
        let asset = AVURLAsset(url: url)

        let composition = AVMutableComposition()

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil, nil, NSError(domain: "Video track not found", code: 0, userInfo: nil))
            return
        }

        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            completion(nil, nil, NSError(domain: "Audio track not found", code: 0, userInfo: nil))
            return
        }

        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            let startTime = CMTime(seconds: startTime, preferredTimescale: asset.duration.timescale)
            let endTime = CMTime(seconds: endTime, preferredTimescale: asset.duration.timescale)
            let timeRange = CMTimeRange(start: startTime, end: endTime)

            try videoCompositionTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            try audioCompositionTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)

            // Apply preferred transform to the video composition track
            videoCompositionTrack?.preferredTransform = videoTrack.preferredTransform

            //
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = videoTrack.naturalSize
            //CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

//            let instruction = AVMutableVideoCompositionInstruction()
//            instruction.timeRange = CMTimeRange(start: .zero, duration: timeRange.duration)
//
//            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack!)
//            layerInstruction.setTransform(videoCompositionTrack!.preferredTransform, at: .zero)
//            instruction.layerInstructions = [layerInstruction]
//
//            videoComposition.instructions = [instruction]
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: timeRange.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack!)
            layerInstruction.setTransform(videoCompositionTrack!.preferredTransform, at: .zero)
            instruction.layerInstructions = [layerInstruction]

            videoComposition.instructions = [instruction]
            //
            let fileManager = FileManager.default

            // Split video URL
            let splitOutputURL = generateUniqueOutputURL()

            if fileManager.fileExists(atPath: splitOutputURL.path) {
                try? fileManager.removeItem(at: splitOutputURL)
            }

            // Remaining video URL
            let remainingOutputURL = generateUniqueOutputURL()

            if fileManager.fileExists(atPath: remainingOutputURL.path) {
                try? fileManager.removeItem(at: remainingOutputURL)
            }

            let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)

            exporter?.outputURL = splitOutputURL
            exporter?.outputFileType = .mp4
            exporter?.shouldOptimizeForNetworkUse = true

            exporter?.exportAsynchronously(completionHandler: {
                switch exporter?.status {
                case .completed:
                    // Splitting is successful
                    let remainingTimeRange = CMTimeRange(start: endTime, end: asset.duration)
                    self.exportRemainingVideo(asset: asset, timeRange: remainingTimeRange) { url, error in
                        if let url = url {
                            completion(splitOutputURL, url, nil)
                        }else{
                            completion(nil, nil, NSError(domain: "Failed to export remaining video", code: 0, userInfo: nil))
                        }
                    }

                case .failed, .cancelled:
                    // Splitting failed or was cancelled
                    let error = exporter?.error ?? NSError(domain: "Video splitting failed", code: 0, userInfo: nil)
                    completion(nil, nil, error)

                default:
                    break
                }
            })
        } catch {
            // Error occurred while splitting the video
            let error = NSError(domain: "Video splitting error", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
            completion(nil, nil, error)
        }
    }
       

    func exportRemainingVideo(asset: AVAsset, timeRange: CMTimeRange, completion: @escaping (URL?, Error?) -> Void) {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil, NSError(domain: "Video track not found", code: 0, userInfo: nil))
            return
        }

        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            completion(nil, NSError(domain: "Audio track not found", code: 0, userInfo: nil))
            return
        }

        let composition = AVMutableComposition()

        do {
            let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

            try videoCompositionTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            try audioCompositionTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)

            // Apply fixed transform to the video composition track to ensure full-screen portrait orientation
            let transform = videoTrack.preferredTransform
            videoCompositionTrack?.preferredTransform = transform

            let videoComposition = AVMutableVideoComposition()
            
//            // works fine on recorded videos
//            videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
//
//            //work fine on downloaded videos
//            videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            
            let naturalSize = videoTrack.naturalSize
            let renderSize: CGSize
            
            if naturalSize.width > naturalSize.height {
                renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            }else{
                renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
            }
            
            videoComposition.renderSize = renderSize

            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: timeRange.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack!)
            layerInstruction.setTransform(transform, at: .zero)
            instruction.layerInstructions = [layerInstruction]

            videoComposition.instructions = [instruction]

            let fileManager = FileManager.default
            let outputURL = generateUniqueOutputURL()

            if fileManager.fileExists(atPath: outputURL.path) {
                try? fileManager.removeItem(at: outputURL)
            }

            let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
            exporter?.outputURL = outputURL
            exporter?.outputFileType = .mp4
            exporter?.videoComposition = videoComposition
            exporter?.shouldOptimizeForNetworkUse = true

            exporter?.exportAsynchronously(completionHandler: {
                switch exporter?.status {
                case .completed:
                    // Exporting is successful
                    completion(outputURL, nil)

                case .failed, .cancelled:
                    // Exporting failed or was cancelled
                    let error = exporter?.error ?? NSError(domain: "Exporting failed", code: 0, userInfo: nil)
                    completion(nil, error)

                default:
                    break
                }
            })
        } catch {
            // Error occurred while exporting the video
            let error = NSError(domain: "Exporting error", code: 0, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
            completion(nil, error)
        }
    }

    ///Remaining video Unique Video url
    func generateUniqueOutputURL() -> URL {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory

        var outputURL = tempDirectory.appendingPathComponent(UUID().uuidString)
        outputURL.appendPathExtension("mp4")

        return outputURL
    }

    func mergeVideos(arrayVideos: [AVAsset], completion: @escaping (URL?, Error?) -> ()) {
        let mainComposition = AVMutableComposition()
        let compositionVideoTrack = mainComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = mainComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        var insertTime = CMTime.zero

        for videoAsset in arrayVideos {
            guard let videoTrack = videoAsset.tracks(withMediaType: .video).first,
                  let audioTrack = videoAsset.tracks(withMediaType: .audio).first else {
                completion(nil, NSError(domain: "Video or audio track not found", code: 0, userInfo: nil))
                return
            }

            try? compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoTrack, at: insertTime)
            try? compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: audioTrack, at: insertTime)

            insertTime = CMTimeAdd(insertTime, videoAsset.duration)
        }

        let outputFileURL = generateUniqueOutputURL()

        let composition = AVAssetExportSession(asset: mainComposition, presetName: AVAssetExportPresetHighestQuality)
        composition?.outputURL = outputFileURL
        composition?.outputFileType = AVFileType.mp4
        composition?.shouldOptimizeForNetworkUse = true

        composition?.exportAsynchronously {
            if let url = composition?.outputURL {
                completion(url, nil)
            } else if let error = composition?.error {
                completion(nil, error)
            }
        }
    }

}

//MARK: Play Out Put Video
extension AddWaterMarkViewController {
    
    //PLay VIdeo after succefully add watermark
    func playOutputVideo(_ videoURL: URL) {
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player

        present(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
    }

 
    ///Save video in the photos
    func saveVideoToLibrary(videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { success, error in
            if success {
                // Video saved successfully
                print("Video saved to photo library")
            } else {
                // Saving video failed
                print("Error saving video to photo library:", error?.localizedDescription ?? "")
            }
        }
    }
    
}

