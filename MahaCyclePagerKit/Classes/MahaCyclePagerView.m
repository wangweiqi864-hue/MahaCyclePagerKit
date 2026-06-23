#import "MahaCyclePagerView.h"

NS_INLINE BOOL MahaEqualIndexSection(MahaIndexSection indexSection1, MahaIndexSection indexSection2) {
    return indexSection1.index == indexSection2.index && indexSection1.section == indexSection2.section;
}

NS_INLINE MahaIndexSection MahaMakeIndexSection(NSInteger index, NSInteger section) {
    MahaIndexSection indexSection;
    indexSection.index = index;
    indexSection.section = section;
    return indexSection;
}

@interface MahaCyclePagerView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MahaCyclePagerTransformLayoutDelegate> {
    struct {
        unsigned int respondsToPagerViewDidScroll : 1;
        unsigned int respondsToDidScrollFromIndexToIndex : 1;
        unsigned int respondsToInitializeTransformAttributes : 1;
        unsigned int respondsToApplyTransformToAttributes : 1;
    } _delegateFlags;
    struct {
        unsigned int respondsToCellForItemAtIndex : 1;
        unsigned int respondsToLayoutForPagerView : 1;
    } _dataSourceFlags;
}

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) MahaCyclePagerViewLayout *layout;
@property (nonatomic, strong) NSTimer *autoScrollTimer;
@property (nonatomic, assign) NSInteger itemCount;
@property (nonatomic, assign) NSInteger reuseSection;
@property (nonatomic, assign) MahaIndexSection dragStartIndexSection;
@property (nonatomic, assign) NSInteger pendingInitialScrollIndex;
@property (nonatomic, assign) BOOL shouldClearCachedLayout;
@property (nonatomic, assign) BOOL hasReloadedData;
@property (nonatomic, assign) BOOL hasCompletedLayout;
@property (nonatomic, assign) BOOL shouldResetIndexAfterReload;

@end

static const NSInteger MahaPagerViewMaxSectionCount = 200;
static const NSInteger MahaPagerViewMinSectionCount = 18;

@implementation MahaCyclePagerView

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
    [self setUpDefaultState];
    [self setUpCollectionView];
}

- (void)setUpDefaultState {
    _shouldResetIndexAfterReload = NO;
    _hasReloadedData = NO;
    _hasCompletedLayout = NO;
    _autoScrollInterval = 0;
    _isInfiniteLoop = YES;
    _dragStartIndexSection = MahaMakeIndexSection(0, 0);
    _indexSection = MahaMakeIndexSection(-1, -1);
    _pendingInitialScrollIndex = -1;
}

- (void)setUpCollectionView {
    MahaCyclePagerTransformLayout *transformLayout = [[MahaCyclePagerTransformLayout alloc] init];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:transformLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.pagingEnabled = NO;
    collectionView.decelerationRate = 1 - 0.0076;
    if ([collectionView respondsToSelector:@selector(setPrefetchingEnabled:)]) {
        collectionView.prefetchingEnabled = NO;
    }
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    [self addSubview:collectionView];
    _collectionView = collectionView;
    [self updateTransformLayoutDelegate];
}

- (void)updateTransformLayoutDelegate {
    if (!self.collectionView) {
        return;
    }
    ((MahaCyclePagerTransformLayout *)self.collectionView.collectionViewLayout).delegate = _delegateFlags.respondsToApplyTransformToAttributes ? self : nil;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self stopAutoScrollTimer];
    if (newSuperview && _autoScrollInterval > 0) {
        [self startAutoScrollTimer];
    }
}

- (void)startAutoScrollTimer {
    if (_autoScrollTimer || _autoScrollInterval <= 0) {
        return;
    }
    _autoScrollTimer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:self selector:@selector(handleAutoScrollTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_autoScrollTimer forMode:NSRunLoopCommonModes];
}

- (void)stopAutoScrollTimer {
    if (!_autoScrollTimer) {
        return;
    }
    [_autoScrollTimer invalidate];
    _autoScrollTimer = nil;
}

- (void)handleAutoScrollTimer:(NSTimer *)timer {
    if (!self.superview || !self.window || _itemCount == 0 || self.tracking) {
        return;
    }
    BOOL isRTL = NO;
    if (@available(iOS 9.0, *)) {
        isRTL = UIView.appearance.semanticContentAttribute == UISemanticContentAttributeForceRightToLeft;
    }
    [self scrollToNearestIndexAtDirection:(isRTL ? MahaPagerScrollDirectionLeft : MahaPagerScrollDirectionRight) animate:YES];
}

