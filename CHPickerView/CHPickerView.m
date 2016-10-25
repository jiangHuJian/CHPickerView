//
//  CHDatePickerView.m
//  CHPickerView
//
//  Created by chw on 16/9/21.
//  Copyright © 2016年 chw. All rights reserved.
//

#import "CHPickerView.h"

/** 控件的高度  */
static CGFloat const viewHeight = 300;
/** 顶端的高度  */
static CGFloat const topHeight = 70;
/** 行高  */
static CGFloat const cellHeight = 50;
/** 取消/确定按钮的高度  */
static CGFloat const btnHeight = 50;
/** 日期和顶端/底端的间距  */
static CGFloat const gap = 15;
/** 线的间距(CHPickerModeDate模式)  */
static CGFloat const lineSpacing = 15;


/** 默认起始年分  */
#define CHStartYear 2010
/** 默认结束年分  */
#define CHEndYear @"2120"
#define CHLineColor [UIColor colorWithRed:60/255.0 green:170/255.0 blue:250/255.0 alpha:1.0]
/** 控件宽度  */
#define WIDTH self.frame.size.width
/** 控件高度  */
#define HEIGHT self.frame.size.height

#define widths  [UIScreen mainScreen].bounds.size.width
#define heights [UIScreen mainScreen].bounds.size.height

@interface CHPickerView ()<UITableViewDelegate, UITableViewDataSource>
{
    // 日期
    UITableView *_yearsTableView;
    UITableView *_monthsTableView;
    UITableView *_daysTableView;
    // 时间
    UITableView *_hoursTableView;
    UITableView *_minutesTableView;
    UITableView *_secondsTableView;
    // 普通
    UITableView *_normalTableView;

    // 日期数组
    NSMutableArray *_yearsArray;
    NSMutableArray *_monthsArray;
    NSMutableArray *_daysArray;
    NSMutableArray *_hoursArray;
    NSMutableArray *_minutesArray;
    NSMutableArray *_secondsArray;

    // 线
    UIView *_lineYearsTop;
    UIView *_lineYearsBottom;
    UIView *_lineMonthsTop;
    UIView *_lineMonthsBottom;
    UIView *_lineDaysTop;
    UIView *_lineDaysBottom;
    
    UIView *_lineHoursTop;
    UIView *_lineHoursBottom;
    UIView *_lineMinutesTop;
    UIView *_lineMinutesBottom;
    UIView *_lineSecondsTop;
    UIView *_lineSecondsBottom;
    
    // 选择的日期
    NSInteger _selectedDay;
    NSInteger _selectedMonth;
    NSInteger _selectedYear;
    NSString *_selectedData;// 普通选择
    NSString *_selectedWeek;// 周几
    
    NSInteger _selectedHour;
    NSInteger _selectedMinutes;
    NSInteger _selectedSecond;
    
    // 只对CHPickerModeNormal 有效
    CGFloat _dataSpacing;
}
/** 时区 */
@property(nonatomic,retain) NSTimeZone *timeZone;
@property(nonatomic,retain) NSLocale *locale;

/** view */
@property (strong, nonatomic) UIView *wholeView;
/** 蒙版 */
@property (strong, nonatomic) UIView *coverView;
/** 所选的日期展示 */
@property (strong, nonatomic) UILabel *dateLab;
/** 日历 */
@property (strong, nonatomic) NSCalendar *dateCalendar;
/** 选择第几行 */
@property (assign, nonatomic) NSInteger row;
/** 数据数组 */
@property (strong, nonatomic) NSMutableArray *infoArray;
@end

@implementation CHPickerView

+ (CHPickerView *)pickerView
{
    return [[CHPickerView alloc] initWithFrame:CGRectMake(30, 0, widths-60, viewHeight)];
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)show
{
    _dataSpacing = _lineLength == 0 ? 130 : _lineLength;
    [self createView];
    
    // 蒙版覆盖在主窗口上
    _coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, widths, heights)];
    _coverView.backgroundColor = [UIColor blackColor];
    _coverView.alpha = 0.3;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
    [_coverView addGestureRecognizer:tap];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addSubview:_coverView];
    
    self.center = keyWindow.center;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    [keyWindow addSubview:self];
    
    // 转换为可变数组
    self.infoArray = [NSMutableArray arrayWithArray:self.dataArray];
    if (_pickerMode == CHPickerModeNormal) {
        // 给self.infoArray数组前后插入@""
        if (![self.infoArray containsObject:@""]) {
            [self.infoArray insertObject:@"" atIndex:0];
            [self.infoArray addObject:@""];
        }
        // 创建普通的选择器
        [self createNormalTableView];
    } else if (_pickerMode == CHPickerModeDate) {
        // Default parameters :
        self.locale = [NSLocale currentLocale];
        self.timeZone = nil;
        
        // 创建日期
        [self createYearsTableView];
        [self createMonthsTableView];
        [self createDaysTableView];
    } else if (_pickerMode == CHPickerModeTime) {
        // Default parameters :
        self.locale = [NSLocale currentLocale];
        self.timeZone = nil;
        
        // 创建日期
        [self createHoursTableView];
        [self createMinutesTableView];
        [self createSecondsTableView];
    }
    
}

