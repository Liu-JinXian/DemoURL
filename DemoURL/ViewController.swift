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
    private var playObservation: NSKeyValueObservation?
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
        cleanObserver()
    }
}

extension ViewController {
    private func setView() {
        searchTextfield.rx.text.orEmpty.bind(to: viewModel.searchText).disposed(by: dispose)
        
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        self.view.layer.addSublayer(playerLayer!)
        
        playObservation = player?.observe(\.rate, options: [.new, .old]) { [weak self] player, change in
            guard let self = self else { return }
            self.viewModel.isPlay.accept(change.newValue == 1 ? true : false)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        resultCollectionVew.dataSource = self
        resultCollectionVew.delegate = self
        resultCollectionVew.register(UINib(nibName: "ResultCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ResultCollectionViewCell")
    }
    
    private func setViewModel() {
        
        searchTextfield.rx.controlEvent([.editingChanged]).asObservable().subscribe ({ [weak self] _ in
            self?.player?.replaceCurrentItem(with: nil)
            self?.viewModel.setPlayer(row: nil)
            self?.viewModel.getSearchResult()
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
        
        viewModel.setPlayerMusic.subscribe(onNext: { [weak self] url in
            self?.startPlayer(audioURL: url!)
        }).disposed(by: dispose)
        
        viewModel.stopPlayer.subscribe(onNext: { [weak self]  in
            self?.player?.pause()
        }).disposed(by: dispose)
        
        viewModel.startPlayer.subscribe(onNext: { [weak self]  in
            self?.player?.play()
        }).disposed(by: dispose)
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
        
        viewModel.setPlayer(row: indexPath.row)
    }
}
