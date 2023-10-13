// The MIT License (MIT)
//
// Copyright (c) 2019 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import Photos

// MARK: ImagePickerController
@objcMembers open class ImagePickerController: UINavigationController {
    // MARK: Public properties
    public weak var imagePickerDelegate: ImagePickerControllerDelegate?
    public var settings: Settings = Settings()
    public var doneButton: UIBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
    public var cancelButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    public var segmentedControl: UISegmentedControl = UISegmentedControl(items: ["", ""])
    public var selectedAssets: [PHAsset] {
        get {
            return assetStore.assets
        }
    }

    // Note this trick to get the apple localization no longer works.
    // Figure out why. Until then, expose the variable for users to set to whatever they want it localized to
    // TODO: Fix this ^^
    /// Title to use for button
    public var doneButtonTitle = Bundle(identifier: "com.apple.UIKit")?.localizedString(forKey: "Done", value: "Done", table: "") ?? "Done"
    public var segmentedControlPhotosTitle = Bundle(identifier: "com.apple.UIKit")?.localizedString(forKey: "Photos", value: "Photos", table: "") ?? "Photos"
    public var segmentedControlAlbumsTitle = Bundle(identifier: "com.apple.UIKit")?.localizedString(forKey: "Albums", value: "Albums", table: "") ?? "Albums"

    // MARK: Internal properties
    var assetStore: AssetStore
    var onSelection: ((_ asset: PHAsset) -> Void)?
    var onDeselection: ((_ asset: PHAsset) -> Void)?
    var onCancel: ((_ assets: [PHAsset]) -> Void)?
    var onFinish: ((_ assets: [PHAsset]) -> Void)?

    let assetsViewController: AssetsViewController
    let albumsViewController = AlbumsViewController()
    let zoomTransitionDelegate = ZoomTransitionDelegate()

    lazy var photosSectionAlbum: PHAssetCollection? = {
        let fetchOptions = settings.fetch.assets.options.copy() as! PHFetchOptions
        fetchOptions.fetchLimit = 1
        guard let fetchResult = settings.fetch.album.photosSectionFetchResult else {
            return nil
        }
        return fetchResult.objects(at: IndexSet(0..<fetchResult.count)).first
    }()

    lazy var albums: [PHAssetCollection] = {
        // We don't want collections without assets.
        // I would like to do that with PHFetchOptions: fetchOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        // But that doesn't work...
        // This seems suuuuuper ineffective...
        let fetchOptions = settings.fetch.assets.options.copy() as! PHFetchOptions
        fetchOptions.fetchLimit = 1

        return settings.fetch.album.fetchResults.filter {
            $0.count > 0
        }.flatMap {
            $0.objects(at: IndexSet(integersIn: 0..<$0.count))
        }.filter {
            // We can't use estimatedAssetCount on the collection
            // It returns NSNotFound. So actually fetch the assets...
            let assetsFetchResult = PHAsset.fetchAssets(in: $0, options: fetchOptions)
            return assetsFetchResult.count > 0
        }
    }()

    public init(selectedAssets: [PHAsset] = []) {
        assetStore = AssetStore(assets: selectedAssets)
        assetsViewController = AssetsViewController(store: assetStore)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Sync settings
        albumsViewController.settings = settings
        assetsViewController.settings = settings

        // Setup view controllers
        albumsViewController.delegate = self
        assetsViewController.delegate = self

        view.backgroundColor = settings.theme.backgroundColor

        // Setup delegates
        delegate = zoomTransitionDelegate
        presentationController?.delegate = self

        // Turn off translucency so drop down can match its color
        navigationBar.isTranslucent = false
        navigationBar.isOpaque = true

        // Setup buttons
        segmentedControl.setTitle(segmentedControlPhotosTitle, forSegmentAt: 0)
        segmentedControl.setTitle(segmentedControlAlbumsTitle, forSegmentAt: 1)
        segmentedControl.addTarget(self, action: #selector(segmentedControlUpdated(_:)), for: .valueChanged)

        doneButton.target = self
        doneButton.action = #selector(doneButtonPressed(_:))

        cancelButton.target = self
        cancelButton.action = #selector(cancelButtonPressed(_:))

        updatedDoneButton()

        // We need to have some color to be able to match with the drop down
        if navigationBar.barTintColor == nil {
            navigationBar.barTintColor = .systemBackgroundColor
        }

        loadPhotosSection()
    }

    public func deselect(asset: PHAsset) {
        assetsViewController.unselect(asset: asset)
        assetStore.remove(asset)
        updatedDoneButton()
    }

    func updatedDoneButton() {
        doneButton.title = assetStore.count > 0 ? doneButtonTitle + " (\(assetStore.count))" : doneButtonTitle
        doneButton.isEnabled = assetStore.count >= settings.selection.min
    }

    func resetNavigationBar() {
        let firstViewController = viewControllers.first
        firstViewController?.navigationItem.titleView = nil
        firstViewController?.navigationItem.rightBarButtonItem = nil
        firstViewController?.navigationItem.leftBarButtonItem = nil
    }

    func updateNavigationBar() {
        let firstViewController = viewControllers.first
        firstViewController?.navigationItem.titleView = segmentedControl
        firstViewController?.navigationItem.rightBarButtonItem = doneButton
        firstViewController?.navigationItem.leftBarButtonItem = cancelButton
    }

    func loadPhotosSection() {
        guard let photosSectionAlbum else { return }
        resetNavigationBar()
        assetsViewController.showAssets(in: photosSectionAlbum)
        segmentedControl.selectedSegmentIndex = 0
        viewControllers = [assetsViewController]
        updateNavigationBar()
    }

    func loadAlbumsSection() {
        resetNavigationBar()
        albumsViewController.albums = albums
        viewControllers = [albumsViewController]
        updateNavigationBar()
    }

    func presentPhotosFromAlbum(_ album: PHAssetCollection) {
        assetsViewController.navigationItem.title = album.localizedTitle
        assetsViewController.showAssets(in: album)
        pushViewController(assetsViewController, animated: true)
    }
}
