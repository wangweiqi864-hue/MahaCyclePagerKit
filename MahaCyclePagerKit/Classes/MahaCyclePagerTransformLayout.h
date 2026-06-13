#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MahaCyclePagerTransformLayoutType) {
    MahaCyclePagerTransformLayoutNormal,
    MahaCyclePagerTransformLayoutLinear,
    MahaCyclePagerTransformLayoutCoverflow,
};

@class MahaCyclePagerTransformLayout;

@protocol MahaCyclePagerTransformLayoutDelegate <NSObject>

- (void)pagerViewTransformLayout:(MahaCyclePagerTransformLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;
- (void)pagerViewTransformLayout:(MahaCyclePagerTransformLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;

@end

@interface MahaCyclePagerViewLayout : NSObject

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;
@property (nonatomic, assign) MahaCyclePagerTransformLayoutType layoutType;
@property (nonatomic, assign) CGFloat minimumScale;
@property (nonatomic, assign) CGFloat minimumAlpha;
@property (nonatomic, assign) CGFloat maximumAngle;
@property (nonatomic, assign) BOOL isInfiniteLoop;
@property (nonatomic, assign) CGFloat rateOfChange;
@property (nonatomic, assign) BOOL adjustSpacingWhenScroling;
@property (nonatomic, assign) BOOL itemVerticalCenter;
@property (nonatomic, assign) BOOL itemHorizontalCenter;
@property (nonatomic, assign, readonly) UIEdgeInsets onlyOneSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets firstSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets lastSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets middleSectionInset;

@end

@interface MahaCyclePagerTransformLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) MahaCyclePagerViewLayout *layout;
@property (nonatomic, weak, nullable) id<MahaCyclePagerTransformLayoutDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