- (void)tap
{
    [self moveView];
}


- (void)moveView
{
    [_coverView removeFromSuperview];
    [self removeFromSuperview];
}


- (void)createView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
    view.backgroundColor = [UIColor whiteColor];
    [self addSubview:view];
    _wholeView = view;
    
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, WIDTH, topHeight-2)];
    dateLabel.textAlignment = NSTextAlignmentCenter;
    dateLabel.font = [UIFont boldSystemFontOfSize:20];
    if (_lineColor) {
        dateLabel.textColor = _lineColor;
    } else {
        dateLabel.textColor = CHLineColor;
    }
    [_wholeView addSubview:dateLabel];
    _dateLab = dateLabel;

    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, topHeight-2, WIDTH, 2)];
    if (_lineColor) {
        lineView.backgroundColor = _lineColor;
    } else {
        lineView.backgroundColor = CHLineColor;
    }
    [_wholeView addSubview:lineView];
    
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 3*cellHeight+topHeight+2*gap+1, WIDTH, 1)];
    bottomView.backgroundColor = [UIColor lightGrayColor];
    [_wholeView addSubview:bottomView];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 3*cellHeight+topHeight+2*gap+2, WIDTH/2, btnHeight);
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    cancelBtn.backgroundColor = [UIColor whiteColor];
    [cancelBtn addTarget:self action:@selector(moveView) forControlEvents:UIControlEventTouchUpInside];
    [_wholeView addSubview:cancelBtn];
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.frame = CGRectMake(WIDTH/2+1, 3*cellHeight+topHeight+2*gap+2, WIDTH/2, btnHeight);
    [confirmBtn setTitle:@"确定" forState:UIControlStateNormal];
    if (_lineColor) {
        [confirmBtn setTitleColor:_lineColor forState:UIControlStateNormal];
    } else {
        [confirmBtn setTitleColor:CHLineColor forState:UIControlStateNormal];
    }
    confirmBtn.backgroundColor = [UIColor whiteColor];
    [confirmBtn addTarget:self action:@selector(confirmBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_wholeView addSubview:confirmBtn];
    
    UIView *verticalLineView = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/2, topHeight+3*cellHeight+2*gap+2, 1, btnHeight)];
    verticalLineView.backgroundColor = [UIColor lightGrayColor];
    [_wholeView addSubview:verticalLineView];
   
}

#pragma mark - 创建普通选择器
- (void)createNormalTableView
{
    _normalTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight+gap, WIDTH, 3*cellHeight)];
    _normalTableView.delegate = self;
    _normalTableView.dataSource = self;
    _normalTableView.showsHorizontalScrollIndicator = NO;
    _normalTableView.showsVerticalScrollIndicator = NO;
    _normalTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_wholeView addSubview:_normalTableView];
    
    _lineYearsTop = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/2-_dataSpacing/2, cellHeight+topHeight+gap, _dataSpacing, 2)];
    
    if (_lineColor) {
        _lineYearsTop.backgroundColor = _lineColor;
    } else {
        _lineYearsTop.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineYearsTop];
    _lineYearsBottom = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/2-_dataSpacing/2, cellHeight * 2+topHeight+gap,_dataSpacing, 2)];
    if (_lineColor) {
        _lineYearsBottom.backgroundColor = _lineColor;
    } else {
        _lineYearsBottom.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineYearsBottom];
    
    // 默认展示选择的数据
    _selectedData = self.infoArray[1];
    _dateLab.text = _selectedData;
    
}

#pragma mark - 创建日期三大滑动条
- (void)createYearsTableView
{
    _yearsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight+gap, WIDTH/3, 3*cellHeight)];
    _yearsTableView.delegate = self;
    _yearsTableView.dataSource = self;
    _yearsTableView.showsHorizontalScrollIndicator = NO;
    _yearsTableView.showsVerticalScrollIndicator = NO;
    _yearsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_wholeView addSubview:_yearsTableView];
    
    _lineYearsTop = [[UIView alloc] initWithFrame:CGRectMake(lineSpacing, cellHeight+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineYearsTop.backgroundColor = _lineColor;
    } else {
        _lineYearsTop.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineYearsTop];
    _lineYearsBottom = [[UIView alloc] initWithFrame:CGRectMake(lineSpacing, cellHeight * 2+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineYearsBottom.backgroundColor = _lineColor;
    } else {
        _lineYearsBottom.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineYearsBottom];

    _yearsArray = [self getYears];
    // 默认展示的年份
    NSDate *date = [NSDate date];
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    dateF.dateFormat = @"yyyy";
    NSString *dateStr = [dateF stringFromDate:date];
    for (NSInteger i = 0; i < _yearsArray.count; i++) {
        if ([_yearsArray[i] containsString:dateStr]) {
            [_yearsTableView setContentOffset:CGPointMake(0, (i-1) * cellHeight) animated:NO];
            _selectedYear = [dateStr integerValue];
            break;
        }
    }
}

- (void)createMonthsTableView
{
    _monthsTableView = [[UITableView alloc] initWithFrame:CGRectMake(WIDTH/3, topHeight+gap, WIDTH/3, 3*cellHeight)];
    _monthsTableView.delegate = self;
    _monthsTableView.dataSource = self;
    _monthsTableView.showsHorizontalScrollIndicator = NO;
    _monthsTableView.showsVerticalScrollIndicator = NO;
    _monthsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_wholeView addSubview:_monthsTableView];
    
    _lineMonthsTop = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3+lineSpacing, cellHeight+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineMonthsTop.backgroundColor = _lineColor;
    } else {
        _lineMonthsTop.backgroundColor = CHLineColor;
    }    [self addSubview:_lineMonthsTop];
    _lineMonthsBottom = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3+lineSpacing, cellHeight * 2+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineMonthsBottom.backgroundColor = _lineColor;
    } else {
        _lineMonthsBottom.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineMonthsBottom];
    
    _monthsArray = [self getMonths];
    // 默认展示的月份
    NSDate *date = [NSDate date];
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"M"];
    NSString *dateStr = [dateF stringFromDate:date];
    for (NSInteger i = 0; i < _monthsArray.count; i++) {
        if ([_monthsArray[i] containsString:dateStr]) {
            [_monthsTableView setContentOffset:CGPointMake(0, (i-1) * cellHeight) animated:NO];
            _selectedMonth = [dateStr integerValue];

            break;
        }
    }
    
}

