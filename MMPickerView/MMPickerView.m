//
//  MMPickerView.m
//  MMPickerView
//
//  Created by Madjid Mahdjoubi on 6/5/13.
//  Copyright (c) 2013 GG. All rights reserved.
//

#import "MMPickerView.h"

NSString * const MMbackgroundColor = @"backgroundColor";
NSString * const MMtextColor = @"textColor";
NSString * const MMtoolbarColor = @"toolbarColor";
NSString * const MMbuttonColor = @"buttonColor";
NSString * const MMfont = @"font";
NSString * const MMvalueY = @"yValueFromTop";
NSString * const MMselectedObject = @"selectedObject";
NSString * const MMtoolbarBackgroundImage = @"toolbarBackgroundImage";
NSString * const MMtextAlignment = @"textAlignment";
NSString * const MMshowsSelectionIndicator = @"showsSelectionIndicator";

@interface MMPickerView () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UILabel *pickerViewLabel;
@property (nonatomic, strong) UIView *pickerViewLabelView;
@property (nonatomic, strong) UIView *pickerContainerView;
@property (nonatomic, strong) UIView *pickerViewContainerView;
@property (nonatomic, strong) UIView *pickerTopBarView;
@property (nonatomic, strong) UIImageView *pickerTopBarImageView;
@property (nonatomic, strong) UIToolbar *pickerViewToolBar;
@property (nonatomic, strong) UIBarButtonItem *pickerViewBarButtonItem;
@property (nonatomic, strong) UIButton *pickerDoneButton;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *pickerViewArray;
@property (nonatomic, strong) NSArray *pickerViewComponentSizes;
@property (nonatomic, strong) UIColor *pickerViewTextColor;
@property (nonatomic, strong) UIFont *pickerViewFont;
@property (nonatomic, assign) CGFloat yValueFromTop;
@property (nonatomic, assign) NSInteger pickerViewTextAlignment;
@property (nonatomic, assign) BOOL pickerViewShowsSelectionIndicator;
@property (nonatomic, assign) BOOL multidimensional;
@property (copy) void (^onDismissCompletion)(id);
@property (copy) NSString *(^objectToStringConverter)(id object);

@end


@implementation MMPickerView

#pragma mark - Singleton

+ (MMPickerView*)sharedView {
  static dispatch_once_t once;
  static MMPickerView *sharedView;
  dispatch_once(&once, ^ { sharedView = [[self alloc] init]; });
  return sharedView;
}

#pragma mark - Show Methods

+(void)showPickerViewInView:(UIView *)view
                withStrings:(NSArray *)strings
                withOptions:(NSDictionary *)options
                 completion:(void (^)(NSString *))completion{
  
  [[self sharedView] initializePickerViewInView:view
                                      withArray:strings
                             withComponentSizes:nil
                             isMultidimensional:NO
                                    withOptions:options];
  
  [[self sharedView] setPickerHidden:NO callBack:nil];
  [self sharedView].onDismissCompletion = completion;
  [view addSubview:[self sharedView]];
  
}

+(void)showPickerViewInView:(UIView *)view
                withObjects:(NSArray *)objects
                withOptions:(NSDictionary *)options
    objectToStringConverter:(NSString *(^)(id))converter
                 completion:(void (^)(id))completion {
  
  [self sharedView].objectToStringConverter = converter;
  [self sharedView].onDismissCompletion = completion;
  [[self sharedView] initializePickerViewInView:view
                                      withArray:objects
                             withComponentSizes:nil
                             isMultidimensional:NO
                                    withOptions:options];
  [[self sharedView] setPickerHidden:NO callBack:nil];
  [view addSubview:[self sharedView]];
  
}

+(void)showPickerViewInView: (UIView *)view
                 withArrays: (NSArray *)arrays
         withComponentSizes: (NSArray *)sizes
                withOptions: (NSDictionary *)options
                 completion: (void (^)(NSArray* selectedComponents))completion{

    [[self sharedView] initializePickerViewInView:view
                                        withArray:arrays
                               withComponentSizes:sizes
                               isMultidimensional:YES
                                      withOptions:options];
    
    [[self sharedView] setPickerHidden:NO callBack:nil];
    [self sharedView].onDismissCompletion = completion;
    [view addSubview:[self sharedView]];
    
}


