import Photos
import UIKit

class ViewController: UIViewController {
    private lazy var pickImageButton: UIButton = {
        var configuration: UIButton.Configuration = .filled()
        configuration.cornerStyle = .capsule
        configuration.title = "Pick Image"

        let button = UIButton()
        button.configuration = configuration
        button.addTarget(self, action: #selector(didTapPickImageButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var applePickImageButton: UIButton = {
        var configuration: UIButton.Configuration = .filled()
        configuration.cornerStyle = .capsule
        configuration.title = "Pick Image (Apple)"

        let button = UIButton()
        button.configuration = configuration
        button.addTarget(self, action: #selector(didTapApplePickImageButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var carouselView: CarouselView = {
        let carouselView = CarouselView()
        carouselView.translatesAutoresizingMaskIntoConstraints = false
        return carouselView
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        return loadingIndicator
    }()

    private lazy var loadingView: UIView = {
        let loadingView = UIView()
        loadingView.backgroundColor = .gray.withAlphaComponent(0.8)
        loadingView.isHidden = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        return loadingView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        installConstraints()
    }

    // MARK: Setup views

    private func setupViews() {
        defer { setupLoadingScreen() }
        view.backgroundColor = .white
        view.addSubview(carouselView)
        view.addSubview(pickImageButton)
        view.addSubview(applePickImageButton)
    }

    private func installConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),

            carouselView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            carouselView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 25),
            carouselView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            carouselView.heightAnchor.constraint(equalToConstant: 500),

            pickImageButton.topAnchor.constraint(equalTo: carouselView.bottomAnchor, constant: 50),
            pickImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            applePickImageButton.topAnchor.constraint(equalTo: pickImageButton.bottomAnchor, constant: 25),
            applePickImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: Actions

    @objc
    private func didTapPickImageButton() {
        debugPrint("[ViewController] didTapPickImageButton()")
        presentImagePicker()
    }

    @objc
    private func didTapApplePickImageButton() {
        debugPrint("[ViewController] didTapApplePickImageButton()")
        presentAppleImagePicker()
    }

    private func presentImagePicker() {
        let launchImagePicker = { [weak self] in
            guard let self else { return }
            let imagePicker = ImagePickerController()
            imagePicker.imagePickerDelegate = self
            imagePicker.settings.dismiss.enabled = true
            imagePicker.settings.fetch.assets.supportedMediaTypes = [.image]
            let options = imagePicker.settings.fetch.album.options
            imagePicker.settings.fetch.album.photosSectionFetchResult =
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: options)
            imagePicker.settings.fetch.album.fetchResults = [
                PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options),
                PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: options),
            ]
            imagePicker.modalPresentationStyle = .overFullScreen
            present(imagePicker, animated: true)
        }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async(execute: launchImagePicker)
            }
        }
    }

    private func presentAppleImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .overFullScreen
        present(imagePicker, animated: true)
    }

    private func setupLoadingScreen() {
        loadingView.addSubview(loadingIndicator)
        view.addSubview(loadingView)
    }

    private func showLoadingScreen() {
        loadingView.isHidden = false
        loadingIndicator.startAnimating()
    }

    private func hideLoadingScreen() {
        loadingView.isHidden = true
        loadingIndicator.stopAnimating()
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        debugPrint("[ViewController][UIImagePickerControllerDelegate] imagePickerController(_, didFinishPickingMediaWithInfo")
        if let originalImage = info[.originalImage] as? UIImage {
            carouselView.images = [originalImage]
        }
        picker.dismiss(animated: true)
    }
}

// MARK: - ImagePickerControllerDelegate

extension ViewController: ImagePickerControllerDelegate {
    func imagePicker(_ imagePicker: ImagePickerController, didFinishWithAssets assets: [PHAsset]) {
        debugPrint("[ViewController][ImagePickerControllerDelegate] imagePicker(_, didFinishWithAssets)")
        let waiter = DispatchGroup()
        var images: [UIImage?] = Array(repeating: nil, count: assets.count)
        for (index, asset) in assets.enumerated() {
            waiter.enter()
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: nil
            ) { (image, info) in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? true
                guard !isDegraded else { return }
                if images[index] == nil {
                    images[index] = image
                    waiter.leave()
                }
            }
        }
        waiter.notify(queue: .main) { [weak self] in
            guard let self else { return }
            carouselView.images = images.compactMap { $0 }
            hideLoadingScreen()
        }
        showLoadingScreen()
        imagePicker.dismiss(animated: true)
    }

    func imagePicker(_ imagePicker: ImagePickerController, didCancelWithAssets assets: [PHAsset]) {} // no-op
    func imagePicker(_ imagePicker: ImagePickerController, didSelectAsset asset: PHAsset) {} // no-op
    func imagePicker(_ imagePicker: ImagePickerController, didDeselectAsset asset: PHAsset) {} // no-op
    func imagePicker(_ imagePicker: ImagePickerController, didReachSelectionLimit count: Int) {} // no-op
}
