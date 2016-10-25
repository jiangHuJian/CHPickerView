# CHPickerView
仿安卓偏平化的时间,日期,普通文字的选择器

## 普通选择器
```objc
    CHPickerView *pickerView = [CHPickerView pickerView];
    NSArray *array = [NSArray arrayWithObjects:@"中国", @"美国", @"日本", @"韩国", @"朝鲜", @"俄罗斯", @"蒙古", @"越南", nil];
    pickerView.dataArray = array;
    pickerView.lineColor = [UIColor orangeColor];
    [pickerView show];
    pickerView.pickerViewNormalBlock = ^(NSString *selectedData, NSInteger row) {
        _resultLabel.text = [NSString stringWithFormat:@"选择了第%zd行  %@", row, selectedData];
    };
```

## 日期选择器
```objc
    CHPickerView *pickerView = [CHPickerView pickerView];
    pickerView.lineColor = [UIColor orangeColor];
    pickerView.pickerMode = CHPickerModeDate;
    [pickerView show];
    pickerView.pickerViewDateBlock = ^(NSString *selectedDay, NSString *selectedMonth, NSString *selectedYear, NSString *selectedWeek) {
        _resultLabel.text = [NSString stringWithFormat:@"%@年%@月%@日 周%@", selectedYear, selectedMonth, selectedDay, selectedWeek];
    };
```

## 时间选择器
```objc
    CHPickerView *pickerView = [CHPickerView pickerView];
    pickerView.lineColor = [UIColor orangeColor];
    pickerView.pickerMode = CHPickerModeTime;
    [pickerView show];
    pickerView.pickerViewTimeBlock = ^(NSString *selectedSecond, NSString *selectedMintus, NSString *selectedHour) {
        _resultLabel.text = [NSString stringWithFormat:@"%@时%@分%@秒", selectedHour, selectedMintus, selectedSecond];
    };
```
