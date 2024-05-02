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
    
    enum PlayerStatus {
        case create
        case cover
        case stop
        case none
    }
    
    let reloadData = PublishSubject<()>()
    let setLoading = PublishSubject<()>()
    let stopLoading = PublishSubject<()>()
    let presentToVC = PublishSubject<(UIAlertController)>()
    let searchText = BehaviorRelay<String>(value: "")
    
    private let dispose = DisposeBag()
    private var isPlayerRow: Int? = nil
    private(set) var cellViewModels: [ResultCollectionViewMdoel] = []
    
    func getSearchResult() {
        
        self.setPlayerNil()
        
        let params: [String: Any] = ["term": searchText.value]
        let api = ApiManager.shared.mangers(object: SearchResultResponse.self, method: .get, url: searchURL, parameters: params)
        
        setLoading.onNext(())
        
        api.subscribe(onSuccess: { [weak self] model in
            
            guard let response = model else {
                self?.setAlert(title: "沒有資料", error: "請重新搜尋")
                return
            }
            self?.setCellViewModel(model: response)
            self?.stopLoading.onNext(())
            
        }, onError: { [weak self] (error) in
            self?.setAlert(title: "Api錯誤", error: "\(error)")
            self?.stopLoading.onNext(())
        }).disposed(by: dispose)
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
    
    func setPlayer(row: Int, isPlay: Bool) -> (PlayerStatus, URL?) {
            
        if isPlayerRow == nil {
            self.isPlayerRow = row
            let url = cellViewModels[row].previewUrl.value
            guard let audioURL = URL(string: url) else { return (.none, nil) }
            cellViewModels[row].setPlayStatus(playStatus: .playing)
            return (.create, audioURL)
        }else if isPlayerRow != row {
            cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
            let url = cellViewModels[row].previewUrl.value
            guard let audioURL = URL(string: url) else { return (.none, nil) }
            cellViewModels[row].setPlayStatus(playStatus: .playing)
            self.isPlayerRow = row
            return (.cover, audioURL)
        }else {
            cellViewModels[row].setPlayStatus(playStatus: isPlay ? .stop : .playing)
            return (.stop, nil)
        }
    }
    
    func setPlayerNil() {
        if isPlayerRow == nil { return }
        cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
        self.isPlayerRow = nil
    }
}

extension ViewModel {
    
    private func setCellViewModel(model: SearchResultResponse) {
        
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