- (void)createDaysTableView
{
    _daysTableView = [[UITableView alloc] initWithFrame:CGRectMake(WIDTH/3*2, topHeight+gap, WIDTH/3, 3*cellHeight)];
    _daysTableView.delegate = self;
    _daysTableView.dataSource = self;
    _daysTableView.showsHorizontalScrollIndicator = NO;
    _daysTableView.showsVerticalScrollIndicator = NO;
    _daysTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_wholeView addSubview:_daysTableView];

    _lineDaysTop = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3*2+lineSpacing, cellHeight+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineDaysTop.backgroundColor = _lineColor;
    } else {
        _lineDaysTop.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineDaysTop];
    _lineDaysBottom = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3*2+lineSpacing, cellHeight * 2+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineDaysBottom.backgroundColor = _lineColor;
    } else {
        _lineDaysBottom.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineDaysBottom];
    
    _daysArray = [self getDaysInMonth:[NSDate date]];
    // 默认展示的日数
    NSDate *date = [NSDate date];
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"d"];
    NSString *dateStr = [dateF stringFromDate:date];
    for (NSInteger i = 0; i < _daysArray.count; i++) {
        if ([_daysArray[i] containsString:dateStr]) {
            [_daysTableView setContentOffset:CGPointMake(0, (i-1) * cellHeight) animated:NO];
            _selectedDay = [dateStr integerValue];

            break;
        }
    }
    
    // 展示日期
    _dateLab.text = [self showSelectedDate];
}

#pragma mark - 创建时间三大滑动条
- (void)createHoursTableView
{
    _hoursTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight+gap, WIDTH/3, 3*cellHeight)];
    _hoursTableView.delegate = self;
    _hoursTableView.dataSource = self;
    _hoursTableView.showsHorizontalScrollIndicator = NO;
    _hoursTableView.showsVerticalScrollIndicator = NO;
    _hoursTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_wholeView addSubview:_hoursTableView];
    
    _lineHoursTop = [[UIView alloc] initWithFrame:CGRectMake(lineSpacing, cellHeight+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineHoursTop.backgroundColor = _lineColor;
    } else {
        _lineHoursTop.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineHoursTop];
    _lineHoursBottom = [[UIView alloc] initWithFrame:CGRectMake(lineSpacing, cellHeight * 2+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineHoursBottom.backgroundColor = _lineColor;
    } else {
        _lineHoursBottom.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineHoursBottom];
    
    _hoursArray = [self getHours];
    // 默认展示的时间
    NSDate *date = [NSDate date];
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    dateF.dateFormat = @"H";
    NSString *dateStr = [dateF stringFromDate:date];
    for (NSInteger i = 0; i < _hoursArray.count; i++) {
        if ([_hoursArray[i] containsString:dateStr]) {
            [_hoursTableView setContentOffset:CGPointMake(0, (i-1) * cellHeight) animated:NO];
            _selectedHour = [dateStr integerValue];
            break;
        }
    }
    
    
}

- (void)createMinutesTableView
{
    _minutesTableView = [[UITableView alloc] initWithFrame:CGRectMake(WIDTH/3, topHeight+gap, WIDTH/3, 3*cellHeight)];
    _minutesTableView.delegate = self;
    _minutesTableView.dataSource = self;
    _minutesTableView.showsHorizontalScrollIndicator = NO;
    _minutesTableView.showsVerticalScrollIndicator = NO;
    _minutesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_wholeView addSubview:_minutesTableView];
    
    _lineMinutesTop = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3+lineSpacing, cellHeight+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineMinutesTop.backgroundColor = _lineColor;
    } else {
        _lineMinutesTop.backgroundColor = CHLineColor;
    }    [self addSubview:_lineMinutesTop];
    _lineMinutesBottom = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3+lineSpacing, cellHeight * 2+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineMinutesBottom.backgroundColor = _lineColor;
    } else {
        _lineMinutesBottom.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineMinutesBottom];
    
    _minutesArray = [self getMinutes];
    // 默认展示的月份
    NSDate *date = [NSDate date];
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"m"];
    NSString *dateStr = [dateF stringFromDate:date];
    for (NSInteger i = 0; i < _minutesArray.count; i++) {
        if ([_minutesArray[i] containsString:dateStr]) {
            [_minutesTableView setContentOffset:CGPointMake(0, (i-1) * cellHeight) animated:NO];
            _selectedMinutes = [dateStr integerValue];
            
            break;
        }
    }
    
}

