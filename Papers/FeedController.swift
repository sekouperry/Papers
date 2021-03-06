//
//  ViewController.swift
//  Papers
//
//  Created by Don Bytyqi on 5/4/17.
//  Copyright © 2017 Don Bytyqi. All rights reserved.
//

import UIKit
import GoogleMobileAds

var photoQuality = "regular"

class FeedController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, GADBannerViewDelegate, PhotoQualityDelegate {
    
    let ud = UserDefaults.standard
    
    func photo(withQuality: String) {
        print("NEW QUALITY IS: ", withQuality)
        photoQuality = withQuality
        ud.set(photoQuality, forKey: "photoQ")
        ud.synchronize()
        PhotoAPIManager.shared.fetchPhotos(url: "", orderBy: currentOrder!, page: n, query: currentQuery, quality: photoQuality) { (photos: [Photo]) in
            print("quality: ->", photoQuality)
            self.photos = photos
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top
                , animated: true)
            self.collectionView?.reloadData()
        }
    }
    
    
    private let cellId = "cellId"
    private let headerId = "headerId"
    private var indexPaths = [IndexPath]()
    
    var currentURL = String()
    var currentOrder: OrderBy?
    var photos: [Photo]?
    var n = 1
    var currentQuery = String()
    var previousQuality = ""
    
    var moreButton: UIBarButtonItem?
    var searchButton: UIBarButtonItem?
    
    func fetchPhotos() {
        PhotoAPIManager.shared.fetchPhotos(url: "", orderBy: currentOrder!, page: n, query: currentQuery, quality: photoQuality) { (photos: [Photo]) in
            self.photos = photos
            self.collectionView?.reloadData()
        }
    }
    
    func fetchMorePhotos() {
        n += 1
        print(n)
        if currentQuery != "" {
            PhotoAPIManager.shared.fetchPhotos(url: "s", orderBy: currentOrder!, page: n, query: currentQuery, quality: photoQuality) { (photos: [Photo]) in
                for photo in photos {
                    self.photos?.append(photo)
                }
                self.collectionView?.reloadData()
            }
        }
        else {
            PhotoAPIManager.shared.fetchPhotos(url: "", orderBy: currentOrder!, page: n, query: currentQuery, quality: photoQuality) { (photos: [Photo]) in
                for photo in photos {
                    self.photos?.append(photo)
                }
                self.collectionView?.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarButtons()
        setupNavBarAndCollectionView()
        fetchPhotos()
        
        previousQuality = photoQuality
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if ud.string(forKey: "photoQ") != nil {
            guard let photoQualityValue = ud.string(forKey: "photoQ") else { return }
            photoQuality = photoQualityValue
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PhotoCell
        cell.photo = photos?[indexPath.item]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showPhotoInfo(atIndex: indexPath)
    }
    
    func showPhotoInfo(atIndex: IndexPath) {
        let photoInfoController = PhotoInfoController()
//        photoInfoController.photo = photos?[atIndex.item]
        photoInfoController.photoViewer.photo = photos?[atIndex.item]
        self.navigationController?.pushViewController(photoInfoController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width - 50, height: 300)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath.item == (photos?.count)! - 1 {
            fetchMorePhotos()
        }
        
        if (!indexPaths.contains(indexPath)) {
            indexPaths.append(indexPath)
            cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
            UIView.animate(withDuration: 0.3, animations: {
                cell.layer.transform = CATransform3DMakeScale(1.05, 1.05, 1)
            },completion: { finished in
                UIView.animate(withDuration: 0.1, animations: {
                    cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
                })
            })
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 30
    }
    
    func setupNavBarAndCollectionView() {
        n = 1
        currentOrder = .popular
        currentQuery = ""
        navigationItem.title = currentOrder?.rawValue.capitalized
        navigationController?.navigationBar.isTranslucent = false
        //navigationController?.hidesBarsOnSwipe = true
        
        //this two lines below remove the shadow ?? border under the navigation bar.
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        collectionView?.backgroundColor = .white
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: cellId)
    }
    
    func setupNavBarButtons() {
        moreButton = UIBarButtonItem(image: UIImage(named: "menubar_icon"), style: .done, target: self, action: #selector(handleMoreButton))
        moreButton?.tintColor = .black
        
        searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(handleSearchButton))
        searchButton?.tintColor = .black
        
        navigationItem.leftBarButtonItem = moreButton
        navigationItem.rightBarButtonItem = searchButton
    }
    
    @objc func handleMoreButton() {
        let actionSheet = UIAlertController(title: "Select an order to filter by", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Popular", style: .default, handler: { (a) in
            self.currentOrder = .popular
            self.currentQuery = ""
            self.n = 1
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top
                , animated: true)
            self.fetchPhotos()
        }))
        actionSheet.addAction(UIAlertAction(title: "Latest", style: .default, handler: { (a) in
            self.currentOrder = .latest
            self.n = 1
            self.currentQuery = ""
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top
                , animated: true)
            self.fetchPhotos()
        }))
        actionSheet.addAction(UIAlertAction(title: "Oldest", style: .default, handler: { (a) in
            self.currentOrder = .oldest
            self.n = 1
            self.currentQuery = ""
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top
                , animated: true)
            self.fetchPhotos()
        }))
        actionSheet.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (a) in
            
            let settingsController = SettingsController(style: .grouped)
            settingsController.photoQualityDelegate = self
            self.navigationController?.pushViewController(settingsController, animated: true)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func handleSearchButton() {
        createSearchBar()
    }
    
    func createSearchBar() {
        let searchBar = UISearchBar()
        let searchBarTextField = searchBar.value(forKey: "searchField") as? UITextField
        searchBarTextField?.textColor = .black
        searchBar.placeholder = "Search for a movie..."
        searchBar.delegate = self
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.searchBarStyle = .minimal
        searchBar.cancelButton(true)
        searchBar.tintColor = .black
        searchBar.barTintColor = .black
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        navigationItem.titleView = searchBar
    }
    
    func removeSearchBar() {
        navigationItem.titleView = nil
        navigationItem.leftBarButtonItem = moreButton
        navigationItem.rightBarButtonItem = searchButton
        currentQuery = ""
        fetchPhotos()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        removeSearchBar()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        currentQuery = (searchBar.text?.replacingOccurrences(of: " ", with: "+"))!
        fetchPhotosByQuery(query: currentQuery)
    }
    
    func fetchPhotosByQuery(query: String) {
        n = 1
        PhotoAPIManager.shared.fetchPhotos(url: "s", orderBy: currentOrder!, page: n, query: query, quality: photoQuality) { (photos: [Photo]) in
            self.photos?.removeAll()
            self.photos = photos
            self.collectionView?.reloadData()
        }
        self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top
            , animated: true)
    }
}
