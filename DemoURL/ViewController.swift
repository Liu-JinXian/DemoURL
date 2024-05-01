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
    
    private let dispose = DisposeBag()
    private let viewModel = ViewModel()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let activityIndicatorView = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setViewModel()
    }
}

extension ViewController {
    private func setView() {
        searchTextfield.rx.text.orEmpty.bind(to: viewModel.searchText).disposed(by: dispose)
        resultCollectionVew.dataSource = self
        resultCollectionVew.delegate = self
        resultCollectionVew.register(UINib(nibName: "ResultCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ResultCollectionViewCell")
    }
    
    private func setViewModel() {
        viewModel.setSubscribe()
        
        viewModel.reloadData.subscribe(onNext: { [weak self] in
            self?.resultCollectionVew.reloadData()
        }).disposed(by: dispose)
        
        viewModel.setLoading.subscribe(onNext: { [weak self] in
            self?.activityIndicatorView.center = self!.view.center
            self?.view.addSubview(self!.activityIndicatorView)
            self?.activityIndicatorView.startAnimating()
        }).disposed(by: dispose)
        
        viewModel.stopLoading.subscribe(onNext: { [weak self] in
            self?.activityIndicatorView.stopAnimating()
        }).disposed(by: dispose)
    }
    
    @objc private func playerDidFinishPlaying(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        player = nil
        print("播放完畢")
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
        
        let (isPlayer, audioURL) = viewModel.setPlayer(row: indexPath.row)
                
        switch isPlayer {
        case .create:
            guard let audioURL = audioURL else { return }
            player = AVPlayer(url: audioURL)
            playerLayer = AVPlayerLayer(player: player)
            view.layer.addSublayer(playerLayer!)
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
            player?.play()
        case .cover:
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
            player = nil
            guard let audioURL = audioURL else { return }
            player = AVPlayer(url: audioURL)
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
            player?.play()
        case .stop:
            if player!.rate == 0 {
                player!.play()
            } else {
                player!.pause()
            }
        case .none:
            return
        }
    }
}