- (void)createSecondsTableView
{
    _secondsTableView = [[UITableView alloc] initWithFrame:CGRectMake(WIDTH/3*2, topHeight+gap, WIDTH/3, 3*cellHeight)];
    _secondsTableView.delegate = self;
    _secondsTableView.dataSource = self;
    _secondsTableView.showsHorizontalScrollIndicator = NO;
    _secondsTableView.showsVerticalScrollIndicator = NO;
    _secondsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_wholeView addSubview:_secondsTableView];
    
    _lineSecondsTop = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3*2+lineSpacing, cellHeight+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineSecondsTop.backgroundColor = _lineColor;
    } else {
        _lineSecondsTop.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineSecondsTop];
    _lineSecondsBottom = [[UIView alloc] initWithFrame:CGRectMake(WIDTH/3*2+lineSpacing, cellHeight * 2+topHeight+gap, WIDTH/3-2*lineSpacing, 2)];
    if (_lineColor) {
        _lineSecondsBottom.backgroundColor = _lineColor;
    } else {
        _lineSecondsBottom.backgroundColor = CHLineColor;
    }
    [self addSubview:_lineSecondsBottom];
    
    _secondsArray = [self getSeconds];
    // 默认展示的日数
    NSDate *date = [NSDate date];
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"s"];
    NSString *dateStr = [dateF stringFromDate:date];
    for (NSInteger i = 0; i < _secondsArray.count; i++) {
        if ([_secondsArray[i] containsString:dateStr]) {
            [_secondsTableView setContentOffset:CGPointMake(0, (i-1) * cellHeight) animated:NO];
            _selectedSecond = [dateStr integerValue];
            
            break;
        }
    }
    
    // 展示时间
    _dateLab.text = [self showSelectedTime];
}




