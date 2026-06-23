#import "MahaPageControl.h"

@interface MahaPageControl ()

@property (nonatomic, strong) NSArray<UIImageView *> *pageIndicatorViews;
@property (nonatomic, assign) BOOL shouldForceRefreshIndicators;

@end

@implementation MahaPageControl

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.userInteractionEnabled = NO;
    _shouldForceRefreshIndicators = NO;
    _animationDuration = 0.3;
    _pageIndicatorSpaing = 10;
    _indicatorImageContentMode = UIViewContentModeCenter;
    _pageIndicatorSize = CGSizeMake(6, 6);
    _currentPageIndicatorSize = _pageIndicatorSize;
    _pageIndicatorTintColor = [UIColor colorWithRed:128 / 255.0 green:128 / 255.0 blue:128 / 255.0 alpha:1];
    _currentPageIndicatorTintColor = [UIColor whiteColor];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        _shouldForceRefreshIndicators = YES;
        [self reloadIndicatorViewsIfNeeded];
        _shouldForceRefreshIndicators = NO;
    }
}

- (CGSize)contentSize {
    CGFloat width = (_pageIndicatorViews.count - 1) * (_pageIndicatorSize.width + _pageIndicatorSpaing) + _pageIndicatorSize.width + _contentInset.left + _contentInset.right;
    CGFloat height = _currentPageIndicatorSize.height + _contentInset.top + _contentInset.bottom;
    return CGSizeMake(width, height);
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
    if (numberOfPages == _numberOfPages) {
        return;
    }
    _numberOfPages = numberOfPages;
    if (_currentPage >= numberOfPages) {
        _currentPage = 0;
    }
    [self reloadIndicatorViewsIfNeeded];
    [self setNeedsLayoutIfNecessary];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    if (_currentPage == currentPage || _pageIndicatorViews.count <= currentPage) {
        return;
    }
    _currentPage = currentPage;
    if (!CGSizeEqualToSize(_currentPageIndicatorSize, _pageIndicatorSize)) {
        [self setNeedsLayout];
    }
    [self refreshIndicatorAppearanceIfNeeded];
    if (self.userInteractionEnabled) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)setCurrentPage:(NSInteger)currentPage animate:(BOOL)animate {
    if (animate) {
        [UIView animateWithDuration:_animationDuration animations:^{
            [self setCurrentPage:currentPage];
        }];
    } else {
        [self setCurrentPage:currentPage];
    }
}

- (CGFloat)pageIndicatorSpacing {
    return _pageIndicatorSpaing;
}

- (void)setPageIndicatorSpacing:(CGFloat)pageIndicatorSpacing {
    _pageIndicatorSpaing = pageIndicatorSpacing;
    [self setNeedsLayoutIfNecessary];
}

- (void)setPageIndicatorImage:(UIImage *)pageIndicatorImage {
    _pageIndicatorImage = pageIndicatorImage;
    [self refreshIndicatorAppearanceIfNeeded];
}

- (void)setCurrentPageIndicatorImage:(UIImage *)currentPageIndicatorImage {
    _currentPageIndicatorImage = currentPageIndicatorImage;
    [self refreshIndicatorAppearanceIfNeeded];
}

- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
    _pageIndicatorTintColor = pageIndicatorTintColor;
    [self refreshIndicatorAppearanceIfNeeded];
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
    _currentPageIndicatorTintColor = currentPageIndicatorTintColor;
    [self refreshIndicatorAppearanceIfNeeded];
}

- (void)setPageIndicatorSize:(CGSize)pageIndicatorSize {
    if (CGSizeEqualToSize(_pageIndicatorSize, pageIndicatorSize)) {
        return;
    }
    _pageIndicatorSize = pageIndicatorSize;
    if (CGSizeEqualToSize(_currentPageIndicatorSize, CGSizeZero) || (_currentPageIndicatorSize.width < pageIndicatorSize.width && _currentPageIndicatorSize.height < pageIndicatorSize.height)) {
        _currentPageIndicatorSize = pageIndicatorSize;
    }
    [self setNeedsLayoutIfNecessary];
}

- (void)setPageIndicatorSpaing:(CGFloat)pageIndicatorSpaing {
    _pageIndicatorSpaing = pageIndicatorSpaing;
    [self setNeedsLayoutIfNecessary];
}

- (void)setCurrentPageIndicatorSize:(CGSize)currentPageIndicatorSize {
    if (CGSizeEqualToSize(_currentPageIndicatorSize, currentPageIndicatorSize)) {
        return;
    }
    _currentPageIndicatorSize = currentPageIndicatorSize;
    [self setNeedsLayoutIfNecessary];
}

- (CGFloat)animateDuring {
    return _animationDuration;
}

- (void)setAnimateDuring:(CGFloat)animateDuring {
    _animationDuration = animateDuring;
}

- (void)setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment {
    [super setContentHorizontalAlignment:contentHorizontalAlignment];
    [self setNeedsLayoutIfNecessary];
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];
    [self setNeedsLayoutIfNecessary];
}

- (void)setNeedsLayoutIfNecessary {
    if (_pageIndicatorViews.count > 0) {
        [self setNeedsLayout];
    }
}

