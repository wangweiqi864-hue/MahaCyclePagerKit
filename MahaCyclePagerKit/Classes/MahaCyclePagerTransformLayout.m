#import "MahaCyclePagerTransformLayout.h"

typedef NS_ENUM(NSUInteger, MahaTransformLayoutItemPosition) {
    MahaTransformLayoutItemPositionLeft,
    MahaTransformLayoutItemPositionCenter,
    MahaTransformLayoutItemPositionRight,
};

@interface MahaCyclePagerTransformLayout () {
    struct {
        unsigned int respondsToApplyTransformToAttributes : 1;
        unsigned int respondsToInitializeTransformAttributes : 1;
    } _delegateFlags;
}
@end

@interface MahaCyclePagerViewLayout ()

@property (nonatomic, weak) UIView *hostingView;

@end

@implementation MahaCyclePagerTransformLayout

- (instancetype)init {
    if (self = [super init]) {
        [self configureDefaultScrollDirection];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self configureDefaultScrollDirection];
    }
    return self;
}

- (void)configureDefaultScrollDirection {
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

- (void)setDelegate:(id<MahaCyclePagerTransformLayoutDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.respondsToInitializeTransformAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:initializeTransformAttributes:)];
    _delegateFlags.respondsToApplyTransformToAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:applyTransformToAttributes:)];
}

- (void)setLayout:(MahaCyclePagerViewLayout *)layout {
    _layout = layout;
    _layout.hostingView = self.collectionView;
    self.itemSize = _layout.itemSize;
    self.minimumInteritemSpacing = _layout.itemSpacing;
    self.minimumLineSpacing = _layout.itemSpacing;
}

- (CGSize)itemSize {
    if (!_layout) {
        return [super itemSize];
    }
    return _layout.itemSize;
}

- (CGFloat)minimumLineSpacing {
    if (!_layout) {
        return [super minimumLineSpacing];
    }
    return _layout.itemSpacing;
}

- (CGFloat)minimumInteritemSpacing {
    if (!_layout) {
        return [super minimumInteritemSpacing];
    }
    return _layout.itemSpacing;
}

- (CGFloat)visibleContentCenterX {
    return self.collectionView.contentOffset.x + CGRectGetWidth(self.collectionView.frame) / 2;
}

- (MahaTransformLayoutItemPosition)itemPositionForCenterX:(CGFloat)centerX {
    CGFloat visibleCenterX = [self visibleContentCenterX];
    if (ABS(centerX - visibleCenterX) < 0.5) {
        return MahaTransformLayoutItemPositionCenter;
    }
    if (centerX < visibleCenterX) {
        return MahaTransformLayoutItemPositionLeft;
    }
    return MahaTransformLayoutItemPositionRight;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return _layout.layoutType == MahaCyclePagerTransformLayoutNormal ? [super shouldInvalidateLayoutForBoundsChange:newBounds] : YES;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (_delegateFlags.respondsToApplyTransformToAttributes || _layout.layoutType != MahaCyclePagerTransformLayoutNormal) {
        NSArray *attributesArray = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
        CGRect visibleRect = {self.collectionView.contentOffset, self.collectionView.bounds.size};
        for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
            if (!CGRectIntersectsRect(visibleRect, attributes.frame)) {
                continue;
            }
            if (_delegateFlags.respondsToApplyTransformToAttributes) {
                [_delegate pagerViewTransformLayout:self applyTransformToAttributes:attributes];
            } else {
                [self applyTransformToAttributes:attributes layoutType:_layout.layoutType];
            }
        }
        return attributesArray;
    }
    return [super layoutAttributesForElementsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    if (_delegateFlags.respondsToInitializeTransformAttributes) {
        [_delegate pagerViewTransformLayout:self initializeTransformAttributes:attributes];
    } else if (_layout.layoutType != MahaCyclePagerTransformLayoutNormal) {
        [self initializeTransformAttributes:attributes layoutType:_layout.layoutType];
    }
    return attributes;
}

- (void)initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(MahaCyclePagerTransformLayoutType)layoutType {
    switch (layoutType) {
        case MahaCyclePagerTransformLayoutLinear:
            [self applyLinearTransformToAttributes:attributes scale:_layout.minimumScale alpha:_layout.minimumAlpha];
            break;
        case MahaCyclePagerTransformLayoutCoverflow:
            [self applyCoverflowTransformToAttributes:attributes angle:_layout.maximumAngle alpha:_layout.minimumAlpha];
            break;
        default:
            break;
    }
}

