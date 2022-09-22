//
//  RBWaterfallCollectionViewLayoutDelegate.swift
//  1stdibs
//
//  Created by Reza Bina on 2022-04-01.
//  Copyright © 2022 Reza Bina. All rights reserved.
//

import UIKit

protocol RBWaterfallCollectionViewLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int
    func collectionView(_ collectionView: UICollectionView, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    
    func collectionView(_ collectionView: UICollectionView, insetForSectionAt section: Int) -> UIEdgeInsets
    func collectionView(_ collectionView: UICollectionView, lineSpacingForSectionAt section: Int) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, interitemSpacingForSectionAt section: Int) -> CGFloat
}

class RBWaterfallCollectionViewLayout: UICollectionViewLayout {
    
    // MARK: - Publics
    
    weak var delegate: RBWaterfallCollectionViewLayoutDelegate?
    
    // MARK: - Privates
    
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    private var numberOfSections: Int {
        return collectionView?.numberOfSections ?? 0
    }
    
    private func numberOfItems(inSection section: Int) -> Int {
        return collectionView?.numberOfItems(inSection: section) ?? 0
    }
    
    // MARK: - Overrides
    
    override public var collectionViewContentSize: CGSize {
        get {
            CGSize(width: contentWidth, height: contentHeight)
        }
    }
    
    override public func invalidateLayout() {
        cache.removeAll()
        contentHeight = 0
        
        super.invalidateLayout()
    }
    
    override func prepare() {
        guard cache.isEmpty == true, let collectionView = collectionView else { return }
        guard let delegate = delegate else {
            fatalError("A delegate of type RBWaterfallCollectionViewLayoutDelegate must be set.")
        }
        
        for section in 0..<numberOfSections {
            let numberOfColumns = delegate.collectionView(collectionView, numberOfColumnsInSection: section)
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            
            let sectionInset = delegate.collectionView(collectionView, insetForSectionAt: section)
            let lineSpacing = delegate.collectionView(collectionView, lineSpacingForSectionAt: section)
            let interitemSpacing = delegate.collectionView(collectionView, interitemSpacingForSectionAt: section)
            
            let spacesBetweenColumnsInRow = interitemSpacing * CGFloat(numberOfColumns - 1)
            let horizontalSpacesInRow = sectionInset.left + sectionInset.right + spacesBetweenColumnsInRow
            
            let columnWidth = ((contentWidth - horizontalSpacesInRow) / CGFloat(numberOfColumns))
            var xOffset: [CGFloat] = []
            for column in 0..<numberOfColumns {
                let offset = (CGFloat(column) * (columnWidth + interitemSpacing)) + sectionInset.left
                xOffset.append(offset)
            }
            
            var yOffset: [CGFloat] = .init(repeating: contentHeight + sectionInset.top, count: numberOfColumns)
            
            for item in 0..<numberOfItems {
                let indexPath = IndexPath(item: item, section: section)
                let column = yOffset.firstIndex(of: yOffset.min() ?? 0) ?? 0
                let itemSize = delegate.collectionView(collectionView, sizeForItemAtIndexPath: indexPath)
                
                let sizeRatio = itemSize.height / itemSize.width
                let photoHeight = columnWidth * sizeRatio
                let height = photoHeight
                let frame = CGRect(x: xOffset[column],
                                   y: yOffset[column],
                                   width: columnWidth,
                                   height: height)
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                cache.append(attributes)
                
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height + lineSpacing
                
                if item == (numberOfItems - 1) {
                    contentHeight = contentHeight + sectionInset.bottom
                }
            }
        }
        
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
        
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        
        return visibleLayoutAttributes
    }
    
}
