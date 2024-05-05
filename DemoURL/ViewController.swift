//
//  ViewController.swift
//  DemoURL
//
//  Created by 劉晉賢 on 2024/5/1.
//
import UIKit
import RxSwift
import RxCocoa
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var searchTextfield: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBOutlet weak var resultCollectionVew: UICollectionView!
    
    private var dispose = DisposeBag()
    
    private var playObservation: NSKeyValueObservation?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private let viewModel = ViewModel()
    private var itemSizes: [CGSize] = []
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = self.view.center
        return activityIndicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanObserver()
    }
}

extension ViewController {
    
    private func setView() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        self.view.layer.addSublayer(playerLayer!)
        
        playObservation = player?.observe(\.rate, options: [.new, .old]) { [weak self] player, change in
            guard let self = self else { return }
            self.viewModel.isPlay.accept(change.newValue == 1 ? true : false)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        resultCollectionVew.register(UINib(nibName: "ResultCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ResultCollectionViewCell")
    }
    
    private func setViewModel() {
        
        viewModel.setLoading.subscribe(onNext: { [weak self] in
            self?.activityIndicator.center = self!.view.center
            self?.view.addSubview(self!.activityIndicator)
            self?.activityIndicator.startAnimating()
        }).disposed(by: dispose)
        
        viewModel.stopLoading.subscribe(onNext: { [weak self] in
            self?.activityIndicator.stopAnimating()
        }).disposed(by: dispose)
        
        viewModel.presentToVC.subscribe(onNext: { [weak self] vc in
            self?.present(vc, animated: true)
        }).disposed(by: dispose)
        
        viewModel.setPlayerMusic.subscribe(onNext: { [weak self] url in
            self?.startPlayer(audioURL: url!)
        }).disposed(by: dispose)
        
        viewModel.stopPlayer.subscribe(onNext: { [weak self]  in
            self?.player?.pause()
        }).disposed(by: dispose)
        
        viewModel.startPlayer.subscribe(onNext: { [weak self]  in
            self?.player?.play()
        }).disposed(by: dispose)
        
        let inputs = ViewModel.Input(searchText: searchTextfield.rx.text.orEmpty.distinctUntilChanged().asObservable(),
                                          validate: searchButton.rx.tap.asObservable())
        
        let output = viewModel.transform(input: inputs)
        output.cellViewModels.asDriver().drive(resultCollectionVew.rx.items(cellIdentifier: "ResultCollectionViewCell", cellType: ResultCollectionViewCell.self)) {  _, model, cell in
            cell.bind(to: model)
        }.disposed(by: dispose)
        
        output.cellSizes.drive(onNext: { [weak self] sizes in
            guard let self = self else { return }
            self.itemSizes = sizes
            self.resultCollectionVew.collectionViewLayout.invalidateLayout()
        }).disposed(by: dispose)
        
        resultCollectionVew.rx.itemSelected.map({ $0.item }).subscribe(onNext: { [weak self] row in
            guard let self = self else { return }
            self.viewModel.setPlayer(row: row)
        }).disposed(by: dispose)
        
        resultCollectionVew.rx.setDelegate(self).disposed(by: dispose)
    }
    
    @objc private func playerDidFinishPlaying(_ notification: Notification) {
        viewModel.setPlayer(row: nil)
    }
    
    private func startPlayer(audioURL: URL) {
        let newPlayerItem = AVPlayerItem(url: audioURL)
        player?.replaceCurrentItem(with: newPlayerItem)
        player?.play()
    }
    
    private func cleanObserver() {
        dispose = DisposeBag()
        player = nil
        playObservation?.invalidate()
        playObservation = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        itemSizes[indexPath.row]
    }
}