- (MahaCyclePagerViewLayout *)layout {
    if (!_layout) {
        if (_dataSourceFlags.respondsToLayoutForPagerView) {
            _layout = [_dataSource layoutForPagerView:self];
            _layout.isInfiniteLoop = _isInfiniteLoop;
        }
        if (_layout.itemSize.width <= 0 || _layout.itemSize.height <= 0) {
            _layout = nil;
        }
    }
    return _layout;
}

- (NSInteger)curIndex {
    return _indexSection.index;
}

- (NSInteger)currentIndex {
    return _indexSection.index;
}

- (CGPoint)contentOffset {
    return _collectionView.contentOffset;
}

- (BOOL)tracking {
    return _collectionView.tracking;
}

- (BOOL)dragging {
    return _collectionView.dragging;
}

- (BOOL)decelerating {
    return _collectionView.decelerating;
}

- (UIView *)backgroundView {
    return _collectionView.backgroundView;
}

- (__kindof UICollectionViewCell *)curIndexCell {
    return [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_indexSection.index inSection:_indexSection.section]];
}

- (__kindof UICollectionViewCell *)currentIndexCell {
    return [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_indexSection.index inSection:_indexSection.section]];
}

- (NSArray<__kindof UICollectionViewCell *> *)visibleCells {
    return _collectionView.visibleCells;
}

- (NSArray *)visibleIndexes {
    NSMutableArray *visibleIndexes = [NSMutableArray array];
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
        [visibleIndexes addObject:@(indexPath.item)];
    }
    return [visibleIndexes copy];
}

- (NSArray *)visibleIndexs {
    return [self visibleIndexes];
}

- (void)setBackgroundView:(UIView *)backgroundView {
    [_collectionView setBackgroundView:backgroundView];
}

- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval {
    _autoScrollInterval = autoScrollInterval;
    [self stopAutoScrollTimer];
    if (autoScrollInterval > 0 && self.superview) {
        [self startAutoScrollTimer];
    }
}

- (void)setDelegate:(id<MahaCyclePagerViewDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.respondsToPagerViewDidScroll = [delegate respondsToSelector:@selector(pagerViewDidScroll:)];
    _delegateFlags.respondsToDidScrollFromIndexToIndex = [delegate respondsToSelector:@selector(pagerView:didScrollFromIndex:toIndex:)];
    _delegateFlags.respondsToInitializeTransformAttributes = [delegate respondsToSelector:@selector(pagerView:initializeTransformAttributes:)];
    _delegateFlags.respondsToApplyTransformToAttributes = [delegate respondsToSelector:@selector(pagerView:applyTransformToAttributes:)];
    [self updateTransformLayoutDelegate];
}

- (void)setDataSource:(id<MahaCyclePagerViewDataSource>)dataSource {
    _dataSource = dataSource;
    _dataSourceFlags.respondsToCellForItemAtIndex = [dataSource respondsToSelector:@selector(pagerView:cellForItemAtIndex:)];
    _dataSourceFlags.respondsToLayoutForPagerView = [dataSource respondsToSelector:@selector(layoutForPagerView:)];
}

- (void)reloadData {
    _hasReloadedData = YES;
    _shouldResetIndexAfterReload = YES;
    [self setNeedClearLayout];
    [self clearCachedLayoutIfNeeded];
    [self updateData];
}

- (void)updateData {
    [self refreshCollectionLayout];
    _itemCount = [_dataSource numberOfItemsInPagerView:self];
    [_collectionView reloadData];
    if (!_hasCompletedLayout && !CGRectIsEmpty(self.collectionView.frame) && _indexSection.index < 0) {
        _hasCompletedLayout = YES;
    }
    BOOL shouldResetToInitialIndex = _shouldResetIndexAfterReload && _reloadDataNeedResetIndex;
    _shouldResetIndexAfterReload = NO;
    NSInteger targetIndex = ((_indexSection.index < 0 && !CGRectIsEmpty(self.collectionView.frame)) || shouldResetToInitialIndex) ? 0 : _indexSection.index;
    [self resetPagerViewAtIndex:targetIndex];
    if (shouldResetToInitialIndex) {
        [self startAutoScrollTimer];
    }
}

