//
//  ImageLoading.swift
//  ImageLoader
//
//  Created by Prathamesh Tatar on 13/10/23.
//

import UIKit

public enum ImageLoadingError: Error {
    case downloadError(_ error: Error)
    case imageParsingError
}

public typealias ImageLoaderResult = Result<UIImage, ImageLoadingError>
public typealias ImageLoaderCompletionHandler = (ImageLoaderResult) -> Void

public class ImageLoadingTask {
    private var completionHandler: ImageLoaderCompletionHandler?
    private let syncQueue = DispatchQueue(label: "ImageLoadingTaskSyncQueue", qos: .background)

    public init(completion: @escaping ImageLoaderCompletionHandler) {
        syncQueue.async { [weak self] in
            self?.completionHandler = completion
        }
    }

    public func cancel() {
        syncQueue.async { [weak self] in
            self?.completionHandler = nil
        }
    }

    func complete(with result: ImageLoaderResult) {
        syncQueue.async { [weak self] in
            self?.completionHandler?(result)
        }
    }
}

public class ImageLoader {
    private let remoteImageLoader = RemoteImageLoader()
    private let imageCache = NSCache<NSURL, UIImage>()
    private let networkCache = NSCache<NSURL, NSMutableArray>()
    private let networkQueue = DispatchQueue(label: "ImageLoaderNetworkQueue", qos: .background, attributes: .concurrent)
    private let serialQueue = DispatchQueue(label: "ImageLoaderSerialQueue", qos: .background)

    public func loadImage(from url: URL, completion: @escaping ImageLoaderCompletionHandler, queue: DispatchQueue = .main) -> ImageLoadingTask {
        let task = ImageLoadingTask { result in
            queue.async {
                completion(result)
            }
        }
        let nsURL = url as NSURL
        serialQueue.async { [weak self] in
            guard let self else { return }
            if let image = imageCache.object(forKey: nsURL) {
                task.complete(with: .success(image))
                return
            } else if let cache = networkCache.object(forKey: nsURL), cache.count > 0 {
                cache.add(task)
                return
            } else {
                networkCache.setObject(NSMutableArray(object: task), forKey: nsURL)
            }
            networkQueue.async { [weak self] in
                guard let self else { return }
                remoteImageLoader.loadImage(from: url) { [weak self] result in
                    guard let self else { return }
                    serialQueue.async { [weak self] in
                        guard let self else { return }
                        if case .success(let image) = result {
                            imageCache.setObject(image, forKey: nsURL)
                        }
                        (networkCache.object(forKey: nsURL) as? [ImageLoadingTask])?.forEach { task in
                            task.complete(with: result)
                        }
                        networkCache.removeObject(forKey: nsURL)
                    }
                }
            }
        }
        return task
    }
}

final class RemoteImageLoader {
    func loadImage(from url: URL, completion: @escaping ImageLoaderCompletionHandler) {
        do {
            let imageData = try Data(contentsOf: url)
            guard let image = UIImage(data: imageData) else {
                completion(.failure(.imageParsingError))
                return
            }
            completion(.success(image))
        } catch {
            completion(.failure(.downloadError(error)))
        }
    }
}
