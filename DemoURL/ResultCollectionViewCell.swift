//
//  ResultCollectionViewCell.swift
//  DemoURL
//
//  Created by 劉晉賢 on 2024/5/1.
//
import UIKit
import RxSwift


class ResultCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var longDescription: UILabel!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var playStaus: UILabel!
    
    private var dispose = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dispose = DisposeBag()
    }
    
    func bind(to viewModel: ResultCollectionViewMdoel) {
        viewModel.trackName.bind(to: trackName.rx.text).disposed(by: dispose)
        viewModel.longDescription.bind(to: longDescription.rx.text).disposed(by: dispose)
        viewModel.time.bind(to: time.rx.text).disposed(by: dispose)
        viewModel.playStaus.bind(to: playStaus.rx.text).disposed(by: dispose)
        viewModel.downImage { [weak self] image in
            self?.imageView.image = image
        }
        self.cardView.layoutIfNeeded()
    }
}
