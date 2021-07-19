//
//  AttachmentSlideshow.swift
//  MAGE
//
//  Created by Daniel Barela on 1/22/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

class AttachmentSlideShow: UIView {

    private var didSetUpConstraints = false;
    private var height: CGFloat = 150.0;
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var scheme: MDCContainerScheming?;
    
    private lazy var slidescroll: UIScrollView = {
        let slidescroll = UIScrollView(forAutoLayout: ());
        slidescroll.isPagingEnabled = true;
        slidescroll.isScrollEnabled = true;
        slidescroll.delegate = self;
        slidescroll.contentSize = CGSize(width: CGFloat(self.bounds.width), height: height)
        slidescroll.isUserInteractionEnabled = true;
        return slidescroll;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        stackView.isUserInteractionEnabled = true;
        return stackView;
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl();
        pageControl.currentPage = 0;
        pageControl.hidesForSinglePage = true;
        pageControl.addTarget(self, action: #selector(pageControlChangedValue), for: .valueChanged)
        return pageControl;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init() {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.isUserInteractionEnabled = true;
        slidescroll.addSubview(stackView);
        self.addSubview(slidescroll);
        self.addSubview(pageControl);
        setNeedsUpdateConstraints();
        self.accessibilityLabel = "attachment slideshow";
    }
    
    func getAttachmentUrl(size: Int, attachment: Attachment) -> URL {
        if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
            return URL(fileURLWithPath: attachment.localPath!);
        } else {
            return URL(string: String(format: "%@?size=%ld", attachment.url!, size))!;
        }
    }
    
    func populate(observation: Observation, attachmentSelectionDelegate: AttachmentSelectionDelegate?) {
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview();
        }
        guard let safeAttachments = observation.attachments else {
            return
        }
        for (_, attachment) in safeAttachments.enumerated() {
            let imageView = AttachmentUIImageView(frame: CGRect(x: 0, y: 0, width: 0, height: height))
            stackView.addArrangedSubview(imageView);
            imageView.autoMatch(.width, to: .width, of: slidescroll);
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true;
            imageView.kf.indicatorType = .activity;
            
            let imageSize: Int = Int(max(self.frame.size.height, self.frame.size.width) * UIScreen.main.scale);
            if (attachment.contentType?.hasPrefix("image") ?? false) {
                imageView.setAttachment(attachment: attachment);
                imageView.accessibilityLabel = "attachment \(attachment.name ?? "")";
                imageView.showThumbnail(completionHandler:
                                                { result in
                                                    switch result {
                                                    case .success(_):
                                                        imageView.accessibilityLabel = "attachment \(attachment.name ?? "") loaded";
                                                        if (attachmentSelectionDelegate != nil) {
                                                            imageView.isUserInteractionEnabled = true;
                                                            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageViewTapped(sender:)))
                                                            imageView.addGestureRecognizer(tapGesture);
                                                        }
                                                    case .failure(let error):
                                                        print(error);
                                                    }
                                                });
            } else if (attachment.contentType?.hasPrefix("video") ?? false) {
                let url = self.getAttachmentUrl(size: imageSize, attachment: attachment);
                imageView.setAttachment(attachment: attachment);
                var localPath: String? = nil;
                if (attachment.localPath != nil && FileManager.default.fileExists(atPath: attachment.localPath!)) {
                    localPath = attachment.localPath;
                }
                let provider: VideoImageProvider = VideoImageProvider(url: url, localPath: localPath);
                imageView.contentMode = .scaleAspectFit;
                imageView.kf.setImage(with: provider, placeholder: UIImage(named: "play_overlay"), options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                    .processor(DownsamplingImageProcessor(size: imageView.frame.size)),
                    .cacheOriginalImage
                ], completionHandler:
                    { result in
                        switch result {
                        case .success(_):
                            imageView.contentMode = .scaleAspectFill;
                            let overlay: UIImageView = UIImageView(image: UIImage(named: "play_overlay"));
                            overlay.contentMode = .scaleAspectFit;
                            imageView.addSubview(overlay);
                            overlay.autoCenterInSuperview();
                            if (attachmentSelectionDelegate != nil) {
                                imageView.isUserInteractionEnabled = true;
                                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageViewTapped(sender:)))
                                imageView.addGestureRecognizer(tapGesture);
                            }
                        case .failure(let error):
                            print(error);
                            imageView.backgroundColor = UIColor.init(white: 0, alpha: 0.06);
                            let overlay: UIImageView = UIImageView(image: UIImage.init(named: "play_overlay"));
                            overlay.contentMode = .scaleAspectFit;
                            imageView.addSubview(overlay);
                        }
                    });
                
            } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
                imageView.image = UIImage(named: "audio_thumbnail");
                imageView.contentMode = .scaleAspectFit;
                imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
                imageView.setAttachment(attachment: attachment);
                if (attachmentSelectionDelegate != nil) {
                    imageView.isUserInteractionEnabled = true;
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.imageViewTapped(sender:)))
                    imageView.addGestureRecognizer(tapGesture);
                }
            } else {
                imageView.image = UIImage(named: "paperclip_thumbnail");
                imageView.tintColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.4)
                imageView.contentMode = .scaleAspectFit;
            }
            
        }
        
        slidescroll.contentSize = CGSize(width: CGFloat(safeAttachments.count) * CGFloat(self.bounds.width), height: height)
        pageControl.numberOfPages = safeAttachments.count;
    }
    
    @objc func imageViewTapped(sender: UITapGestureRecognizer) {
        let attachmentImageView:AttachmentUIImageView = sender.view as! AttachmentUIImageView;
        attachmentSelectionDelegate?.selectedAttachment(attachmentImageView.attachment);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            autoSetDimension(.height, toSize: height);
            slidescroll.autoPinEdgesToSuperviewEdges();
            stackView.autoPinEdgesToSuperviewEdges();
            stackView.autoMatch(.height, to: .height, of: slidescroll);
            pageControl.autoPinEdge(toSuperviewEdge: .bottom, withInset: 8);
            pageControl.autoAlignAxis(toSuperviewAxis: .vertical);
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.backgroundColor;
        self.pageControl.pageIndicatorTintColor = scheme.colorScheme.onPrimaryColor.withAlphaComponent(0.6);
        self.pageControl.currentPageIndicatorTintColor = scheme.colorScheme.primaryColor;
        for view in stackView.arrangedSubviews {
            view.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.4);
        }
    }
    
    @objc func pageControlChangedValue() {
        let currentPage = self.pageControl.currentPage;
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.slidescroll.contentOffset.x = CGFloat(currentPage) * self.slidescroll.frame.size.width
            }, completion: nil)
        }
    }
}

extension AttachmentSlideShow : UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}