- (void)scrollToNearlyIndexAtDirection:(MahaPagerScrollDirection)direction animate:(BOOL)animate {
    [self scrollToNearestIndexAtDirection:direction animate:animate];
}

- (void)scrollToNearestIndexAtDirection:(MahaPagerScrollDirection)direction animate:(BOOL)animate {
    MahaIndexSection indexSection = [self adjacentIndexSectionAtDirection:direction];
    [self scrollToItemAtIndexSection:indexSection animate:animate];
}

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
    if (!_hasCompletedLayout && _hasReloadedData) {
        _pendingInitialScrollIndex = index;
    } else {
        _pendingInitialScrollIndex = -1;
    }
    if (!_isInfiniteLoop) {
        [self scrollToItemAtIndexSection:MahaMakeIndexSection(index, 0) animate:animate];
        return;
    }
    NSInteger targetSection = index >= self.currentIndex ? _indexSection.section : _indexSection.section + 1;
    [self scrollToItemAtIndexSection:MahaMakeIndexSection(index, targetSection) animate:animate];
}

- (void)scrollToItemAtIndexSection:(MahaIndexSection)indexSection animate:(BOOL)animate {
    if (_itemCount <= 0 || ![self isValidIndexSection:indexSection]) {
        return;
    }
    if (animate && [_delegate respondsToSelector:@selector(pagerViewWillBeginScrollingAnimation:)]) {
        [_delegate pagerViewWillBeginScrollingAnimation:self];
    }
    CGFloat targetOffsetX = [self contentOffsetXForIndexSection:indexSection];
    [_collectionView setContentOffset:CGPointMake(targetOffsetX, _collectionView.contentOffset.y) animated:animate];
}

- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:Class forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    return [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:_reuseSection]];
}

- (void)refreshCollectionLayout {
    if (!self.layout) {
        return;
    }
    self.layout.isInfiniteLoop = _isInfiniteLoop;
    ((MahaCyclePagerTransformLayout *)_collectionView.collectionViewLayout).layout = self.layout;
}

- (void)clearCachedLayoutIfNeeded {
    if (_shouldClearCachedLayout) {
        _layout = nil;
        _shouldClearCachedLayout = NO;
    }
}

- (void)setNeedClearLayout {
    _shouldClearCachedLayout = YES;
}

- (void)setNeedUpdateLayout {
    if (!self.layout) {
        return;
    }
    [self clearCachedLayoutIfNeeded];
    [self refreshCollectionLayout];
    [_collectionView.collectionViewLayout invalidateLayout];
    [self resetPagerViewAtIndex:_indexSection.index < 0 ? 0 : _indexSection.index];
}

- (BOOL)isValidIndexSection:(MahaIndexSection)indexSection {
    return indexSection.index >= 0 && indexSection.index < _itemCount && indexSection.section >= 0 && indexSection.section < MahaPagerViewMaxSectionCount;
}

- (MahaIndexSection)adjacentIndexSectionAtDirection:(MahaPagerScrollDirection)direction {
    return [self adjacentIndexSectionFromIndexSection:_indexSection direction:direction];
}

- (MahaIndexSection)adjacentIndexSectionFromIndexSection:(MahaIndexSection)indexSection direction:(MahaPagerScrollDirection)direction {
    if (indexSection.index < 0 || indexSection.index >= _itemCount) {
        return indexSection;
    }

    if (!_isInfiniteLoop) {
        if (direction == MahaPagerScrollDirectionRight && indexSection.index == _itemCount - 1) {
            return _autoScrollInterval > 0 ? MahaMakeIndexSection(0, 0) : indexSection;
        } else if (direction == MahaPagerScrollDirectionRight) {
            return MahaMakeIndexSection(indexSection.index + 1, 0);
        }

        if (indexSection.index == 0) {
            return _autoScrollInterval > 0 ? MahaMakeIndexSection(_itemCount - 1, 0) : indexSection;
        }
        return MahaMakeIndexSection(indexSection.index - 1, 0);
    }

    if (direction == MahaPagerScrollDirectionRight) {
        if (indexSection.index < _itemCount - 1) {
            return MahaMakeIndexSection(indexSection.index + 1, indexSection.section);
        }
        if (indexSection.section >= MahaPagerViewMaxSectionCount - 1) {
            return MahaMakeIndexSection(indexSection.index, MahaPagerViewMaxSectionCount - 1);
        }
        return MahaMakeIndexSection(0, indexSection.section + 1);
    }

    if (indexSection.index > 0) {
        return MahaMakeIndexSection(indexSection.index - 1, indexSection.section);
    }
    if (indexSection.section <= 0) {
        return MahaMakeIndexSection(indexSection.index, 0);
    }
    return MahaMakeIndexSection(_itemCount - 1, indexSection.section - 1);
}

