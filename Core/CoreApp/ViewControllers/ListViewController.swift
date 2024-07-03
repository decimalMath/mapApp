//
//  ListViewController.swift
//  Core
//
//  Created by LL on 7/20/22.
//

import Foundation
import UIKit
import MapKit
import SnapKit
import Combine

class ListViewController: UIViewController {

    private var contentApp: StateApp<ContentApp>
    private let repo: Repository<Venue>
    private let searchController = UISearchController(searchResultsController: nil)
    private let searchManager = LocationSearchManager()
    private var lastOp: Operation?

    private var collectionView: UICollectionView!
    private var bag = Set<AnyCancellable>()
    private let compositionalLayout: UICollectionViewCompositionalLayout = {
        let fractionWidth: CGFloat = 1
        let fractionHeight: CGFloat = 1 / 2
        let inset: CGFloat = 2.5

        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fractionWidth), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)

        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(fractionHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        return UICollectionViewCompositionalLayout(section: section)
    }()

    init() {
        repo = Repository<Venue>()

        searchManager.startUpdatingLocation()

        contentApp = StateApp<ContentApp>(
            helpers: .init(venueRepo: repo)
        )
        
        super.init(nibName: nil, bundle: nil)

        defaultSearch()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = repo.dispatch(.reloadItems)
    }

    private func defaultSearch() {
        let minutesDiffFromNow = """
            ABS(
                (strftime('%H', timeOfDay) * 60 + strftime('%M', timeOfDay)) -
                (strftime('%H', 'now') * 60 + strftime('%M', 'now'))
            )
        """

        let query = repo.stateApp.helpers.modelBuilder.defaultQuery()
        query.addFilter(expression: "\(minutesDiffFromNow) <= 30")
        query.addSort(expression: "\(minutesDiffFromNow) ASC")
        _ = repo.dispatch(.set(query: query))

        contentApp.dispatch(.checkForData)
    }

    private func setup() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ListItemCell.self, forCellWithReuseIdentifier: "listItemCell")
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        repo.stateApp.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.collectionView.reloadData()
        }.store(in: &bag)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Add new places"
        navigationItem.searchController = searchController
        definesPresentationContext = true

    }
}

extension ListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return repo.stateApp.state.totalCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "listItemCell", for: indexPath) as? ListItemCell else {
            fatalError()
        }

        if let venue = repo.get(itemAt: indexPath.row) {
            cell.imageView.image = nil
            cell.identifier = venue.id
            cell.configure(text: "\(venue.title)")
            let coordinate = CLLocationCoordinate2D(latitude: venue.latitude!, longitude: venue.longitude!)
            // Retrieving a cached image (also checks availability)
            if let cachedImage = ImageCache.shared.getCachedImage(withID: venue.id) {
                // Use the cached image
                cell.imageView.image = cachedImage
            } else {
                searchManager.generateMapImage(for: coordinate, size: cell.frame.size) { [weak cell] image in
                    guard let cell = cell, let mapImage = image else { return }
                    guard cell.identifier == venue.id else {return}
                    _ = ImageCache.shared.saveImage(mapImage, withID: venue.id)
                    DispatchQueue.main.async {
                        cell.imageView.image = mapImage
                    }
                }
            }


        } else {
            cell.configure(text: "")
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let venue = repo.get(itemAt: indexPath.row) else { return }

        contentApp.dispatch(.selectedVenue(item: venue))

        defaultSearch()
    }
}

extension ListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        lastOp?.cancel()

        if let queryText = searchController.searchBar.text, !queryText.isEmpty {
            searchManager.performSearch(searchBarText: queryText) { [weak self] items in
                guard let self = self, let items = items else { return }
                let venues: [Venue] = items.map {
                    Venue(
                        title: $0.name ?? "",
                        address: $0.name ?? "",
                        latitude: $0.placemark.location?.coordinate.latitude,
                        longitude: $0.placemark.location?.coordinate.longitude,
                        timeOfDay: nil
                    )
                }

                _ = contentApp.dispatch(.saveVenues(item: venues))
            }
            let query = repo.stateApp.helpers.modelBuilder.searchQuery()
            query.addFilter(field: .title, expression: "MATCH \"\(queryText)\"")
            lastOp = repo.dispatch(.set(query: query))
        } else {
            defaultSearch()
            searchManager.stopUpdatingLocation()
        }
        contentApp.dispatch(.checkForData)
    }
}
