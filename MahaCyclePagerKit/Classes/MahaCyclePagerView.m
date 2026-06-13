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
        unsigned int pagerViewDidScroll : 1;
        unsigned int didScrollFromIndexToNewIndex : 1;
        unsigned int initializeTransformAttributes : 1;
        unsigned int applyTransformToAttributes : 1;
    } _delegateFlags;
    struct {
        unsigned int cellForItemAtIndex : 1;
        unsigned int layoutForPagerView : 1;
    } _dataSourceFlags;
}

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) MahaCyclePagerViewLayout *layout;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, assign) NSInteger dequeueSection;
@property (nonatomic, assign) MahaIndexSection beginDragIndexSection;
@property (nonatomic, assign) NSInteger firstScrollIndex;
@property (nonatomic, assign) BOOL needClearLayout;
@property (nonatomic, assign) BOOL didReloadData;
@property (nonatomic, assign) BOOL didLayout;
@property (nonatomic, assign) BOOL needResetIndex;

@end

#define kMahaPagerViewMaxSectionCount 200
#define kMahaPagerViewMinSectionCount 18

@implementation MahaCyclePagerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureProperty];
        [self addCollectionView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self configureProperty];
        [self addCollectionView];
    }
    return self;
}

- (void)configureProperty {
    _needResetIndex = NO;
    _didReloadData = NO;
    _didLayout = NO;
    _autoScrollInterval = 0;
    _isInfiniteLoop = YES;
    _beginDragIndexSection.index = 0;
    _beginDragIndexSection.section = 0;
    _indexSection.index = -1;
    _indexSection.section = -1;
    _firstScrollIndex = -1;
}

- (void)addCollectionView {
    MahaCyclePagerTransformLayout *layout = [[MahaCyclePagerTransformLayout alloc] init];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    layout.delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
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
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!newSuperview) {
        [self removeTimer];
    } else {
        [self removeTimer];
        if (_autoScrollInterval > 0) {
            [self addTimer];
        }
    }
}

- (void)addTimer {
    if (_timer || _autoScrollInterval <= 0) {
        return;
    }
    _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer {
    if (!_timer) {
        return;
    }
    [_timer invalidate];
    _timer = nil;
}

- (void)timerFired:(NSTimer *)timer {
    if (!self.superview || !self.window || _numberOfItems == 0 || self.tracking) {
        return;
    }
    BOOL isRTL = NO;
    if (@available(iOS 9.0, *)) {
        isRTL = UIView.appearance.semanticContentAttribute == UISemanticContentAttributeForceRightToLeft;
    }
    [self scrollToNearlyIndexAtDirection:(isRTL ? MahaPagerScrollDirectionLeft : MahaPagerScrollDirectionRight) animate:YES];
}

- (MahaCyclePagerViewLayout *)layout {
    if (!_layout) {
        if (_dataSourceFlags.layoutForPagerView) {
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

- (NSArray<__kindof UICollectionViewCell *> *)visibleCells {
    return _collectionView.visibleCells;
}

- (NSArray *)visibleIndexs {
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
        [indexs addObject:@(indexPath.item)];
    }
    return [indexs copy];
}

- (void)setBackgroundView:(UIView *)backgroundView {
    [_collectionView setBackgroundView:backgroundView];
}

- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval {
    _autoScrollInterval = autoScrollInterval;
    [self removeTimer];
    if (autoScrollInterval > 0 && self.superview) {
        [self addTimer];
    }
}

- (void)setDelegate:(id<MahaCyclePagerViewDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.pagerViewDidScroll = [delegate respondsToSelector:@selector(pagerViewDidScroll:)];
    _delegateFlags.didScrollFromIndexToNewIndex = [delegate respondsToSelector:@selector(pagerView:didScrollFromIndex:toIndex:)];
    _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(pagerView:initializeTransformAttributes:)];
    _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(pagerView:applyTransformToAttributes:)];
    if (self.collectionView && self.collectionView.collectionViewLayout) {
        ((MahaCyclePagerTransformLayout *)self.collectionView.collectionViewLayout).delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
    }
}

- (void)setDataSource:(id<MahaCyclePagerViewDataSource>)dataSource {
    _dataSource = dataSource;
    _dataSourceFlags.cellForItemAtIndex = [dataSource respondsToSelector:@selector(pagerView:cellForItemAtIndex:)];
    _dataSourceFlags.layoutForPagerView = [dataSource respondsToSelector:@selector(layoutForPagerView:)];
}

- (void)reloadData {
    _didReloadData = YES;
    _needResetIndex = YES;
    [self setNeedClearLayout];
    [self clearLayout];
    [self updateData];
}

- (void)updateData {
    [self updateLayout];
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];
    [_collectionView reloadData];
    if (!_didLayout && !CGRectIsEmpty(self.collectionView.frame) && _indexSection.index < 0) {
        _didLayout = YES;
    }
    BOOL needResetIndex = _needResetIndex && _reloadDataNeedResetIndex;
    _needResetIndex = NO;
    [self resetPagerViewAtIndex:(_indexSection.index < 0 && !CGRectIsEmpty(self.collectionView.frame)) || needResetIndex ? 0 : _indexSection.index];
    if (needResetIndex) {
        [self addTimer];
    }
}

