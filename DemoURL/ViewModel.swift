//
//  ViewModel.swift
//  DemoURL
//
//  Created by 劉晉賢 on 2024/5/1.
//
import RxSwift
import RxCocoa
import UIKit

class ViewModel {
    
    let reloadData = PublishSubject<()>()
    let setLoading = PublishSubject<()>()
    let stopLoading = PublishSubject<()>()
    let presentToVC = PublishSubject<(UIAlertController)>()
    let setPlayerMusic = PublishSubject<(URL?)>()
    let stopPlayer = PublishSubject<()>()
    let startPlayer = PublishSubject<()>()
    
    let searchText = BehaviorRelay<String>(value: "")
    let isPlay = BehaviorRelay<Bool>(value: false)
    
    private let dispose = DisposeBag()
    private let cellViewModelLock = NSLock()
    private(set) var cellViewModels: [ResultCollectionViewMdoel] = []
    
    private var isPlayerRow: Int? = nil {
        willSet {
            
            if newValue == nil && isPlayerRow == nil { return }
            
            // 重新搜尋時會為nil，清除播放
            guard let newValue = newValue else {
                cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
                return
            }
            
            if isPlayerRow != newValue && isPlayerRow != nil {
                cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
            }
            
            if isPlayerRow == newValue {
                cellViewModels[newValue].setPlayStatus(playStatus: isPlay.value ? .stop : .playing)
                isPlay.value == true ? stopPlayer.onNext(()) : startPlayer.onNext(())
                return
            }
            
            cellViewModels[newValue].setPlayStatus(playStatus: .playing)
            let url = cellViewModels[newValue].previewUrl.value
            guard let audioURL = URL(string: url) else { return }
            setPlayerMusic.onNext((audioURL))
        }
    }
    
    func getSearchResult() {
        
        DispatchQueue.global().async { [weak self] in
            
            let params: [String: Any] = ["term": self!.searchText.value]
            let api = ApiManager.shared.mangers(object: SearchResultResponse.self, method: .get, url: searchURL, parameters: params)
            
            DispatchQueue.main.async {
                self?.setLoading.onNext(())
            }
            
            api.subscribe(onSuccess: { [weak self] model in
                DispatchQueue.main.async {
                    if let response = model {
                        self?.setCellViewModel(model: response)
                        self?.stopLoading.onNext(())
                    }else {
                        self?.setAlert(title: "沒有資料", error: "請重新搜尋")
                    }
                }
                
            }, onError: { [weak self] (error) in
                DispatchQueue.main.async {
                    self?.setAlert(title: "Api錯誤", error: "\(error)")
                    self?.stopLoading.onNext(())
                }
            }).disposed(by: self!.dispose)
        }
    }
    
    func setNumberOfItemsInSection() -> Int {
        return cellViewModels.count
    }
    
    func setSizeForItemAt(row: Int) -> CGSize {
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let textFont = UIFont.init(name: "PingFang-TC-Regular", size: 15)!
        let textMaxSize = CGSize(width: screenWidth - 32, height: screenHeight)
        
        let trackNameString = cellViewModels[row].trackName.value
        let trackNameLabelSize = self.textSize(text: trackNameString, font: textFont, maxSize: textMaxSize)
        
        let longDescriptionString = cellViewModels[row].longDescription.value
        let longDescriptionLabelSize = self.textSize(text: longDescriptionString, font: textFont, maxSize: textMaxSize)
        
        let hieght = trackNameLabelSize.height + longDescriptionLabelSize.height + 48
        
        return CGSize(width: screenWidth, height: hieght)
    }
    
    func setPlayer(row: Int?) {
        self.isPlayerRow = row
    }
}

extension ViewModel {
    
    private func setCellViewModel(model: SearchResultResponse) {
        
        cellViewModelLock.lock()
        
        defer {
            cellViewModelLock.unlock()
        }
        
        cellViewModels = []
        
        model.results?.forEach { item in
            let viewModel = ResultCollectionViewMdoel()
            viewModel.setViewModel(item: item)
            cellViewModels.append(viewModel)
        }
        
        self.reloadData.onNext(())
    }
    
    private func textSize(text: String, font: UIFont, maxSize: CGSize) -> CGSize {
        
        return text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font : font], context: nil).size
    }
    
    private func setAlert(title: String, error: String) {
        let alertSever: UIAlertController = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let action = UIAlertAction(title: "確定", style: UIAlertAction.Style.default, handler: nil)
        alertSever.addAction(action)
        self.presentToVC.onNext((alertSever))
    }
}
