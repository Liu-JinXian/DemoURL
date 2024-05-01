//
//  ResultCollectionViewMdoel.swift
//  DemoURL
//
//  Created by 劉晉賢 on 2024/5/1.
//
import RxSwift
import RxCocoa
import SDWebImage

class ResultCollectionViewMdoel {
    
    let trackName = BehaviorRelay<String>(value: "")
    let longDescription = BehaviorRelay<String>(value: "")
    let time = BehaviorRelay<String>(value: "")
    let previewUrl = BehaviorRelay<String>(value: "")
    let playStaus = BehaviorRelay<String>(value: "")
    var item: SearchResultResponse.Result?
    
    private var picUrl: String?
    private var isPlayer: Bool = false
    
    func setViewModel(item: SearchResultResponse.Result) {
        self.item = item
        self.trackName.accept(item.trackName ?? "")
        self.longDescription.accept(item.longDescription ?? "")
        self.previewUrl.accept(item.previewUrl ?? "")
        
        let totalSeconds = (item.trackTimeMillis ?? 0) / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        self.time.accept("\(minutes):\(seconds)")
        
        self.picUrl = item.artworkUrl100
    }
    
    func downImage(completion: @escaping (UIImage?)->()) {
        
        guard let url = self.picUrl else { return }
        SDWebImageManager.shared.loadImage(with: URL(string: url), options: SDWebImageOptions.retryFailed, progress: nil, completed: { (image, data, error, cacheType, bool, imageURL) in
            
            if error == nil {
                completion(image)
            }
        })
    }
    
    func setPlayStatus(playStatus: SearchResultResponse.PlayStatus) {
        
        switch playStatus {
        case .noplay:
            playStaus.accept("")
        case .playing:
            playStaus.accept("正在播放 ▶️")
        case .stop:
            playStaus.accept("暫停播放 ⏸️")
        }
    }
}
