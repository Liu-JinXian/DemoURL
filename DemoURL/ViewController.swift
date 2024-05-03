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
    @IBOutlet weak var resultCollectionVew: UICollectionView!
    
    private var dispose = DisposeBag()
    private let viewModel = ViewModel()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
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
        dispose = DisposeBag()
    }
}

extension ViewController {
    private func setView() {
        searchTextfield.rx.text.orEmpty.bind(to: viewModel.searchText).disposed(by: dispose)
        
        playerLayer = AVPlayerLayer(player: player)
        self.view.layer.addSublayer(playerLayer!)
        
        resultCollectionVew.dataSource = self
        resultCollectionVew.delegate = self
        resultCollectionVew.register(UINib(nibName: "ResultCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ResultCollectionViewCell")
    }
    
    private func setViewModel() {
        
        searchTextfield.rx.controlEvent([.editingChanged]).asObservable().subscribe ({ [weak self] _ in
            self?.viewModel.getSearchResult()
            self?.stopPlayer()
            self?.viewModel.setPlayerNil()
        }).disposed(by: dispose)
        
        viewModel.reloadData.subscribe(onNext: { [weak self] in
            self?.resultCollectionVew.reloadData()
        }).disposed(by: dispose)
        
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
    }
    
    @objc private func playerDidFinishPlaying(_ notification: Notification) {
        stopPlayer()
        viewModel.setPlayerNil()
    }
    
    private func stopPlayer() {
        guard player != nil else { return }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        self.player!.pause()
        self.player!.replaceCurrentItem(with: nil)
        self.player = nil
    }
    
    private func startPlayer(audioURL: URL) {
        player = AVPlayer(url: audioURL)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        player?.play()
    }
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.setNumberOfItemsInSection()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCollectionViewCell", for: indexPath) as! ResultCollectionViewCell
        cell.setCell(viewModel: viewModel.cellViewModels[indexPath.row])
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return viewModel.setSizeForItemAt(row: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let isPlay: Bool = player?.rate == 0 ? false : true
        
        let (isPlayer, audioURL) = viewModel.setPlayer(row: indexPath.row, isPlay: isPlay)
                
        switch isPlayer {
        case .create:
            guard let audioURL = audioURL else { return }
            self.startPlayer(audioURL: audioURL)
        case .cover:
            guard let audioURL = audioURL else { return }
            self.stopPlayer()
            self.startPlayer(audioURL: audioURL)
        case .stop:
            if isPlay {
                player!.pause()
            } else {
                player!.play()
            }
        case .none:
            return
        }
    }
}