- (MahaIndexSection)indexSectionForContentOffsetX:(CGFloat)contentOffsetX {
    if (_itemCount <= 0) {
        return MahaMakeIndexSection(0, 0);
    }
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    CGFloat leadingInset = _isInfiniteLoop ? _layout.sectionInset.left : _layout.onlyOneSectionInset.left;
    CGFloat collectionViewWidth = CGRectGetWidth(_collectionView.frame);
    CGFloat centeredOffsetX = contentOffsetX + collectionViewWidth / 2;
    CGFloat itemStride = flowLayout.itemSize.width + flowLayout.minimumInteritemSpacing;
    NSInteger currentIndex = 0;
    NSInteger currentSection = 0;
    if (centeredOffsetX - leadingInset >= 0) {
        NSInteger itemIndex = (centeredOffsetX - leadingInset + flowLayout.minimumInteritemSpacing / 2) / itemStride;
        if (itemIndex < 0) {
            itemIndex = 0;
        } else if (itemIndex >= _itemCount * MahaPagerViewMaxSectionCount) {
            itemIndex = _itemCount * MahaPagerViewMaxSectionCount - 1;
        }
        currentIndex = itemIndex % _itemCount;
        currentSection = itemIndex / _itemCount;
    }
    return MahaMakeIndexSection(currentIndex, currentSection);
}

- (CGFloat)contentOffsetXForIndexSection:(MahaIndexSection)indexSection {
    if (_itemCount == 0) {
        return 0;
    }
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    UIEdgeInsets sectionInset = _isInfiniteLoop ? _layout.sectionInset : _layout.onlyOneSectionInset;
    CGFloat leadingInset = sectionInset.left;
    CGFloat trailingInset = sectionInset.right;
    CGFloat collectionViewWidth = CGRectGetWidth(_collectionView.frame);
    CGFloat itemStride = flowLayout.itemSize.width + flowLayout.minimumInteritemSpacing;
    CGFloat targetOffsetX = 0;
    if (!_isInfiniteLoop && !_layout.itemHorizontalCenter && indexSection.index == _itemCount - 1) {
        targetOffsetX = leadingInset + itemStride * (indexSection.index + indexSection.section * _itemCount) - (collectionViewWidth - itemStride) - flowLayout.minimumInteritemSpacing + trailingInset;
    } else {
        targetOffsetX = leadingInset + itemStride * (indexSection.index + indexSection.section * _itemCount) - flowLayout.minimumInteritemSpacing / 2 - (collectionViewWidth - itemStride) / 2;
    }
    return MAX(targetOffsetX, 0);
}

- (void)resetPagerViewAtIndex:(NSInteger)index {
    if (_hasCompletedLayout && _pendingInitialScrollIndex >= 0) {
        index = _pendingInitialScrollIndex;
        _pendingInitialScrollIndex = -1;
    }
    if (index < 0) {
        return;
    }
    if (index >= _itemCount) {
        index = 0;
    }
    NSInteger targetSection = _isInfiniteLoop ? MahaPagerViewMaxSectionCount / 3 : 0;
    [self scrollToItemAtIndexSection:MahaMakeIndexSection(index, targetSection) animate:NO];
    if (!_isInfiniteLoop && _indexSection.index < 0) {
        [self scrollViewDidScroll:_collectionView];
    }
}

- (void)recyclePagerViewIfNeeded {
    if (!_isInfiniteLoop) {
        return;
    }
    if (_indexSection.section > MahaPagerViewMaxSectionCount - MahaPagerViewMinSectionCount || _indexSection.section < MahaPagerViewMinSectionCount) {
        [self resetPagerViewAtIndex:_indexSection.index];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _isInfiniteLoop ? MahaPagerViewMaxSectionCount : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    _itemCount = [_dataSource numberOfItemsInPagerView:self];
    return _itemCount;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _reuseSection = indexPath.section;
    if (_dataSourceFlags.respondsToCellForItemAtIndex) {
        return [_dataSource pagerView:self cellForItemAtIndex:indexPath.row];
    }
    NSAssert(NO, @"pagerView cellForItemAtIndex: is nil!");
    return nil;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (!_isInfiniteLoop) {
        return _layout.onlyOneSectionInset;
    }
    if (section == 0) {
        return _layout.firstSectionInset;
    } else if (section == MahaPagerViewMaxSectionCount - 1) {
        return _layout.lastSectionInset;
    }
    return _layout.middleSectionInset;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *selectedCell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectItemCell:atIndex:)]) {
        [_delegate pagerView:self didSelectItemCell:selectedCell atIndex:indexPath.item];
    } else if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndex:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [_delegate pagerView:self didSelectedItemCell:selectedCell atIndex:indexPath.item];
