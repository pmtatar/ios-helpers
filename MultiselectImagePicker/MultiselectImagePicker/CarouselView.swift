import UIKit

class CarouselView: UIView {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    var images: [UIImage] = [] {
        didSet {
            guard oldValue != images else { return }
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            images.forEach { (image) in
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                stackView.addArrangedSubview(imageView)
                imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            }
            scrollView.setContentOffset(.zero, animated: false)
        }
    }

    @available(iOS, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    init() {
        super.init(frame: .zero)
        setupViews()
        installConstraints()
    }

    private func setupViews() {
        scrollView.addSubview(stackView)
        addSubview(scrollView)
    }

    private func installConstraints() {
        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),

            stackView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor),
            stackView.widthAnchor.constraint(greaterThanOrEqualTo: frameLayoutGuide.widthAnchor),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