- (void)scrollToNearlyIndexAtDirection:(MahaPagerScrollDirection)direction animate:(BOOL)animate {
    MahaIndexSection indexSection = [self nearlyIndexPathAtDirection:direction];
    [self scrollToItemAtIndexSection:indexSection animate:animate];
}

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
    if (!_didLayout && _didReloadData) {
        _firstScrollIndex = index;
    } else {
        _firstScrollIndex = -1;
    }
    if (!_isInfiniteLoop) {
        [self scrollToItemAtIndexSection:MahaMakeIndexSection(index, 0) animate:animate];
        return;
    }
    [self scrollToItemAtIndexSection:MahaMakeIndexSection(index, index >= self.curIndex ? _indexSection.section : _indexSection.section + 1) animate:animate];
}

- (void)scrollToItemAtIndexSection:(MahaIndexSection)indexSection animate:(BOOL)animate {
    if (_numberOfItems <= 0 || ![self isValidIndexSection:indexSection]) {
        return;
    }
    if (animate && [_delegate respondsToSelector:@selector(pagerViewWillBeginScrollingAnimation:)]) {
        [_delegate pagerViewWillBeginScrollingAnimation:self];
    }
    CGFloat offset = [self calculateOffsetXAtIndexSection:indexSection];
    [_collectionView setContentOffset:CGPointMake(offset, _collectionView.contentOffset.y) animated:animate];
}

- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:Class forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    UICollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:_dequeueSection]];
    return cell;
}

- (void)updateLayout {
    if (!self.layout) {
        return;
    }
    self.layout.isInfiniteLoop = _isInfiniteLoop;
    ((MahaCyclePagerTransformLayout *)_collectionView.collectionViewLayout).layout = self.layout;
}

- (void)clearLayout {
    if (_needClearLayout) {
        _layout = nil;
        _needClearLayout = NO;
    }
}

- (void)setNeedClearLayout {
    _needClearLayout = YES;
}

- (void)setNeedUpdateLayout {
    if (!self.layout) {
        return;
    }
    [self clearLayout];
    [self updateLayout];
    [_collectionView.collectionViewLayout invalidateLayout];
    [self resetPagerViewAtIndex:_indexSection.index < 0 ? 0 : _indexSection.index];
}

- (BOOL)isValidIndexSection:(MahaIndexSection)indexSection {
    return indexSection.index >= 0 && indexSection.index < _numberOfItems && indexSection.section >= 0 && indexSection.section < kMahaPagerViewMaxSectionCount;
}