#pragma mark - Dismiss Methods

+(void)dismissWithCompletion:(void (^)(NSString *))completion{
    [[self sharedView] setPickerHidden:YES callBack:completion];
}

-(void)dismiss{
    [MMPickerView dismissWithCompletion:self.onDismissCompletion];
}

+(void)removePickerView{
    [[self sharedView] removeFromSuperview];
}

#pragma mark - Show/hide PickerView methods

-(void)setPickerHidden: (BOOL)hidden
              callBack: (void(^)(NSString *))callBack; {
  
  [UIView animateWithDuration:0.3
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
                     
                     if (hidden) {
                       [_pickerViewContainerView setAlpha:0.0];
                       [_pickerContainerView setTransform:CGAffineTransformMakeTranslation(0.0, CGRectGetHeight(_pickerContainerView.frame))];
                     } else {
                       [_pickerViewContainerView setAlpha:1.0];
                       [_pickerContainerView setTransform:CGAffineTransformIdentity];
                     }
                   } completion:^(BOOL completed) {
                     if(completed && hidden){
                       [MMPickerView removePickerView];
                       callBack([self selectedObject]);
                     }
                   }];
  
}

#pragma mark - Initialize PickerView

-(void)initializePickerViewInView: (UIView *)view
                        withArray: (NSArray *)array
               withComponentSizes: (NSArray *)sizes
               isMultidimensional: (BOOL) multidemsional
                      withOptions: (NSDictionary *)options {
  
  _pickerViewArray = array;
  _multidimensional = multidemsional;
  _pickerViewComponentSizes = sizes;
    
  // get number of components
  NSInteger numberComponents = multidemsional ? array.count : 1;
    
  // if no component sizes were given just calculate them
  if(_pickerViewComponentSizes == nil || numberComponents != _pickerViewComponentSizes.count)
  {
        _pickerViewComponentSizes = [[NSMutableArray alloc] initWithCapacity:numberComponents];
        for(int i=0; i<numberComponents; i++)
        {
            [(NSMutableArray*)_pickerViewComponentSizes addObject:@(320.f/numberComponents)];
        }
  }

  
  id chosenObject = options[MMselectedObject];
  NSMutableArray* selectedRows = [[NSMutableArray alloc] init];
  
  if (chosenObject != nil) {
      if (_multidimensional) {
          for (int i=0;i<numberComponents;i++) {
              [selectedRows addObject: [NSNumber numberWithInteger:[_pickerViewArray[i] indexOfObject:chosenObject[i]]]];
          }
      } else {
          [selectedRows addObject: [NSNumber numberWithInteger:[_pickerViewArray indexOfObject:chosenObject]]];
      }
  }else{
      [selectedRows addObject:[NSNumber numberWithInteger:0]];
  }
  
  
  NSNumber *textAlignment = [[NSNumber alloc] init];
  textAlignment = options[MMtextAlignment];
  //Default value is NSTextAlignmentCenter
  _pickerViewTextAlignment = 1;
  
  if (textAlignment != nil) {
      _pickerViewTextAlignment = [options[MMtextAlignment] integerValue];
  }
  
  BOOL showSelectionIndicator = [options[MMshowsSelectionIndicator] boolValue];
  
  if (!showSelectionIndicator) {
      _pickerViewShowsSelectionIndicator = 1;
  }
  _pickerViewShowsSelectionIndicator = showSelectionIndicator;
  
  UIColor *pickerViewBackgroundColor = [[UIColor alloc] initWithCGColor:[options[MMbackgroundColor] CGColor]];
  UIColor *pickerViewTextColor = [[UIColor alloc] initWithCGColor:[options[MMtextColor] CGColor]];
  UIColor *toolbarBackgroundColor = [[UIColor alloc] initWithCGColor:[options[MMtoolbarColor] CGColor]];
  UIColor *buttonTextColor = [[UIColor alloc] initWithCGColor:[options[MMbuttonColor] CGColor]];
  UIFont *pickerViewFont = [[UIFont alloc] init];
  pickerViewFont = options[MMfont];
  _yValueFromTop = [options[MMvalueY] floatValue];
  
  [self setFrame: view.bounds];
  [self setBackgroundColor:[UIColor clearColor]];
  
  UIImage * toolbarImage = options[MMtoolbarBackgroundImage];
  
  //Whole screen with PickerView and a dimmed background
  _pickerViewContainerView = [[UIView alloc] initWithFrame:view.bounds];
  [_pickerViewContainerView setBackgroundColor: [UIColor colorWithRed:0.412 green:0.412 blue:0.412 alpha:0.7]];
  [self addSubview:_pickerViewContainerView];
  
  //PickerView Container with top bar
  _pickerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, _pickerViewContainerView.bounds.size.height - 260.0, 320.0, 260.0)];
    
  //Default Color Values (if colors == nil)
  
  //PickerViewBackgroundColor - White
  if (pickerViewBackgroundColor==nil) {
    pickerViewBackgroundColor = [UIColor whiteColor];
  }
  
  //PickerViewTextColor - Black
  if (pickerViewTextColor==nil) {
    pickerViewTextColor = [UIColor blackColor];
  }
  _pickerViewTextColor = pickerViewTextColor;
  
  //ToolbarBackgroundColor - Black
  if (toolbarBackgroundColor==nil) {
    toolbarBackgroundColor = [UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:0.8];
  }
  
  //ButtonTextColor - Blue
  if (buttonTextColor==nil) {
    buttonTextColor = [UIColor colorWithRed:0.000 green:0.486 blue:0.976 alpha:1];
  }
  
  if (pickerViewFont==nil) {
    _pickerViewFont = [UIFont systemFontOfSize:22];
  }
  _pickerViewFont = pickerViewFont;
  _pickerContainerView.backgroundColor = pickerViewBackgroundColor;
  [_pickerViewContainerView addSubview:_pickerContainerView];
  
  
  //Content of pickerContainerView
  
  //Top bar view
  _pickerTopBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _pickerContainerView.frame.size.width, 44.0)];
  [_pickerContainerView addSubview:_pickerTopBarView];
  [_pickerTopBarView setBackgroundColor:[UIColor whiteColor]];
  
  
  _pickerViewToolBar = [[UIToolbar alloc] initWithFrame:_pickerTopBarView.frame];
  [_pickerContainerView addSubview:_pickerViewToolBar];
  
  CGFloat iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
  //NSLog(@"%f",iOSVersion);
  
  if (iOSVersion < 7.0) {
    _pickerViewToolBar.tintColor = toolbarBackgroundColor;
    //[_pickerViewToolBar setBackgroundColor:toolbarBackgroundColor];
  }else{
     [_pickerViewToolBar setBackgroundColor:toolbarBackgroundColor];

     //_pickerViewToolBar.tintColor = toolbarBackgroundColor;
  
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    _pickerViewToolBar.barTintColor = toolbarBackgroundColor;
    #endif
  }
  
  if (toolbarImage!=nil) {
    [_pickerViewToolBar setBackgroundImage:toolbarImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
  }
  
  UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  
  _pickerViewBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
  _pickerViewToolBar.items = @[flexibleSpace, _pickerViewBarButtonItem];
  [_pickerViewBarButtonItem setTintColor:buttonTextColor];
  
  
  //Add pickerView
  _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 44.0, 320.0, 216.0)];
  [_pickerView setDelegate:self];
  [_pickerView setDataSource:self];
  [_pickerView setShowsSelectionIndicator: _pickerViewShowsSelectionIndicator];//YES];
  [_pickerContainerView addSubview:_pickerView];
  
  //[self.pickerViewContainerView setAlpha:0.0];
  [_pickerContainerView setTransform:CGAffineTransformMakeTranslation(0.0, CGRectGetHeight(_pickerContainerView.frame))];
  
  //Set selected row
  for (int comp = 0; comp < numberComponents; comp++) {
        [_pickerView selectRow:[selectedRows[comp] integerValue] inComponent:comp animated:YES];
  }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView: (UIPickerView *)pickerView {
    if (_multidimensional) {
        return _pickerViewArray.count;
    } else {
        return 1;
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component {
    if (_multidimensional) {
        return [_pickerViewArray[component] count];
    } else {
        return [_pickerViewArray count];
    }
}

- (NSString *)pickerView: (UIPickerView *)pickerView
             titleForRow: (NSInteger)row
            forComponent: (NSInteger)component {
    if (_multidimensional) {
        return [_pickerViewArray[component] objectAtIndex:row];
    } else {
        
        if (self.objectToStringConverter == nil){
            return [_pickerViewArray objectAtIndex:row];
        } else{
            return (self.objectToStringConverter ([_pickerViewArray objectAtIndex:row]));
        }
    }
}

#pragma mark - UIPickerViewDelegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (_multidimensional) {
        self.onDismissCompletion ([self selectedObject]);
    } else {
        if (self.objectToStringConverter == nil) {
            self.onDismissCompletion ([_pickerViewArray objectAtIndex:row]);
        } else{
            self.onDismissCompletion (self.objectToStringConverter ([self selectedObject]));
        }
    }
}