#pragma mark - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _yearsTableView) {
        return _yearsArray.count;
    } else if (tableView == _monthsTableView) {
        return _monthsArray.count;
    } else if (tableView == _daysTableView) {
        return _daysArray.count;
    } else if (tableView == _hoursTableView) {
        return _hoursArray.count;
    } else if (tableView == _minutesTableView) {
        return _minutesArray.count;
    } else if (tableView == _secondsTableView) {
        return _secondsArray.count;
    } else {
        return self.infoArray.count;
    }
        
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _yearsTableView) {
        static NSString *cellIndentifier = @"yearsCell";
        UITableViewCell *yearCell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        if (!yearCell) {
            yearCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        }
        yearCell.textLabel.text = _yearsArray[indexPath.row];
        yearCell.textLabel.textColor = [UIColor grayColor];
        yearCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [yearCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        // 默认当前年份字体加黑
        if ([yearCell.textLabel.text containsString:[NSString stringWithFormat:@"%zd", _selectedYear]] ) {
            yearCell.textLabel.textColor = [UIColor blackColor];
        }
        return yearCell;
        
    } else if (tableView == _monthsTableView) {
        static NSString *cellIndentifier = @"monthsCell";
        UITableViewCell *monthCell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        if (!monthCell) {
            monthCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        }
        monthCell.textLabel.text = _monthsArray[indexPath.row];
        monthCell.textLabel.textColor = [UIColor grayColor];
        monthCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [monthCell setSelectionStyle:UITableViewCellSelectionStyleNone];

        // 默认当前月份字体加黑
        if ([monthCell.textLabel.text containsString:[NSString stringWithFormat:@"%zd", _selectedMonth]] ) {
            monthCell.textLabel.textColor = [UIColor blackColor];
        }
        return monthCell;
        
    } else  if (tableView == _daysTableView) {
        static NSString *cellIndentifier = @"daysCell";
        UITableViewCell *dayCell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        if (!dayCell) {
            dayCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        }
        dayCell.textLabel.text = _daysArray[indexPath.row];
        dayCell.textLabel.textColor = [UIColor grayColor];
        dayCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [dayCell setSelectionStyle:UITableViewCellSelectionStyleNone];

        // 默认当前天数字体加黑
        if ([dayCell.textLabel.text containsString:[NSString stringWithFormat:@"%zd", _selectedDay]] ) {
            dayCell.textLabel.textColor = [UIColor blackColor];
        }
        return dayCell;
        
    } else if (tableView == _hoursTableView) {
        static NSString *cellIndentifier = @"hoursCell";
        UITableViewCell *hourCell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        if (!hourCell) {
            hourCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        }
        hourCell.textLabel.text = _hoursArray[indexPath.row];
        hourCell.textLabel.textColor = [UIColor grayColor];
        hourCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [hourCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        // 默认当前年份字体加黑
        if ([hourCell.textLabel.text containsString:[NSString stringWithFormat:@"%zd", _selectedHour]] ) {
            hourCell.textLabel.textColor = [UIColor blackColor];
        }
        return hourCell;
        
    } else if (tableView == _minutesTableView) {
        static NSString *cellIndentifier = @"minutesCell";
        UITableViewCell *minutesCell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        if (!minutesCell) {
            minutesCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        }
        minutesCell.textLabel.text = _minutesArray[indexPath.row];
        minutesCell.textLabel.textColor = [UIColor grayColor];
        minutesCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [minutesCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        if ([minutesCell.textLabel.text containsString:[NSString stringWithFormat:@"%zd", _selectedMinutes]] ) {
            minutesCell.textLabel.textColor = [UIColor blackColor];
        }
        return minutesCell;
        
    } else if (tableView == _secondsTableView) {
        static NSString *cellIndentifier = @"secondsCell";
        UITableViewCell *secondCell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        if (!secondCell) {
            secondCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        }
        secondCell.textLabel.text = _secondsArray[indexPath.row];
        secondCell.textLabel.textColor = [UIColor grayColor];
        secondCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [secondCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        if ([secondCell.textLabel.text containsString:[NSString stringWithFormat:@"%zd", _selectedSecond]] ) {
            secondCell.textLabel.textColor = [UIColor blackColor];
        }
        return secondCell;
        
    } else {
        static NSString *cellIndentifier = @"datasCell";
        UITableViewCell *dataCell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        if (!dataCell) {
            dataCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        }
        dataCell.textLabel.text = self.infoArray[indexPath.row];
        dataCell.textLabel.textColor = [UIColor grayColor];
        dataCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [dataCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        // 默认第一个数据加黑
        if ([dataCell.textLabel.text containsString:_selectedData] ) {
            dataCell.textLabel.textColor = [UIColor blackColor];
        }
        
        return dataCell;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   return cellHeight;
}


#pragma mark - 滚动日期所做的处理
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{

    if (decelerate) return;
    CGFloat offset = scrollView.contentOffset.y;
    CGFloat indexF = offset / cellHeight;
    NSInteger indexI = offset / cellHeight;
    CGFloat remaining = fabs((indexF - indexI));
    
    NSInteger contentOffset;
    if (remaining > 0.5) {
        contentOffset =  (indexI + 1) * cellHeight;
    } else {
        contentOffset =  indexI * cellHeight;
    }
    if (scrollView == _yearsTableView) {
        [_yearsTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedYear = [_yearsArray[row+1] integerValue];
        
        // 获取当月对应的天数,,
        [self getDaysOfYearMonth];

        
    } else if (scrollView == _monthsTableView) {
        [_monthsTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedMonth = [_monthsArray[row+1] integerValue];
        
        // 获取当月对应的天数,,
        [self getDaysOfYearMonth];


    } else if (scrollView == _daysTableView) {
        [_daysTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedDay = [_daysArray[row+1] integerValue];
        
    } else if (scrollView == _normalTableView) {
        [_normalTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedData = self.infoArray[row+1];
        self.row = row+1;
    } else if (scrollView == _hoursTableView) {
        [_hoursTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedHour = [_hoursArray[row+1] integerValue];
        
    } else if (scrollView == _minutesTableView) {
        [_minutesTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedMinutes = [_minutesArray[row+1] integerValue];
        
    } else if (scrollView == _secondsTableView) {
        [_secondsTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedSecond = [_secondsArray[row+1] integerValue];
    }

    
    if (_pickerMode == CHPickerModeNormal) {
        // 展示选择的数据
        _dateLab.text = _selectedData;
    } else if (_pickerMode == CHPickerModeDate) {
        // 展示日期
        _dateLab.text = [self showSelectedDate];
    } else if (_pickerMode == CHPickerModeTime) {
        // 展示时间
        _dateLab.text = [self showSelectedTime];
    }
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y;
    CGFloat indexF = offset / cellHeight;
    NSInteger indexI = offset / cellHeight;
    CGFloat remaining = fabs((indexF - indexI));
    
    NSInteger contentOffset;
    if (remaining > 0.5) {
        contentOffset =  (indexI + 1) * cellHeight;
    } else {
        contentOffset =  indexI * cellHeight;
    }
    if (scrollView == _yearsTableView) {
        [_yearsTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedYear = [_yearsArray[row+1] integerValue];
        // 获取当月对应的天数
        [self getDaysOfYearMonth];

    } else if (scrollView == _monthsTableView) {
        [_monthsTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedMonth = [_monthsArray[row+1] integerValue];
        
        // 获取当月对应的天数
        [self getDaysOfYearMonth];

    } else if (scrollView == _daysTableView) {
        [_daysTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedDay = [_daysArray[row+1] integerValue];
    } else if (scrollView == _normalTableView) {
        [_normalTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedData = self.infoArray[row+1];
        self.row = row+1;

    } else if (scrollView == _hoursTableView) {
        [_hoursTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedHour = [_hoursArray[row+1] integerValue];
        
        
    } else if (scrollView == _minutesTableView) {
        [_minutesTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedMinutes = [_minutesArray[row+1] integerValue];
        
    } else if (scrollView == _secondsTableView) {
        [_secondsTableView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
        NSInteger row = contentOffset / cellHeight;
        _selectedSecond = [_secondsArray[row+1] integerValue];
    }
    

    if (_pickerMode == CHPickerModeNormal) {
        // 展示选择的数据
        _dateLab.text = _selectedData;
    } else if (_pickerMode == CHPickerModeDate) {
        // 展示日期
        _dateLab.text = [self showSelectedDate];
    } else if (_pickerMode == CHPickerModeTime) {
        // 展示时间
        _dateLab.text = [self showSelectedTime];
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y;
    CGFloat indexF = offset / cellHeight;
    NSInteger indexI = offset / cellHeight;
    CGFloat remaining = fabs((indexF - indexI));
    
    if (remaining > 0.5) {
        indexI = indexI + 1;
    }
    // 设置字体颜色
    if (scrollView == _yearsTableView) {
        NSArray *yearsCellsArray = _yearsTableView.visibleCells;
        for (int i = 0; i < yearsCellsArray.count; i++) {
            UITableViewCell *yearCell = yearsCellsArray[i];
            yearCell.textLabel.textColor = [UIColor grayColor];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexI+1 inSection:0];
        UITableViewCell *yearCell = [_yearsTableView cellForRowAtIndexPath:indexPath];
        yearCell.textLabel.textColor = [UIColor blackColor];
        
    } else if (scrollView == _monthsTableView) {
        NSArray *monthsCellsArray = _monthsTableView.visibleCells;
        for (int i = 0; i < monthsCellsArray.count; i++) {
            UITableViewCell *monthCell = monthsCellsArray[i];
            monthCell.textLabel.textColor = [UIColor grayColor];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexI+1 inSection:0];
        UITableViewCell *monthCell = [_monthsTableView cellForRowAtIndexPath:indexPath];
        monthCell.textLabel.textColor = [UIColor blackColor];
        
    } else if (scrollView == _daysTableView) {
        NSArray *daysCellsArray = _daysTableView.visibleCells;
        for (int i = 0; i < daysCellsArray.count; i++) {
            UITableViewCell *dayCell = daysCellsArray[i];
            dayCell.textLabel.textColor = [UIColor grayColor];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexI+1 inSection:0];
        UITableViewCell *dayCell = [_daysTableView cellForRowAtIndexPath:indexPath];
        dayCell.textLabel.textColor = [UIColor blackColor];
    } else if (scrollView == _normalTableView) {
        NSArray *datasCellsArray = _normalTableView.visibleCells;
        for (int i = 0; i < datasCellsArray.count; i++) {
            UITableViewCell *dataCell = datasCellsArray[i];
            dataCell.textLabel.textColor = [UIColor grayColor];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexI+1 inSection:0];
        UITableViewCell *dataCell = [_normalTableView cellForRowAtIndexPath:indexPath];
        dataCell.textLabel.textColor = [UIColor blackColor];
    } else if (scrollView == _hoursTableView) {
        NSArray *hoursCellsArray = _hoursTableView.visibleCells;
        for (int i = 0; i < hoursCellsArray.count; i++) {
            UITableViewCell *yearCell = hoursCellsArray[i];
            yearCell.textLabel.textColor = [UIColor grayColor];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexI+1 inSection:0];
        UITableViewCell *yearCell = [_hoursTableView cellForRowAtIndexPath:indexPath];
        yearCell.textLabel.textColor = [UIColor blackColor];
        
    } else if (scrollView == _minutesTableView) {
        NSArray *minutesCellsArray = _minutesTableView.visibleCells;
        for (int i = 0; i < minutesCellsArray.count; i++) {
            UITableViewCell *monthCell = minutesCellsArray[i];
            monthCell.textLabel.textColor = [UIColor grayColor];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexI+1 inSection:0];
        UITableViewCell *monthCell = [_minutesTableView cellForRowAtIndexPath:indexPath];
        monthCell.textLabel.textColor = [UIColor blackColor];
        
    } else if (scrollView == _secondsTableView) {
        NSArray *secondsCellsArray = _secondsTableView.visibleCells;
        for (int i = 0; i < secondsCellsArray.count; i++) {
            UITableViewCell *dayCell = secondsCellsArray[i];
            dayCell.textLabel.textColor = [UIColor grayColor];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexI+1 inSection:0];
        UITableViewCell *dayCell = [_secondsTableView cellForRowAtIndexPath:indexPath];
        dayCell.textLabel.textColor = [UIColor blackColor];
    }


}

#pragma mark  获取年月所对应的天数
- (void)getDaysOfYearMonth
{
    // 获取当月对应的天数
    NSDate *seletedDate = [self convertToDateDay:_selectedDay month:_selectedMonth year:_selectedYear hours:0 minutes:0 seconds:0];
    [_daysArray removeAllObjects];
    _daysArray = [self getDaysInMonth:seletedDate];
    [_daysTableView reloadData];
}

#pragma mark 选择的日期展示
- (NSString *)showSelectedDate
{
    // 选择的日期
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    dateF.dateFormat = @"yyyyMMdd";
    NSString *month;
    NSString *day;
    if (_selectedMonth < 10) {
        month = [NSString stringWithFormat:@"0%zd", _selectedMonth];
    } else {
        month = [NSString stringWithFormat:@"%zd", _selectedMonth];
    }
    if (_selectedDay < 10) {
        day = [NSString stringWithFormat:@"0%zd", _selectedDay];
    } else {
        day = [NSString stringWithFormat:@"%zd", _selectedDay];
    }
    NSString *dateStr = [NSString stringWithFormat:@"%zd%@%@", _selectedYear, month, day];
    NSDate *seletedDate = [dateF dateFromString:dateStr];
    
    // 获取周几
    _dateCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday;
    _dateCalendar.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    comps = [_dateCalendar components:unitFlags fromDate:seletedDate];
    NSInteger week = [comps weekday];
    
    // 转换为中文
    NSString *changeWeek = [self changeWeek:week];
    
    NSString *selectedDate = [NSString stringWithFormat:@"%zd年%zd月%zd日 周%@", _selectedYear, _selectedMonth, _selectedDay, changeWeek];
    // 记录周几
    _selectedWeek = changeWeek;
    
    return selectedDate;
}

// 转换为中文
- (NSString *)changeWeek:(NSInteger)week
{
    if (1 == week) {
        return @"日";
    } else if (2 == week){
        return @"一";
    } else if (3 == week){
        return @"二";
    } else if (4 == week){
        return @"三";
    } else if (5 == week){
        return @"四";
    } else if (6 == week){
        return @"五";
    } else if (7 == week){
        return @"六";
    }
    return @"";
}

#pragma mark 选择的时间展示
- (NSString *)showSelectedTime
{
    // 选择的时间
    NSString *minute;
    NSString *second;
    if (_selectedMinutes < 10) {
        minute = [NSString stringWithFormat:@"0%zd", _selectedMinutes];
    } else {
        minute = [NSString stringWithFormat:@"%zd", _selectedMinutes];
    }
    if (_selectedSecond < 10) {
        second = [NSString stringWithFormat:@"0%zd", _selectedSecond];
    } else {
        second = [NSString stringWithFormat:@"%zd", _selectedSecond];
    }
    
    NSString *selectedDate = [NSString stringWithFormat:@"%zd:%@:%@", _selectedHour, minute, second];
    
    return selectedDate;
}


#pragma mark - 获取数据
// 获取年份数据
- (NSMutableArray *)getYears {
    
    NSMutableArray *years = [[NSMutableArray alloc] init];
    // 公历历法
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

   // NSString --> NSDate
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    dateF.dateFormat = @"yyyy";
    NSDate *minDate = [dateF dateFromString:self.minimumDate];
    NSDate *maxDate = [dateF dateFromString:self.maximumDate];

    
    NSInteger yearMin = 0;
    if (self.minimumDate != nil) {
        NSDateComponents *componentsMin = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:minDate];
        yearMin = componentsMin.year;
    } else {
        yearMin = CHStartYear;
    }
    
    NSInteger yearMax = 0;
    NSDateComponents *componentsMax = nil;
    
    if (self.maximumDate != nil) {
        componentsMax = [calendar components:NSCalendarUnitDay|NSCalendarUnitDay|NSCalendarUnitYear fromDate:maxDate];
        yearMax = [componentsMax year];
    } else {
        self.maximumDate = CHEndYear;
        NSDate *maxDate = [dateF dateFromString:self.maximumDate];

        componentsMax = [calendar components:NSCalendarUnitDay|NSCalendarUnitDay|NSCalendarUnitYear fromDate:maxDate];
        yearMax = [componentsMax year];
    }
    
    for (NSInteger i = yearMin; i <= yearMax; i++) {
        
        [years addObject:[NSString stringWithFormat:@"%zd年", i]];
    }
    // 第一个/最后的元素为空
    [years insertObject:@"" atIndex:0];
    [years addObject:@""];
    return years;
}

/**
 *  获取月份数据
 */
- (NSMutableArray*)getMonths {
    
    NSMutableArray *months = [[NSMutableArray alloc] init];
    
    for (int monthNumber = 1; monthNumber <= 12; monthNumber++) {
        
        NSString *dateString = [NSString stringWithFormat:@"%d", monthNumber];
        
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        if (self.timeZone != nil) [dateFormatter setTimeZone:self.timeZone];
        [dateFormatter setLocale:self.locale];
        [dateFormatter setDateFormat:@"mm"];
        NSDate* myDate = [dateFormatter dateFromString:dateString];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        if (self.timeZone != nil) [dateFormatter setTimeZone:self.timeZone];
        [dateFormatter setLocale:self.locale];
        [formatter setDateFormat:@"m"];
        NSString *stringFromDate = [formatter stringFromDate:myDate];
        
        [months addObject:[NSString stringWithFormat:@"%@月", stringFromDate]];
    }
    // 第一个/最后的元素为空
    [months insertObject:@"" atIndex:0];
    [months addObject:@""];
    
    return months;
}

/**
 *  获取天数数据
 */
- (NSMutableArray*)getDaysInMonth:(NSDate*)date {
    
//    if (date == nil) date = [NSDate date];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSRange daysRange = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    
    NSMutableArray *days = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= daysRange.length; i++) {
        
        [days addObject:[NSString stringWithFormat:@"%d日", i]];
    }
    // 第一个/最后的元素为空
    [days insertObject:@"" atIndex:0];
    [days addObject:@""];
    return days;
}

/**
 *  选择的日期
 */
- (NSDate *)convertToDateDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year hours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds; {
    
    // 日数要处理, 防止溢出
    if (day > 27) day = 12;
    
    NSMutableString *dateString = [[NSMutableString alloc] init];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (self.timeZone != nil) [dateFormatter setTimeZone:self.timeZone];
    [dateFormatter setLocale:self.locale];
    
    if (day < 10) {
        [dateString appendFormat:@"0%zd-", day];
    } else {
        [dateString appendFormat:@"%zd-", day];
    }
    
    if (month < 10) {
        [dateString appendFormat:@"0%zd-", month];
    } else {
        [dateString appendFormat:@"%zd-", month];
    }
    
    [dateString appendFormat:@"%zd", year];
    
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

/**
 *  获取小时数据
 */
- (NSMutableArray *)getHours {
    
    NSMutableArray *hours = [NSMutableArray new];
    for (NSInteger i = 0; i < 24; i++) {
        [hours addObject:[NSString stringWithFormat:@"%zd时", i]];
    }
    // 第一个/最后的元素为空
    [hours insertObject:@"" atIndex:0];
    [hours addObject:@""];
    return hours;
}

/**
 *  获取分钟数据
 */
- (NSMutableArray*)getMinutes {
    
    NSMutableArray *minutes = [NSMutableArray new];
    for (NSInteger i = 0; i < 60; i++) {
        [minutes addObject:[NSString stringWithFormat:@"%zd分", i]];
    }
    // 第一个/最后的元素为空
    [minutes insertObject:@"" atIndex:0];
    [minutes addObject:@""];
    return minutes;
}

/**
 *  获取秒数据
 */
- (NSMutableArray*)getSeconds
{
    
    NSMutableArray *seconds = [NSMutableArray new];
    for (NSInteger i = 0; i < 60; i++) {
        [seconds addObject:[NSString stringWithFormat:@"%zd秒", i]];
    }
    // 第一个/最后的元素为空
    [seconds insertObject:@"" atIndex:0];
    [seconds addObject:@""];
    return seconds;
}


#pragma mark 确定选择
- (void)confirmBtnAction
{
    [self moveView];
    if (_pickerMode == CHPickerModeNormal) {
        if (_pickerViewNormalBlock) {
            if (self.row == 0) self.row = 1;
            _pickerViewNormalBlock(_selectedData, self.row);
        }
    } else if (_pickerMode == CHPickerModeDate) {
        if (_pickerViewDateBlock) {
            NSString *day;
            if (_selectedDay < 10) {
               day = [NSString stringWithFormat:@"0%zd", _selectedDay];
            } else {
               day = [NSString stringWithFormat:@"%zd", _selectedDay];
            }
            
            NSString *month;
            if (_selectedMonth < 10) {
                month = [NSString stringWithFormat:@"0%zd", _selectedMonth];
            } else {
                month = [NSString stringWithFormat:@"%zd", _selectedMonth];
            }
            
            NSString *year;
            if (_selectedYear < 10) {
                year = [NSString stringWithFormat:@"0%zd", _selectedYear];
            } else {
                year = [NSString stringWithFormat:@"%zd", _selectedYear];
            }
            
            _pickerViewDateBlock(day, month, year, _selectedWeek);
        }
    } else if (_pickerMode == CHPickerModeTime) {
        if (_pickerViewTimeBlock) {
            NSString *second;
            if (_selectedSecond < 10) {
                second = [NSString stringWithFormat:@"0%zd", _selectedSecond];
            } else {
                second = [NSString stringWithFormat:@"%zd", _selectedSecond];
            }
            
            NSString *minutes;
            if (_selectedMinutes < 10) {
                minutes = [NSString stringWithFormat:@"0%zd", _selectedMinutes];
            } else {
                minutes = [NSString stringWithFormat:@"%zd", _selectedMinutes];
            }
            
            NSString *hour;
            if (_selectedHour < 10) {
                hour = [NSString stringWithFormat:@"0%zd", _selectedHour];
            } else {
                hour = [NSString stringWithFormat:@"%zd", _selectedHour];
            }
            
            _pickerViewTimeBlock(second, minutes, hour);
        }

    }
}


#pragma mark - 限定控件高度
- (void)setFrame:(CGRect)frame
{
    CGRect myFrame = frame;
    myFrame.size.height = viewHeight;
}

- (void)setBounds:(CGRect)bounds
{
    CGRect myBounds = bounds;
    myBounds.size.height = viewHeight;
}





@end
