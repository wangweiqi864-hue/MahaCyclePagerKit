#import <UIKit/UIKit.h>

#if __has_include(<MahaCyclePagerKit/MahaCyclePagerView.h>)
#import <MahaCyclePagerKit/MahaCyclePagerTransformLayout.h>
#else
#import "MahaCyclePagerTransformLayout.h"
#endif

#if __has_include(<MahaCyclePagerKit/MahaPageControl.h>)
#import <MahaCyclePagerKit/MahaPageControl.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    NSInteger index;
    NSInteger section;
} MahaIndexSection;

typedef NS_ENUM(NSUInteger, MahaPagerScrollDirection) {
    MahaPagerScrollDirectionLeft,
    MahaPagerScrollDirectionRight,
};

@class MahaCyclePagerView;

@protocol MahaCyclePagerViewDataSource <NSObject>

- (NSInteger)numberOfItemsInPagerView:(MahaCyclePagerView *)pageView;
- (__kindof UICollectionViewCell *)pagerView:(MahaCyclePagerView *)pagerView cellForItemAtIndex:(NSInteger)index;
- (MahaCyclePagerViewLayout *)layoutForPagerView:(MahaCyclePagerView *)pageView;

@end

@protocol MahaCyclePagerViewDelegate <NSObject>

@optional

- (void)pagerView:(MahaCyclePagerView *)pageView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)pagerView:(MahaCyclePagerView *)pageView didSelectItemCell:(__kindof UICollectionViewCell *)cell atIndex:(NSInteger)index;
- (void)pagerView:(MahaCyclePagerView *)pageView didSelectItemCell:(__kindof UICollectionViewCell *)cell atIndexSection:(MahaIndexSection)indexSection;
- (void)pagerView:(MahaCyclePagerView *)pageView didSelectedItemCell:(__kindof UICollectionViewCell *)cell atIndex:(NSInteger)index DEPRECATED_MSG_ATTRIBUTE("Use pagerView:didSelectItemCell:atIndex: instead.");
- (void)pagerView:(MahaCyclePagerView *)pageView didSelectedItemCell:(__kindof UICollectionViewCell *)cell atIndexSection:(MahaIndexSection)indexSection DEPRECATED_MSG_ATTRIBUTE("Use pagerView:didSelectItemCell:atIndexSection: instead.");
- (void)pagerView:(MahaCyclePagerView *)pageView initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;
- (void)pagerView:(MahaCyclePagerView *)pageView applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;
- (void)pagerViewDidScroll:(MahaCyclePagerView *)pageView;
- (void)pagerViewWillBeginDragging:(MahaCyclePagerView *)pageView;
- (void)pagerViewDidEndDragging:(MahaCyclePagerView *)pageView willDecelerate:(BOOL)decelerate;
- (void)pagerViewWillBeginDecelerating:(MahaCyclePagerView *)pageView;
- (void)pagerViewDidEndDecelerating:(MahaCyclePagerView *)pageView;
- (void)pagerViewWillBeginScrollingAnimation:(MahaCyclePagerView *)pageView;
- (void)pagerViewDidEndScrollingAnimation:(MahaCyclePagerView *)pageView;

@end

@interface MahaCyclePagerView : UIView

@property (nonatomic, strong, nullable) UIView *backgroundView;
@property (nonatomic, weak, nullable) id<MahaCyclePagerViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<MahaCyclePagerViewDelegate> delegate;
@property (nonatomic, weak, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) MahaCyclePagerViewLayout *layout;
@property (nonatomic, assign) BOOL isInfiniteLoop;
@property (nonatomic, assign) CGFloat autoScrollInterval;
@property (nonatomic, assign) BOOL reloadDataNeedResetIndex;
@property (nonatomic, assign, readonly) NSInteger currentIndex;
@property (nonatomic, assign, readonly) NSInteger curIndex DEPRECATED_MSG_ATTRIBUTE("Use currentIndex instead.");
@property (nonatomic, assign, readonly) MahaIndexSection indexSection;
@property (nonatomic, assign, readonly) CGPoint contentOffset;
@property (nonatomic, assign, readonly) BOOL tracking;
@property (nonatomic, assign, readonly) BOOL dragging;
@property (nonatomic, assign, readonly) BOOL decelerating;

- (void)reloadData;
- (void)updateData;
- (void)setNeedUpdateLayout;
- (void)setNeedClearLayout;
- (__kindof UICollectionViewCell * _Nullable)currentIndexCell;
- (__kindof UICollectionViewCell * _Nullable)curIndexCell DEPRECATED_MSG_ATTRIBUTE("Use currentIndexCell instead.");
- (NSArray<__kindof UICollectionViewCell *> * _Nullable)visibleCells;
- (NSArray *)visibleIndexes;
- (NSArray *)visibleIndexs DEPRECATED_MSG_ATTRIBUTE("Use visibleIndexes instead.");
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;
- (void)scrollToItemAtIndexSection:(MahaIndexSection)indexSection animate:(BOOL)animate;
- (void)scrollToNearestIndexAtDirection:(MahaPagerScrollDirection)direction animate:(BOOL)animate;
- (void)scrollToNearlyIndexAtDirection:(MahaPagerScrollDirection)direction animate:(BOOL)animate DEPRECATED_MSG_ATTRIBUTE("Use scrollToNearestIndexAtDirection:animate: instead.");
- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;
- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