#pragma clang diagnostic pop
    }
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectItemCell:atIndexSection:)]) {
        [_delegate pagerView:self didSelectItemCell:selectedCell atIndexSection:MahaMakeIndexSection(indexPath.item, indexPath.section)];
    } else if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndexSection:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [_delegate pagerView:self didSelectedItemCell:selectedCell atIndexSection:MahaMakeIndexSection(indexPath.item, indexPath.section)];
#pragma clang diagnostic pop
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_hasCompletedLayout) {
        return;
    }
    MahaIndexSection updatedIndexSection = [self indexSectionForContentOffsetX:scrollView.contentOffset.x];
    if (_itemCount <= 0 || ![self isValidIndexSection:updatedIndexSection]) {
        NSLog(@"invalidIndexSection:(%ld,%ld)!", (long)updatedIndexSection.index, (long)updatedIndexSection.section);
        return;
    }
    MahaIndexSection previousIndexSection = _indexSection;
    _indexSection = updatedIndexSection;

    if (_delegateFlags.respondsToPagerViewDidScroll) {
        [_delegate pagerViewDidScroll:self];
    }
    if (_delegateFlags.respondsToDidScrollFromIndexToIndex && !MahaEqualIndexSection(_indexSection, previousIndexSection)) {
        [_delegate pagerView:self didScrollFromIndex:MAX(previousIndexSection.index, 0) toIndex:_indexSection.index];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_autoScrollInterval > 0) {
        [self stopAutoScrollTimer];
    }
    _dragStartIndexSection = [self indexSectionForContentOffsetX:scrollView.contentOffset.x];
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDragging:)]) {
        [_delegate pagerViewWillBeginDragging:self];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (fabs(velocity.x) < 0.35 || !MahaEqualIndexSection(_dragStartIndexSection, _indexSection)) {
        targetContentOffset->x = [self contentOffsetXForIndexSection:_indexSection];
        return;
    }
    MahaPagerScrollDirection direction = MahaPagerScrollDirectionRight;
    if ((scrollView.contentOffset.x < 0 && targetContentOffset->x <= 0) || (targetContentOffset->x < scrollView.contentOffset.x && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width)) {
        direction = MahaPagerScrollDirectionLeft;
    }
    MahaIndexSection targetIndexSection = [self adjacentIndexSectionFromIndexSection:_indexSection direction:direction];
    targetContentOffset->x = [self contentOffsetXForIndexSection:targetIndexSection];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_autoScrollInterval > 0) {
        [self startAutoScrollTimer];
    }
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDragging:willDecelerate:)]) {
        [_delegate pagerViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDecelerating:)]) {
        [_delegate pagerViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self recyclePagerViewIfNeeded];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDecelerating:)]) {
        [_delegate pagerViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self recyclePagerViewIfNeeded];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndScrollingAnimation:)]) {
        [_delegate pagerViewDidEndScrollingAnimation:self];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL collectionViewFrameChanged = !CGRectEqualToRect(_collectionView.frame, self.bounds);
    _collectionView.frame = self.bounds;
    if ((_indexSection.section < 0 || collectionViewFrameChanged) && (_itemCount > 0 || _hasReloadedData)) {
        _hasCompletedLayout = YES;
        [self setNeedUpdateLayout];
    }
}

- (void)pagerViewTransformLayout:(MahaCyclePagerTransformLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.respondsToInitializeTransformAttributes) {
        [_delegate pagerView:self initializeTransformAttributes:attributes];
    }
}

- (void)pagerViewTransformLayout:(MahaCyclePagerTransformLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.respondsToApplyTransformToAttributes) {
        [_delegate pagerView:self applyTransformToAttributes:attributes];
    }
}

- (void)dealloc {
    ((MahaCyclePagerTransformLayout *)_collectionView.collectionViewLayout).delegate = nil;
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

@end
