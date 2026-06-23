# MahaCyclePagerKit

MahaCyclePagerKit is a private wrapper of the original cycle pager component used by the app.

It keeps the existing behavior while exposing cleaned-up public APIs.

- `MahaCyclePagerView`
- `MahaCyclePagerViewLayout`
- `MahaCyclePagerTransformLayout`
- `MahaCyclePagerViewDataSource`
- `MahaCyclePagerViewDelegate`
- `MahaPageControl`

Preferred public naming:

- `currentIndex` instead of `curIndex`
- `currentIndexCell` instead of `curIndexCell`
- `visibleIndexes` instead of `visibleIndexs`
- `scrollToNearestIndexAtDirection:animate:` instead of `scrollToNearlyIndexAtDirection:animate:`
- `didSelectItemCell...` instead of `didSelectedItemCell...`
- `pageIndicatorSpacing` instead of `pageIndicatorSpaing`
- `animationDuration` instead of `animateDuring`

Compatibility:

- Legacy API names are still available for existing callers.
- New code should use the preferred names above.

## Quick Start

```objc
#import <MahaCyclePagerKit/MahaCyclePagerView.h>

@interface DemoViewController () <MahaCyclePagerViewDataSource, MahaCyclePagerViewDelegate>

@property (nonatomic, strong) MahaCyclePagerView *pagerView;
@property (nonatomic, strong) MahaPageControl *pageControl;
@property (nonatomic, copy) NSArray<NSString *> *items;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.items = @[@"A", @"B", @"C"];

    self.pagerView = [[MahaCyclePagerView alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, 220)];
    self.pagerView.dataSource = self;
    self.pagerView.delegate = self;
    self.pagerView.autoScrollInterval = 3.0;
    self.pagerView.isInfiniteLoop = YES;
    [self.pagerView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:self.pagerView];
    [self.pagerView reloadData];

    self.pageControl = [[MahaPageControl alloc] initWithFrame:CGRectMake(0, 360, self.view.bounds.size.width, 20)];
    self.pageControl.numberOfPages = self.items.count;
    self.pageControl.pageIndicatorSpacing = 8;
    self.pageControl.animationDuration = 0.25;
    [self.view addSubview:self.pageControl];
}

- (NSInteger)numberOfItemsInPagerView:(MahaCyclePagerView *)pageView {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)pagerView:(MahaCyclePagerView *)pagerView cellForItemAtIndex:(NSInteger)index {
    UICollectionViewCell *cell = [pagerView dequeueReusableCellWithReuseIdentifier:@"cell" forIndex:index];
    cell.contentView.backgroundColor = UIColor.lightGrayColor;
    return cell;
}

- (MahaCyclePagerViewLayout *)layoutForPagerView:(MahaCyclePagerView *)pageView {
    MahaCyclePagerViewLayout *layout = [[MahaCyclePagerViewLayout alloc] init];
    layout.itemSize = CGSizeMake(self.view.bounds.size.width - 40, 220);
    layout.itemSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    return layout;
}

- (void)pagerView:(MahaCyclePagerView *)pageView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    self.pageControl.currentPage = toIndex;
}

@end
```

## Migration Notes

- Prefer `currentIndex`, `currentIndexCell`, `visibleIndexes`, `pageIndicatorSpacing`, and `animationDuration`.
- The old names are still retained for compatibility, but new code should avoid introducing them.
