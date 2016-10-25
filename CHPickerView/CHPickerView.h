//
//  CHPickerView.h
//  CHPickerView
//
//  Created by chw 16/9/21.
//  Copyright © 2016年 chw. All rights reserved.
//

// 说明:
// 限定控件的高度为: topHeight+3*cellHeight+btnHeight+2*gap = 300 (可改这三个高度的源码)
// 属性的设置要在 - (void)show 方法之前设置;


#import <UIKit/UIKit.h>

typedef void(^CHPickerViewNormalBlock)(NSString *selectedData, NSInteger row);
typedef void(^CHPickerViewDateBlock)(NSString *selectedDay, NSString *selectedMonth, NSString *selectedYear, NSString *selectedWeek);
typedef void(^CHPickerViewTimeBlock)(NSString *selectedSecond, NSString *selectedMinutes, NSString *selectedHour);

// 选择器的样式
typedef NS_ENUM(NSInteger, CHPickerMode) {
    CHPickerModeNormal = 0,
    CHPickerModeDate = 1,
    CHPickerModeTime
};

@interface CHPickerView : UIView

// 公共属性
/** 线条的颜色 */
// 默认:[UIColor colorWithRed:60 green:170 blue:250 alpha:1.0]
@property (strong, nonatomic) UIColor *lineColor;
/** 样式 */
// 默认CHPickerModeNormal
@property (assign, nonatomic) CHPickerMode pickerMode;

// 以下属性只对CHPickerModeDate 有效
/** 起始日期  */
@property(nonatomic,retain) NSString *minimumDate;
/** 就是日期  */
@property(nonatomic,retain) NSString *maximumDate;

// 以下属性只对CHPickerModeNormal 有效
/** 线的长度 */
@property (assign, nonatomic) CGFloat lineLength;
/** 数据源 */
@property (strong, nonatomic) NSArray *dataArray;



/**
 *  创建控件
 */
+ (CHPickerView *)pickerView;

/**
 *  展示
 */
- (void)show;

/**
 *  返回选择的时间
 */
@property (copy, nonatomic) CHPickerViewTimeBlock pickerViewTimeBlock;
/**
 *  返回选择的日期
 */
@property (copy, nonatomic) CHPickerViewDateBlock pickerViewDateBlock;
/**
 *  返回选择的数据
 */
@property (copy, nonatomic) CHPickerViewNormalBlock pickerViewNormalBlock;


@end