- (void)reloadIndicatorViewsIfNeeded {
    if (!self.superview && !_shouldForceRefreshIndicators) {
        return;
    }
    if (_pageIndicatorViews.count == _numberOfPages) {
        [self refreshIndicatorAppearanceIfNeeded];
        return;
    }
    NSMutableArray<UIImageView *> *indicatorViews = _pageIndicatorViews ? [_pageIndicatorViews mutableCopy] : [NSMutableArray array];
    if (indicatorViews.count < _numberOfPages) {
        for (NSInteger pageIndex = indicatorViews.count; pageIndex < _numberOfPages; ++pageIndex) {
            UIImageView *indicatorImageView = [[UIImageView alloc] init];
            indicatorImageView.contentMode = _indicatorImageContentMode;
            [self addSubview:indicatorImageView];
            [indicatorViews addObject:indicatorImageView];
        }
    } else if (indicatorViews.count > _numberOfPages) {
        for (NSInteger pageIndex = indicatorViews.count - 1; pageIndex >= _numberOfPages; --pageIndex) {
            UIImageView *indicatorImageView = indicatorViews[pageIndex];
            [indicatorImageView removeFromSuperview];
            [indicatorViews removeObjectAtIndex:pageIndex];
        }
    }
    _pageIndicatorViews = [indicatorViews copy];
    [self refreshIndicatorAppearanceIfNeeded];
}

- (void)refreshIndicatorAppearanceIfNeeded {
    if (_pageIndicatorViews.count == 0 || (!self.superview && !_shouldForceRefreshIndicators)) {
        return;
    }
    if (_hidesForSinglePage && _pageIndicatorViews.count == 1) {
        UIImageView *indicatorImageView = _pageIndicatorViews.lastObject;
        indicatorImageView.hidden = YES;
        return;
    }
    NSInteger pageIndex = 0;
    for (UIImageView *indicatorImageView in _pageIndicatorViews) {
        if (_pageIndicatorImage) {
            indicatorImageView.contentMode = _indicatorImageContentMode;
            indicatorImageView.image = _currentPage == pageIndex ? _currentPageIndicatorImage : _pageIndicatorImage;
        } else {
            indicatorImageView.image = nil;
            indicatorImageView.backgroundColor = _currentPage == pageIndex ? _currentPageIndicatorTintColor : _pageIndicatorTintColor;
        }
        indicatorImageView.hidden = NO;
        ++pageIndex;
    }
}

- (void)layoutPageIndicatorViews {
    if (_pageIndicatorViews.count == 0) {
        return;
    }
    CGFloat originX = 0;
    CGFloat centerY = 0;
    CGFloat indicatorSpacing = _pageIndicatorSpaing;
    switch (self.contentHorizontalAlignment) {
        case UIControlContentHorizontalAlignmentCenter:
            originX = (CGRectGetWidth(self.frame) - (_pageIndicatorViews.count - 1) * (_pageIndicatorSize.width + _pageIndicatorSpaing) - _currentPageIndicatorSize.width) / 2;
            break;
        case UIControlContentHorizontalAlignmentLeft:
            originX = _contentInset.left;
            break;
        case UIControlContentHorizontalAlignmentRight:
            originX = CGRectGetWidth(self.frame) - ((_pageIndicatorViews.count - 1) * (_pageIndicatorSize.width + _pageIndicatorSpaing) + _currentPageIndicatorSize.width) - _contentInset.right;
            break;
        case UIControlContentHorizontalAlignmentFill:
            originX = _contentInset.left;
            if (_pageIndicatorViews.count > 1) {
                indicatorSpacing = (CGRectGetWidth(self.frame) - _contentInset.left - _contentInset.right - _pageIndicatorSize.width - (_pageIndicatorViews.count - 1) * _pageIndicatorSize.width) / (_pageIndicatorViews.count - 1);
            }
            break;
        default:
            break;
    }

    switch (self.contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter:
            centerY = CGRectGetHeight(self.frame) / 2;
            break;
        case UIControlContentVerticalAlignmentTop:
            centerY = _contentInset.top + _currentPageIndicatorSize.height / 2;
            break;
        case UIControlContentVerticalAlignmentBottom:
            centerY = CGRectGetHeight(self.frame) - _currentPageIndicatorSize.height / 2 - _contentInset.bottom;
            break;
        case UIControlContentVerticalAlignmentFill:
            centerY = (CGRectGetHeight(self.frame) - _contentInset.top - _contentInset.bottom) / 2 + _contentInset.top;
            break;
        default:
            break;
    }

    NSInteger pageIndex = 0;
    for (UIImageView *indicatorImageView in _pageIndicatorViews) {
        if (_pageIndicatorImage) {
            indicatorImageView.layer.cornerRadius = 0;
        } else {
            indicatorImageView.layer.cornerRadius = _currentPage == pageIndex ? _currentPageIndicatorSize.height / 2 : _pageIndicatorSize.height / 2;
        }
        CGSize indicatorSize = pageIndex == _currentPage ? _currentPageIndicatorSize : _pageIndicatorSize;
        indicatorImageView.frame = CGRectMake(originX, centerY - indicatorSize.height / 2, indicatorSize.width, indicatorSize.height);
        originX += indicatorSize.width + indicatorSpacing;
        ++pageIndex;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutPageIndicatorViews];
}

@end
