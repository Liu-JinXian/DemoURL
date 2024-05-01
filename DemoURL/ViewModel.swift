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
    let searchText = BehaviorRelay<String>(value: "")
    
    private let dispose = DisposeBag()
    private var isPlayerRow: Int? = nil
    private(set) var cellViewModels: [ResultCollectionViewMdoel] = []
    
    func setSubscribe() {
        searchText.subscribe(onNext: { [weak self] newValue in
            if newValue == "" { return }
            self?.getSearchResult()
        }).disposed(by: dispose)
    }
    
    func getSearchResult() {
        let params: [String: Any] = ["term": searchText.value]
        let api = ApiManager.shared.mangers(object: SearchResultResponse.self, method: .get, url: searchURL, parameters: params)
        
//        let api = ApiManager.shared.getStructJson(object: SearchResultResponse.self, forResource: "Result")
        setLoading.onNext(())
        
        api.subscribe(onSuccess: { [weak self] model in
            if let response = model {
                self?.setCellViewModel(model: response)
            }
            self?.stopLoading.onNext(())
        }, onError: { (error) in
            
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
    
    func setPlayer(row: Int) -> (PlayerStatus, URL?) {
            
        if isPlayerRow == nil {
            print("DEBUG create")
            self.isPlayerRow = row
            let url = cellViewModels[row].previewUrl.value
            guard let audioURL = URL(string: url) else { return (.none, nil) }
            cellViewModels[row].setPlayStatus(playStatus: .playing)
            return (.create, audioURL)
        }else if isPlayerRow != row {
            print("DEBUG cover")
            cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
            let url = cellViewModels[row].previewUrl.value
            guard let audioURL = URL(string: url) else { return (.none, nil) }
            cellViewModels[row].setPlayStatus(playStatus: .playing)
            self.isPlayerRow = row
            return (.cover, audioURL)
        }else {
            print("DEBUG stop")
            cellViewModels[row].setPlayStatus(playStatus: .stop)
            return (.stop, nil)
        }
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
}
