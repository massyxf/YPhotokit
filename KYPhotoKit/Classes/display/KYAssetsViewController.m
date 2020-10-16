//
//  KYAssetsViewController.m
//  KYPhotoKit
//
//  Created by yxf on 2018/5/4.
//

#import "KYAssetsViewController.h"
#import "KYPhotoSourceManager.h"
#import "KYAssetCell.h"
#import "KYPhotoNaviViewController.h"
#import "KYHud.h"

#define KYAssetMargin 5

@implementation KYAssetviewModel

@end

@interface KYAssetsViewController ()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

/*album*/
@property (nonatomic,strong)KYAlbum *album;

/*图片信息表格*/
@property (nonatomic,weak)UICollectionView *assetCollectionView;

/*assets*/
@property (nonatomic,strong)NSArray *assets;

/*hide status bar*/
@property (nonatomic,assign)BOOL hideBar;

@property (nonatomic,weak)KYHud *hud;


@end

@implementation KYAssetsViewController

-(instancetype)init{
    return [self initWithAlbum:nil];
}

-(instancetype)initWithAlbum:(KYAlbum *)album{
    if(self = [super init]){
        _album = album;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    [self loadData];
}
#pragma mark - ui
-(void)setupUI{
    self.navigationItem.title = _album.album.localizedTitle;
    self.view.backgroundColor = [UIColor whiteColor];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(KYAssetMargin, KYAssetMargin, KYAssetMargin, KYAssetMargin);
    CGFloat length = ([UIScreen mainScreen].bounds.size.width - 4 * KYAssetMargin) / 3.0;
    layout.itemSize = CGSizeMake(length, length);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = KYAssetMargin;
    UICollectionView *assetView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    [self.view addSubview:assetView];
    [assetView registerClass:[KYAssetCell class] forCellWithReuseIdentifier:KYAssetCellIdentifier];
    _assetCollectionView = assetView;
    assetView.delegate = self;
    assetView.dataSource = self;
    assetView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - data
-(void)loadData{
    if (_album) {
        __weak typeof(self) ws = self;
        [self startLoadingData];
        [KYPhotoSourceManager getAssetsFromAlbum:_album imageSize:CGSizeMake(200, 200) complete:^(NSArray<KYAsset *> *assets) {
            [ws loadDataComplete];
            ws.assets = assets;
            [ws.assetCollectionView reloadData];
        }];
    }
}

#pragma mark - UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSMutableArray *assetviewModels = [NSMutableArray array];
    UIWindow *keywindow = [UIApplication sharedApplication].delegate.window;
    for (int i=0; i<_assets.count; i++) {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:cellIndexPath];
        CGRect frame = [cell convertRect:cell.bounds toView:keywindow];
        KYAssetviewModel *viewmodel = [[KYAssetviewModel alloc] init];
        viewmodel.asset = _assets[i];
        viewmodel.originFrame = frame;
        [assetviewModels addObject:viewmodel];
    }
    KYPhotoNaviViewController *naviVc = (KYPhotoNaviViewController *)self.navigationController;
    if ([naviVc.ky_delegate respondsToSelector:@selector(assetsViewController:allAssets:selectAssetAtIndex:)]) {
        [naviVc.ky_delegate assetsViewController:self
                                       allAssets:assetviewModels
                              selectAssetAtIndex:indexPath.item];
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    KYAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:KYAssetCellIdentifier forIndexPath:indexPath];
    cell.asset = _assets[indexPath.item];
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _assets.count;
}

#pragma mark - KYPhotoLoadingDataProtocol
-(void)startLoadingData{
    [self.hud startAnimation];
}
-(void)loadDataComplete{
    [self.hud stopAnimation];
}

#pragma mark - getter
-(BOOL)prefersStatusBarHidden{
    return self.hideBar;
}

-(KYHud *)hud{
    if (!_hud) {
        KYHud *hud = [[KYHud alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        hud.center = CGPointMake(KYSCREENWIDTH / 2, KYNAVIHEIGHT + 200);
        [self.view addSubview:hud];
        _hud = hud;
    }
    return _hud;
}

#pragma mark - KYImageScannerViewControllerDelegate
-(void)scannerVcWillPresent:(KYImageScannerViewController *)scannerVc{
    if (self.hideBar) { return;}
    self.hideBar = YES;
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)scannerVcWillDismiss:(KYImageScannerViewController *)scannerVc{
    if (!self.hideBar) { return;}
    self.hideBar = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (CGRect)scannerVc:(KYImageScannerViewController *)scannerVc dismissAtIndex:(NSInteger)index{
    KYAssetCell *cell = (KYAssetCell *)[_assetCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return [_assetCollectionView convertRect:cell.frame toView:[UIApplication sharedApplication].keyWindow];
}

@end
