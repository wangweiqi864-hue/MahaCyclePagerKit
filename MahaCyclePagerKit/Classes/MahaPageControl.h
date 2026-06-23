#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MahaPageControl : UIControl

@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL hidesForSinglePage;
@property (nonatomic, assign) CGFloat pageIndicatorSpacing;
@property (nonatomic, assign) CGFloat pageIndicatorSpaing DEPRECATED_MSG_ATTRIBUTE("Use pageIndicatorSpacing instead.");
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign, readonly) CGSize contentSize;
@property (nullable, nonatomic, strong) UIColor *pageIndicatorTintColor;
@property (nullable, nonatomic, strong) UIColor *currentPageIndicatorTintColor;
@property (nullable, nonatomic, strong) UIImage *pageIndicatorImage;
@property (nullable, nonatomic, strong) UIImage *currentPageIndicatorImage;
@property (nonatomic, assign) UIViewContentMode indicatorImageContentMode;
@property (nonatomic, assign) CGSize pageIndicatorSize;
@property (nonatomic, assign) CGSize currentPageIndicatorSize;
@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) CGFloat animateDuring DEPRECATED_MSG_ATTRIBUTE("Use animationDuration instead.");

- (void)setCurrentPage:(NSInteger)currentPage animate:(BOOL)animate;

@end

NS_ASSUME_NONNULL_END
