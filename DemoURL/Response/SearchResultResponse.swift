//
//  SearchResultResponse.swift
//  DemoURL
//
//  Created by 劉晉賢 on 2024/5/1.
//

import Foundation

struct SearchResultResponse: Codable, Hashable{
    
    enum PlayStatus {
        case noplay
        case playing
        case stop
    }
    
    let resultCount: Int?
    let results: [Result]?
    
    struct Result: Codable, Hashable {
        let wrapperType: String?
        let kind: String?
        let collectionId: Int?
        let trackId: Int?
        let artistName: String?
        let collectionName: String?
        let trackName: String?
        let collectionCensoredName: String?
        let trackCensoredName: String?
        let collectionArtistId: Int?
        let collectionArtistViewUrl: String?
        let collectionViewUrl: String?
        let trackViewUrl: String?
        let previewUrl: String?
        let artworkUrl30: String?
        let artworkUrl60: String?
        let artworkUrl100: String?
        let collectionPrice: Double?
        let trackPrice: Double?
        let trackRentalPrice: Double?
        let collectionHdPrice: Double?
        let trackHdPrice: Double?
        let trackHdRentalPrice: Double?
        let releaseDate: String?
        let collectionExplicitness: String?
        let trackExplicitness: String?
        let discCount: Int?
        let discNumber: Int?
        let trackCount: Int?
        let trackNumber: Int?
        let trackTimeMillis: Int?
        let country: String?
        let currency: String?
        let primaryGenreName: String?
        let contentAdvisoryRating: String?
        let shortDescription: String?
        let longDescription: String?
        let hasITunesExtras: Bool?
        
        var playStatus: PlayStatus = .noplay
        
        enum CodingKeys: String, CodingKey {
            case wrapperType
            case kind
            case collectionId
            case trackId
            case artistName
            case collectionName
            case trackName
            case collectionCensoredName
            case trackCensoredName
            case collectionArtistId
            case collectionArtistViewUrl
            case collectionViewUrl
            case trackViewUrl
            case previewUrl
            case artworkUrl30
            case artworkUrl60
            case artworkUrl100
            case collectionPrice
            case trackPrice
            case trackRentalPrice
            case collectionHdPrice
            case trackHdPrice
            case trackHdRentalPrice
            case releaseDate
            case collectionExplicitness
            case trackExplicitness
            case discCount
            case discNumber
            case trackCount
            case trackNumber
            case trackTimeMillis
            case country
            case currency
            case primaryGenreName
            case contentAdvisoryRating
            case shortDescription
            case longDescription
            case hasITunesExtras
        }
    }
}