- (id)selectedObject {
    if (_multidimensional) {
        NSMutableArray* result = [[NSMutableArray alloc] init];
        for (int i=0;i<_pickerViewArray.count;i++) {
            [result addObject:[_pickerViewArray[i] objectAtIndex: [self.pickerView selectedRowInComponent:i]]];
        }
        
        return [[NSArray alloc] initWithArray:result];
    } else {
        return [_pickerViewArray objectAtIndex: [self.pickerView selectedRowInComponent:0]];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  
  UIView *customPickerView = view;
  
  UILabel *pickerViewLabel;
  
  if (customPickerView==nil) {
    
    CGRect frame = CGRectMake(0.0, 0.0, 320.f, 44.0);
    customPickerView = [[UIView alloc] initWithFrame: frame];
    
//   UIImageView *patternImageView = [[UIImageView alloc] initWithFrame:frame];
//   patternImageView.image = [[UIImage imageNamed:@"texture"] resizableImageWithCapInsets:UIEdgeInsetsZero];
//    [customPickerView addSubview:patternImageView];
    
    if (_yValueFromTop == 0.0f) {
      _yValueFromTop = 3.0;
    }
    
    CGRect labelFrame = CGRectMake(0.0, _yValueFromTop, 320.f, 35); // 35 or 44
    pickerViewLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [pickerViewLabel setTag:1];
    [pickerViewLabel setTextAlignment: _pickerViewTextAlignment];
    [pickerViewLabel setBackgroundColor:[UIColor clearColor]];
    [pickerViewLabel setTextColor:_pickerViewTextColor];
    [pickerViewLabel setFont:_pickerViewFont];
    [customPickerView addSubview:pickerViewLabel];
  } else{
    
    for (UIView *view in customPickerView.subviews) {
      if (view.tag == 1) {
        pickerViewLabel = (UILabel *)view;
        break;
      }
    }
  }
  
  if (_multidimensional) {
        [pickerViewLabel setText:[_pickerViewArray[component] objectAtIndex:row]];
  } else {
        if (self.objectToStringConverter == nil){
            [pickerViewLabel setText: [_pickerViewArray objectAtIndex:row]];
        } else{
            [pickerViewLabel setText:(self.objectToStringConverter ([_pickerViewArray objectAtIndex:row]))];
        }
  }
  
  return customPickerView;

}

- (CGFloat) pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return [(NSNumber*)[_pickerViewComponentSizes objectAtIndex:component] floatValue];
}

@end
