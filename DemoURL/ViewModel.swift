//
//  ViewModel.swift
//  DemoURL
//
//  Created by 劉晉賢 on 2024/5/1.
//
import RxSwift
import RxCocoa
import UIKit
import AVKit

protocol ViewModelType {
    
    associatedtype Input
    associatedtype Output
    
    var input: Input { get }
    var output: Output { get }
    
    func transform(input: Input) -> Output
}

public enum AvplayerChangeStatus {
    case play
    case stop
    case setUrl
    case none
}

class ViewModel: ViewModelType {
    
    let setLoading = PublishSubject<()>()
    let stopLoading = PublishSubject<()>()
    let presentToVC = PublishSubject<(UIAlertController)>()
    
    let cellViewModelsRelay = BehaviorRelay<[ResultCollectionViewMdoel]>(value: [])
    let playerStatus = BehaviorRelay<AVPlayer.TimeControlStatus>(value: .paused)
    
    private var isPlayerRow: Int? = nil
    private let dispose = DisposeBag()
    
    var input: Input
    var output: Output
    
    struct Input {
        let searchText: Observable<String>
        let validate: Observable<Void>
        let cellIsSelected: Observable<IndexPath>
    }
    
    struct Output {
        let cellViewModels: BehaviorRelay<[ResultCollectionViewMdoel]>
        let cellSizes: Driver<[CGSize]>
        let setPlayer: Driver<(AvplayerChangeStatus, URL?)>
    }
    
    init() {
        input = Input(searchText: Observable.just(""), validate: Observable.just(()), cellIsSelected: Observable.just(IndexPath(item: 0, section: 0)))
        output = Output(cellViewModels: cellViewModelsRelay, cellSizes: Driver.just([]), setPlayer: Driver.just((.none, nil)))
    }
    
    func transform(input: Input) -> Output {
        
        let resultList = input.validate
            .withLatestFrom(input.searchText).flatMapLatest { [weak self] text -> Observable<[SearchResultResponse.Result]> in
                guard let self = self else { return Observable.just([])}
                return self.getSearchResult(searchword: text)
            }.asDriver(onErrorJustReturn: [])
        
        let cellViewModels = resultList.map { result in
            return result.map { test in ResultCollectionViewMdoel(item: test)}
        }.do(onNext: { [weak self] models in
            self?.cellViewModelsRelay.accept(models)
        }).asDriver(onErrorJustReturn: [])
        
        let cellSizes = cellViewModels.map { models in
            models.map { model in
                return self.setSizeForItemAt(cellViewModel: model)
            }
        }
        
        let setPlayer = input.cellIsSelected
            .withLatestFrom(cellViewModels) { indexPath, models in
                return (indexPath, models)
            }
            .flatMapLatest { indexPath, models -> Driver<(AvplayerChangeStatus,URL?)> in
                
                let (status, url) = self.chagePlayer(selectRow: indexPath.row)
                return Driver.just((status, url))
            }.asDriver(onErrorJustReturn: (.none, nil))
    
        return Output(cellViewModels: cellViewModelsRelay, cellSizes: cellSizes, setPlayer: setPlayer)
    }
    
    func chagePlayer(selectRow: Int?) -> (AvplayerChangeStatus, URL?) {
        let cellViewModels = output.cellViewModels.value
        
        if cellViewModels.count == 0 {
            self.isPlayerRow = selectRow
            return (.none, nil)
        }
        
        if selectRow == nil && isPlayerRow == nil {
            self.isPlayerRow = selectRow
            return (.none, nil)
        }
        
        guard let newValue = selectRow else {
            cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
            self.isPlayerRow = selectRow
            return (.none, nil)
        }
        
        if isPlayerRow != newValue && isPlayerRow != nil {
            cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
        }
        
        if isPlayerRow == newValue {
            cellViewModels[newValue].setPlayStatus(playStatus: playerStatus.value == .playing ? .stop : .playing)
            self.isPlayerRow = selectRow
            return (playerStatus.value == .playing ? .stop : .play, nil)
        }
        
        cellViewModels[newValue].setPlayStatus(playStatus: .playing)
        let url = cellViewModels[newValue].previewUrl.value
        guard let audioURL = URL(string: url) else { return (.none, nil) }
        self.isPlayerRow = selectRow
        return (.setUrl, audioURL)
    }
    
    func finishPlayer() {
        let cellViewModels = output.cellViewModels.value
        if cellViewModels.count == 0 || isPlayerRow == nil { return }
        
        cellViewModels[isPlayerRow!].setPlayStatus(playStatus: .noplay)
        self.isPlayerRow = nil
    }
}

extension ViewModel {
    private func getSearchResult(searchword: String) -> Observable<[SearchResultResponse.Result]> {
        
        return Observable.create { observer in
            
            let params: [String: Any] = ["term": searchword]
            let api = ApiManager.shared.mangers(object: SearchResultResponse.self, method: .get, url: searchURL, parameters: params)
            
            self.setLoading.onNext(())
            
            api.subscribe(onSuccess: { [weak self] model in
                self?.stopLoading.onNext(())
                observer.onNext(model?.results ?? [])
                observer.onCompleted()
            },onError: { [weak self] (error) in
                self?.setAlert(title: "Api錯誤", error: "\(error)")
                self?.stopLoading.onNext(())
                observer.onError(error)
            }).disposed(by: self.dispose)
            
            return Disposables.create()
        }
    }
    
    private func setAlert(title: String, error: String) {
        let alertSever: UIAlertController = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let action = UIAlertAction(title: "確定", style: UIAlertAction.Style.default, handler: nil)
        alertSever.addAction(action)
        self.presentToVC.onNext((alertSever))
    }
    
    private func textSize(text: String, font: UIFont, maxSize: CGSize) -> CGSize {
        
        return text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font : font], context: nil).size
    }
    
    private func setSizeForItemAt(cellViewModel: ResultCollectionViewMdoel) -> CGSize {
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let textFont = UIFont.init(name: "PingFang-TC-Regular", size: 15)!
        let textMaxSize = CGSize(width: screenWidth - 32, height: screenHeight)
        
        let trackNameString = cellViewModel.trackName.value
        let trackNameLabelSize = self.textSize(text: trackNameString, font: textFont, maxSize: textMaxSize)
        
        let longDescriptionString = cellViewModel.longDescription.value
        let longDescriptionLabelSize = self.textSize(text: longDescriptionString, font: textFont, maxSize: textMaxSize)
        
        let hieght = trackNameLabelSize.height + longDescriptionLabelSize.height + 48
        
        return CGSize(width: screenWidth, height: hieght < 220 ? 220 : hieght)
    }
}
