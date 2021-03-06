//
//  SocietyViewController.m
//  新闻
//
//  Created by gyh on 15/9/23.
//  Copyright © 2015年 apple. All rights reserved.
//

#define SCREEN_WIDTH                    ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT                   ([UIScreen mainScreen].bounds.size.height)


#import "SocietyViewController.h"
#import "testViewController.h"
#import "AFNetworking.h"
#import "NewTableViewCell.h"
#import "MJExtension.h"
#import "NewData.h"
#import "TopData.h"
#import "NewDataFrame.h"
#import "MJRefresh.h"
#import "SDCycleScrollView.h"
#import "TopViewController.h"
#import "MBProgressHUD+MJ.h"
#import "TabbarView.h"

@interface SocietyViewController ()<UITableViewDelegate,UITableViewDataSource,SDCycleScrollViewDelegate,TabbarViewDelegate>
@property (nonatomic , strong) NSMutableArray *totalArray;
@property (nonatomic , strong) SDCycleScrollView *cycleScrollView;
@property (nonatomic , strong) NSMutableArray *topArray;
@property (nonatomic , strong) NSMutableArray *titleArray;
@property (nonatomic , strong) NSMutableArray *imagesArray;

@property (nonatomic , strong) UITableView *tableview;
@property (nonatomic , assign) int page;

@end

@implementation SocietyViewController

-(NSMutableArray *)totalArray
{
    if (!_totalArray) {
        _totalArray = [NSMutableArray array];
    }
    return _totalArray;
}
-(NSMutableArray *)imagesArray
{
    if (!_imagesArray) {
        _imagesArray = [NSMutableArray array];
    }
    return _imagesArray;
}
-(NSMutableArray *)titleArray
{
    if (!_titleArray) {
        _titleArray = [NSMutableArray array];
    }
    return _titleArray;
}
-(NSMutableArray *)topArray
{
    if (!_topArray) {
        _topArray = [NSMutableArray array];
    }
    return _topArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self initTableView];
    //请求滚动数据
    [self initTopNet];
    
    [self setupRefreshView];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(mynotification) name:@"新闻" object:nil];
}

-(void)mynotification
{
    [self.tableview.header beginRefreshing];
}

-(void)initTableView
{
    UITableView *tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64-49)];
    tableview.delegate = self;
    tableview.dataSource = self;
    [self.view addSubview:tableview];
    self.tableview = tableview;
    
}

-(void)initTopNet
{
    //网易顶部滚动
    //   http://c.m.163.com/nc/article/headline/T1348647853363/0-1.html
    
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    [mgr GET:@"http://c.m.163.com/nc/article/headline/T1348647853363/0-1.html" parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {

        NSArray *dataarray = [TopData objectArrayWithKeyValuesArray:responseObject[@"T1348647853363"][0][@"ads"]];
        // 创建frame模型对象
        NSMutableArray *statusFrameArray = [NSMutableArray array];
        NSMutableArray *titleArray = [NSMutableArray array];
        NSMutableArray *topArray = [NSMutableArray array];
        for (TopData *data in dataarray) {
            [topArray addObject:data];
            [statusFrameArray addObject:data.imgsrc];
            [titleArray addObject:data.title];
        }
        [self.topArray addObjectsFromArray:topArray];
        [self.imagesArray addObjectsFromArray:statusFrameArray];
        [self.titleArray addObjectsFromArray:titleArray];
        
        [self initScrollView];
        
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        
    }];
}

-(void)initScrollView
{
        // 网络加载 --- 创建不带标题的图片轮播器
        SDCycleScrollView *cycleScrollView = [SDCycleScrollView cycleScrollViewWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH * 0.55) imageURLStringsGroup:self.imagesArray];
        cycleScrollView.delegate = self;
        cycleScrollView.pageControlAliment = SDCycleScrollViewPageContolAlimentRight;
        cycleScrollView.titlesGroup = self.titleArray;
        cycleScrollView.pageControlStyle = SDCycleScrollViewPageContolStyleAnimated;
        cycleScrollView.autoScrollTimeInterval = 6.0;
        self.tableview.tableHeaderView = cycleScrollView;
}


//集成刷新控件
-(void)setupRefreshView
{
    //1.下拉刷新
    self.tableview.header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    [self.tableview.header beginRefreshing];
    //2.上拉刷新
    self.tableview.footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];

}
#pragma mark  下拉
-(void)loadNewData
{
    self.page = 1;
    [self requestNet];
}

#pragma mark  上拉
-(void)loadMoreData
{
    [self requestNet];
    [self.tableview.footer endRefreshing];
}

#pragma mark 网络请求
-(void)requestNet
{
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    dic[@"page"] = [NSString stringWithFormat:@"%d",self.page];
    [mgr GET:@"http://api.huceo.com/social/other/?key=c32da470996b3fdd742fabe9a2948adb&num=20" parameters:dic success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
        NSArray *dataarray = [NewData objectArrayWithKeyValuesArray:responseObject[@"newslist"]];
        // 创建frame模型对象
        NSMutableArray *statusFrameArray = [NSMutableArray array];
        for (NewData *data in dataarray) {
            NewDataFrame *dataFrame = [[NewDataFrame alloc] init];
            // 传递微博模型数据
            dataFrame.NewData = data;
            [statusFrameArray addObject:dataFrame];
        }
        [self.totalArray addObjectsFromArray:statusFrameArray];
        self.page++;
        // 刷新表格
        [self.tableview reloadData];
        
        [self.tableview.header endRefreshing];
        
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        
    }];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.totalArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewTableViewCell *cell = [NewTableViewCell cellWithTableView:tableView];
    
    cell.dataFrame = self.totalArray[indexPath.row];
    
    return cell;
    

}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewDataFrame *dataframe = self.totalArray[indexPath.row];
    
    return dataframe.cellH;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewDataFrame *dataframe = self.totalArray[indexPath.row];
    NewData *data = dataframe.NewData;
    NSLog(@"%@",data.url);
    testViewController *detail = [[testViewController alloc]init];
    detail.url = data.url;
    [self.navigationController pushViewController:detail animated:YES];

}


#pragma mark 图片轮播 delegate
-(void)cycleScrollView:(SDCycleScrollView *)cycleScrollView didSelectItemAtIndex:(NSInteger)index
{
    //  http://c.3g.163.com/photo/api/set/0096/77789.json
    TopData *data = self.topArray[index];
    NSString *url = [data.url substringFromIndex:9];
    url = [NSString stringWithFormat:@"http://c.3g.163.com/photo/api/set/0096/%@.json",url];

    TopViewController *topVC = [[TopViewController alloc]init];
    topVC.url = url;
    [self.navigationController pushViewController:topVC animated:YES];
    
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"新闻" object:nil];
}























@end