- (void)applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(MahaCyclePagerTransformLayoutType)layoutType {
    switch (layoutType) {
        case MahaCyclePagerTransformLayoutLinear:
            [self applyLinearTransformToAttributes:attributes];
            break;
        case MahaCyclePagerTransformLayoutCoverflow:
            [self applyCoverflowTransformToAttributes:attributes];
            break;
        default:
            break;
    }
}

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    if (collectionViewWidth <= 0) {
        return;
    }
    CGFloat delta = ABS(attributes.center.x - [self visibleContentCenterX]);
    CGFloat scale = MAX(1 - delta / collectionViewWidth * _layout.rateOfChange, _layout.minimumScale);
    CGFloat alpha = MAX(1 - delta / collectionViewWidth, _layout.minimumAlpha);
    [self applyLinearTransformToAttributes:attributes scale:scale alpha:alpha];
}

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes scale:(CGFloat)scale alpha:(CGFloat)alpha {
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    if (_layout.adjustSpacingWhenScroling) {
        MahaTransformLayoutItemPosition itemPosition = [self itemPositionForCenterX:attributes.center.x];
        CGFloat translate = 0;
        switch (itemPosition) {
            case MahaTransformLayoutItemPositionLeft:
                translate = 1.15 * attributes.size.width * (1 - scale) / 2;
                break;
            case MahaTransformLayoutItemPositionRight:
                translate = -1.15 * attributes.size.width * (1 - scale) / 2;
                break;
            default:
                scale = 1.0;
                alpha = 1.0;
                break;
        }
        transform = CGAffineTransformTranslate(transform, translate, 0);
    }
    attributes.transform = transform;
    attributes.alpha = alpha;
}

- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    if (collectionViewWidth <= 0) {
        return;
    }
    CGFloat delta = ABS(attributes.center.x - [self visibleContentCenterX]);
    CGFloat angle = MIN(delta / collectionViewWidth * (1 - _layout.rateOfChange), _layout.maximumAngle);
    CGFloat alpha = MAX(1 - delta / collectionViewWidth, _layout.minimumAlpha);
    [self applyCoverflowTransformToAttributes:attributes angle:angle alpha:alpha];
}

- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes angle:(CGFloat)angle alpha:(CGFloat)alpha {
    MahaTransformLayoutItemPosition itemPosition = [self itemPositionForCenterX:attributes.center.x];
    CATransform3D transform3D = CATransform3DIdentity;
    transform3D.m34 = -0.002;
    CGFloat translate = 0;
    switch (itemPosition) {
        case MahaTransformLayoutItemPositionLeft:
            translate = (1 - cos(angle * 1.2 * M_PI)) * attributes.size.width;
            break;
        case MahaTransformLayoutItemPositionRight:
            translate = -(1 - cos(angle * 1.2 * M_PI)) * attributes.size.width;
            angle = -angle;
            break;
        default:
            angle = 0;
            alpha = 1;
            break;
    }

    transform3D = CATransform3DRotate(transform3D, M_PI * angle, 0, 1, 0);
    if (_layout.adjustSpacingWhenScroling) {
        transform3D = CATransform3DTranslate(transform3D, translate, 0, 0);
    }
    attributes.transform3D = transform3D;
    attributes.alpha = alpha;
}

@end

@implementation MahaCyclePagerViewLayout

- (instancetype)init {
    if (self = [super init]) {
        _itemVerticalCenter = YES;
        _minimumScale = 0.8;
        _minimumAlpha = 1.0;
        _maximumAngle = 0.2;
        _rateOfChange = 0.4;
        _adjustSpacingWhenScroling = YES;
    }
    return self;
}

- (CGFloat)verticalInsetForCenteredItem {
    return (CGRectGetHeight(_hostingView.frame) - _itemSize.height) / 2;
}

- (UIEdgeInsets)onlyOneSectionInset {
    CGFloat leftSpace = _hostingView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_hostingView.frame) - _itemSize.width) / 2 : _sectionInset.left;
    CGFloat rightSpace = _hostingView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_hostingView.frame) - _itemSize.width) / 2 : _sectionInset.right;
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = [self verticalInsetForCenteredItem];
        return UIEdgeInsetsMake(verticalSpace, leftSpace, verticalSpace, rightSpace);
    }
    return UIEdgeInsetsMake(_sectionInset.top, leftSpace, _sectionInset.bottom, rightSpace);
}

- (UIEdgeInsets)firstSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = [self verticalInsetForCenteredItem];
        return UIEdgeInsetsMake(verticalSpace, _sectionInset.left, verticalSpace, _itemSpacing);
    }
    return UIEdgeInsetsMake(_sectionInset.top, _sectionInset.left, _sectionInset.bottom, _itemSpacing);
}

- (UIEdgeInsets)lastSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = [self verticalInsetForCenteredItem];
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _sectionInset.right);
    }
    return UIEdgeInsetsMake(_sectionInset.top, 0, _sectionInset.bottom, _sectionInset.right);
}

- (UIEdgeInsets)middleSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = [self verticalInsetForCenteredItem];
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _itemSpacing);
    }
    return _sectionInset;
}

@end