- (MahaIndexSection)nearlyIndexPathAtDirection:(MahaPagerScrollDirection)direction {
    return [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
}

- (MahaIndexSection)nearlyIndexPathForIndexSection:(MahaIndexSection)indexSection direction:(MahaPagerScrollDirection)direction {
    if (indexSection.index < 0 || indexSection.index >= _numberOfItems) {
        return indexSection;
    }

    if (!_isInfiniteLoop) {
        if (direction == MahaPagerScrollDirectionRight && indexSection.index == _numberOfItems - 1) {
            return _autoScrollInterval > 0 ? MahaMakeIndexSection(0, 0) : indexSection;
        } else if (direction == MahaPagerScrollDirectionRight) {
            return MahaMakeIndexSection(indexSection.index + 1, 0);
        }

        if (indexSection.index == 0) {
            return _autoScrollInterval > 0 ? MahaMakeIndexSection(_numberOfItems - 1, 0) : indexSection;
        }
        return MahaMakeIndexSection(indexSection.index - 1, 0);
    }

    if (direction == MahaPagerScrollDirectionRight) {
        if (indexSection.index < _numberOfItems - 1) {
            return MahaMakeIndexSection(indexSection.index + 1, indexSection.section);
        }
        if (indexSection.section >= kMahaPagerViewMaxSectionCount - 1) {
            return MahaMakeIndexSection(indexSection.index, kMahaPagerViewMaxSectionCount - 1);
        }
        return MahaMakeIndexSection(0, indexSection.section + 1);
    }

    if (indexSection.index > 0) {
        return MahaMakeIndexSection(indexSection.index - 1, indexSection.section);
    }
    if (indexSection.section <= 0) {
        return MahaMakeIndexSection(indexSection.index, 0);
    }
    return MahaMakeIndexSection(_numberOfItems - 1, indexSection.section - 1);
}

- (MahaIndexSection)calculateIndexSectionWithOffsetX:(CGFloat)offsetX {
    if (_numberOfItems <= 0) {
        return MahaMakeIndexSection(0, 0);
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    CGFloat leftEdge = _isInfiniteLoop ? _layout.sectionInset.left : _layout.onlyOneSectionInset.left;
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    CGFloat middleOffset = offsetX + width / 2;
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    NSInteger curIndex = 0;
    NSInteger curSection = 0;
    if (middleOffset - leftEdge >= 0) {
        NSInteger itemIndex = (middleOffset - leftEdge + layout.minimumInteritemSpacing / 2) / itemWidth;
        if (itemIndex < 0) {
            itemIndex = 0;
        } else if (itemIndex >= _numberOfItems * kMahaPagerViewMaxSectionCount) {
            itemIndex = _numberOfItems * kMahaPagerViewMaxSectionCount - 1;
        }
        curIndex = itemIndex % _numberOfItems;
        curSection = itemIndex / _numberOfItems;
    }
    return MahaMakeIndexSection(curIndex, curSection);
}

- (CGFloat)calculateOffsetXAtIndexSection:(MahaIndexSection)indexSection {
    if (_numberOfItems == 0) {
        return 0;
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    UIEdgeInsets edge = _isInfiniteLoop ? _layout.sectionInset : _layout.onlyOneSectionInset;
    CGFloat leftEdge = edge.left;
    CGFloat rightEdge = edge.right;
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    CGFloat offsetX = 0;
    if (!_isInfiniteLoop && !_layout.itemHorizontalCenter && indexSection.index == _numberOfItems - 1) {
        offsetX = leftEdge + itemWidth * (indexSection.index + indexSection.section * _numberOfItems) - (width - itemWidth) - layout.minimumInteritemSpacing + rightEdge;
    } else {
        offsetX = leftEdge + itemWidth * (indexSection.index + indexSection.section * _numberOfItems) - layout.minimumInteritemSpacing / 2 - (width - itemWidth) / 2;
    }
    return MAX(offsetX, 0);
}

- (void)resetPagerViewAtIndex:(NSInteger)index {
    if (_didLayout && _firstScrollIndex >= 0) {
        index = _firstScrollIndex;
        _firstScrollIndex = -1;
    }
    if (index < 0) {
        return;
    }
    if (index >= _numberOfItems) {
        index = 0;
    }
    [self scrollToItemAtIndexSection:MahaMakeIndexSection(index, _isInfiniteLoop ? kMahaPagerViewMaxSectionCount / 3 : 0) animate:NO];
    if (!_isInfiniteLoop && _indexSection.index < 0) {
        [self scrollViewDidScroll:_collectionView];
    }
}

- (void)recyclePagerViewIfNeed {
    if (!_isInfiniteLoop) {
        return;
    }
    if (_indexSection.section > kMahaPagerViewMaxSectionCount - kMahaPagerViewMinSectionCount || _indexSection.section < kMahaPagerViewMinSectionCount) {
        [self resetPagerViewAtIndex:_indexSection.index];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _isInfiniteLoop ? kMahaPagerViewMaxSectionCount : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];
    return _numberOfItems;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _dequeueSection = indexPath.section;
    if (_dataSourceFlags.cellForItemAtIndex) {
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
    } else if (section == kMahaPagerViewMaxSectionCount - 1) {
        return _layout.lastSectionInset;
    }
    return _layout.middleSectionInset;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndex:)]) {
        [_delegate pagerView:self didSelectedItemCell:cell atIndex:indexPath.item];
    }
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndexSection:)]) {
        [_delegate pagerView:self didSelectedItemCell:cell atIndexSection:MahaMakeIndexSection(indexPath.item, indexPath.section)];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_didLayout) {
        return;
    }
    MahaIndexSection newIndexSection = [self calculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    if (_numberOfItems <= 0 || ![self isValidIndexSection:newIndexSection]) {
        NSLog(@"invalidIndexSection:(%ld,%ld)!", (long)newIndexSection.index, (long)newIndexSection.section);
        return;
    }
    MahaIndexSection indexSection = _indexSection;
    _indexSection = newIndexSection;

    if (_delegateFlags.pagerViewDidScroll) {
        [_delegate pagerViewDidScroll:self];
    }
    if (_delegateFlags.didScrollFromIndexToNewIndex && !MahaEqualIndexSection(_indexSection, indexSection)) {
        [_delegate pagerView:self didScrollFromIndex:MAX(indexSection.index, 0) toIndex:_indexSection.index];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_autoScrollInterval > 0) {
        [self removeTimer];
    }
    _beginDragIndexSection = [self calculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDragging:)]) {
        [_delegate pagerViewWillBeginDragging:self];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (fabs(velocity.x) < 0.35 || !MahaEqualIndexSection(_beginDragIndexSection, _indexSection)) {
        targetContentOffset->x = [self calculateOffsetXAtIndexSection:_indexSection];
        return;
    }
    MahaPagerScrollDirection direction = MahaPagerScrollDirectionRight;
    if ((scrollView.contentOffset.x < 0 && targetContentOffset->x <= 0) || (targetContentOffset->x < scrollView.contentOffset.x && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width)) {
        direction = MahaPagerScrollDirectionLeft;
    }
    MahaIndexSection indexSection = [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
    targetContentOffset->x = [self calculateOffsetXAtIndexSection:indexSection];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_autoScrollInterval > 0) {
        [self addTimer];
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
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDecelerating:)]) {
        [_delegate pagerViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndScrollingAnimation:)]) {
        [_delegate pagerViewDidEndScrollingAnimation:self];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL needUpdateLayout = !CGRectEqualToRect(_collectionView.frame, self.bounds);
    _collectionView.frame = self.bounds;
    if ((_indexSection.section < 0 || needUpdateLayout) && (_numberOfItems > 0 || _didReloadData)) {
        _didLayout = YES;
        [self setNeedUpdateLayout];
    }
}

- (void)pagerViewTransformLayout:(MahaCyclePagerTransformLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if ([_delegate respondsToSelector:@selector(pagerView:initializeTransformAttributes:)]) {
        [_delegate pagerView:self initializeTransformAttributes:attributes];
    }
}

- (void)pagerViewTransformLayout:(MahaCyclePagerTransformLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if ([_delegate respondsToSelector:@selector(pagerView:applyTransformToAttributes:)]) {
        [_delegate pagerView:self applyTransformToAttributes:attributes];
    }
}

- (void)dealloc {
    ((MahaCyclePagerTransformLayout *)_collectionView.collectionViewLayout).delegate = nil;
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

@end
