//
//  JJCollectionViewRoundFlowLayout+Alignment.m
//  JJCollectionViewRoundFlowLayout
//
//  Created by jiajie on 2020/1/10.
//

#import "JJCollectionViewRoundFlowLayout+Alignment.h"
#import "JJCollectionViewFlowLayoutUtils.h"

@implementation JJCollectionViewRoundFlowLayout(Alignment)


/// 将相同section的cell集合到一个集合中(竖向)
/// @param layoutAttributesAttrs layoutAttributesAttrs description
- (NSDictionary *)groupLayoutAttributesForElementsBySectionWithLayoutAttributesAttrs:(NSArray *)layoutAttributesAttrs{
    NSMutableDictionary *allSectionDict = [NSMutableDictionary dictionaryWithCapacity:0];
    for (UICollectionViewLayoutAttributes *attr  in layoutAttributesAttrs) {
        NSMutableArray *dictArr = allSectionDict[@(attr.indexPath.section)];
        if (dictArr) {
            [dictArr addObject:[attr copy]];
        }else{
            NSMutableArray *arr = [NSMutableArray arrayWithObject:[attr copy]];
            allSectionDict[@(attr.indexPath.section)] = arr;
        }
    }
    return allSectionDict;
}

/// 将cell和SupplementaryView按照行分组(竖向)
/// @param layoutAttributesAttrs layoutAttributesAttrs description
- (NSArray *)groupLayoutAttributesForElementsByYLineWithLayoutAttributesAttrs:(NSArray *)layoutAttributesAttrs{
    // - (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect 没有明确说明是按照indexPath升序排列，sorted下更保险
    // 对传入的attributes进行排序
    NSArray *sortedAttributes = [layoutAttributesAttrs sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewLayoutAttributes *attr1, UICollectionViewLayoutAttributes *attr2) {
        return [attr1.indexPath compare:attr2.indexPath];
    }];

    // 分组处理
    NSMutableArray *rows = [NSMutableArray array];
    NSMutableArray *currentRowAttributes;
    CGFloat currentRowMaxY = -1;
    for (UICollectionViewLayoutAttributes *attribute in sortedAttributes) {
        if (attribute.representedElementKind) {
            // SupplementaryView单独一行
            [rows addObject:@[attribute]];
            continue;
        }
        if (attribute.frame.origin.y >= currentRowMaxY) {
            // 开始新的一行
            if (currentRowAttributes) {
                [rows addObject:currentRowAttributes];
            }
            currentRowAttributes = @[attribute].mutableCopy;
            currentRowMaxY = CGRectGetMaxY(attribute.frame);
        } else {
            // 添加到当前行
            [currentRowAttributes addObject:attribute];
            currentRowMaxY = MAX(currentRowMaxY, CGRectGetMaxY(attribute.frame));
        }
    }

    // 添加最后一行
    if (currentRowAttributes.count > 0) {
        [rows addObject:currentRowAttributes];
    }
    return [rows copy];
}

/// 将相同x位置的cell集合到一个列表中(横向)
/// @param layoutAttributesAttrs layoutAttributesAttrs description
- (NSArray *)groupLayoutAttributesForElementsByXLineWithLayoutAttributesAttrs:(NSArray *)layoutAttributesAttrs{
    NSMutableDictionary *allDict = [NSMutableDictionary dictionaryWithCapacity:0];
    for (UICollectionViewLayoutAttributes *attr in layoutAttributesAttrs) {
        NSMutableArray *dictArr = allDict[@(attr.frame.origin.x)];
        if (dictArr) {
            [dictArr addObject:[attr copy]];
        }else{
            NSMutableArray *arr = [NSMutableArray arrayWithObject:[attr copy]];
            allDict[@(attr.frame.origin.x)] = arr;
        }
    }
    return allDict.allValues;
}

/// 进行cells集合对齐方式判断解析
/// @param layoutAttributesAttrs layoutAttributesAttrs description
/// @param toChangeAttributesAttrsList toChangeAttributesAttrsList description
/// @param alignmentType alignmentType description
- (void)analysisCellSettingFrameWithLayoutAttributesAttrs:(NSArray *)layoutAttributesAttrs
                                 toChangeAttributesAttrsList:(NSMutableArray *_Nonnull *_Nonnull)toChangeAttributesAttrsList
                                        cellAlignmentType:(JJCollectionViewRoundFlowLayoutAlignmentType)alignmentType {
    if (alignmentType != JJCollectionViewFlowLayoutAlignmentTypeBySystem) {
        NSArray *formatGroudAttr = [self groupLayoutAttributesForElementsByYLineWithLayoutAttributesAttrs:layoutAttributesAttrs];
        
        for (NSArray <UICollectionViewLayoutAttributes * >*calculateAttributesAttrsArr in formatGroudAttr) {
            [self evaluatedAllCellSettingFrameWithLayoutAttributesAttrs:calculateAttributesAttrsArr
                                            toChangeAttributesAttrsList:toChangeAttributesAttrsList
                                                      cellAlignmentType:alignmentType];
        }
    }else {
        [*toChangeAttributesAttrsList addObjectsFromArray:layoutAttributesAttrs];
    }
}

/// 根据不同对齐方式进行Cell位置计算
/// @param layoutAttributesAttrs 传入需计算的AttributesAttrs集合列表
/// @param toChangeAttributesAttrsList 用来保存所有计算后的AttributesAttrs
/// @param alignmentType 对齐方式
- (NSMutableArray *)evaluatedAllCellSettingFrameWithLayoutAttributesAttrs:(NSArray *)layoutAttributesAttrs toChangeAttributesAttrsList:(NSMutableArray *_Nonnull *_Nonnull)toChangeAttributesAttrsList cellAlignmentType:(JJCollectionViewRoundFlowLayoutAlignmentType)alignmentType {
    NSMutableArray *toChangeList = *toChangeAttributesAttrsList;
    switch (alignmentType) {
        case JJCollectionViewFlowLayoutAlignmentTypeByLeft:{
            [self evaluatedCellSettingFrameByLeftWithWithJJCollectionLayout:self layoutAttributesAttrs:layoutAttributesAttrs];
        }break;
        case JJCollectionViewFlowLayoutAlignmentTypeByLeftTop:{
            [self evaluatedCellSettingFrameByLeftTopWithWithJJCollectionLayout:self layoutAttributesAttrs:layoutAttributesAttrs];
        }break;
        case JJCollectionViewFlowLayoutAlignmentTypeByCenter:{
            [self evaluatedCellSettingFrameByCentertWithWithJJCollectionLayout:self layoutAttributesAttrs:layoutAttributesAttrs];
        }break;
        case JJCollectionViewFlowLayoutAlignmentTypeByRight:{
            NSArray* reversedArray = [[layoutAttributesAttrs reverseObjectEnumerator] allObjects];
            [self evaluatedCellSettingFrameByRightWithWithJJCollectionLayout:self layoutAttributesAttrs:reversedArray];
        }break;
        case JJCollectionViewFlowLayoutAlignmentTypeByRightAndStartR:{
            [self evaluatedCellSettingFrameByRightWithWithJJCollectionLayout:self layoutAttributesAttrs:layoutAttributesAttrs];
        }break;
        default:
            break;
    }
    [toChangeList addObjectsFromArray:layoutAttributesAttrs];
    return toChangeList;
}

#pragma mark - alignment

/// 计算AttributesAttrs左对齐
/// @param layout JJCollectionViewRoundFlowLayout
/// @param layoutAttributesAttrs 需计算的AttributesAttrs列表
- (void)evaluatedCellSettingFrameByLeftWithWithJJCollectionLayout:(JJCollectionViewRoundFlowLayout *)layout layoutAttributesAttrs:(NSArray *)layoutAttributesAttrs{
    //left
    UICollectionViewLayoutAttributes *pAttr = nil;
    for (UICollectionViewLayoutAttributes *attr in layoutAttributesAttrs) {
        if (attr.representedElementKind != nil) {
            //nil when representedElementCategory is UICollectionElementCategoryCell (空的时候为cell)
            continue;
        }
        CGRect frame = attr.frame;

        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            //竖向
            if (pAttr) {
                frame.origin.x = pAttr.frame.origin.x + pAttr.frame.size.width + [JJCollectionViewFlowLayoutUtils evaluatedMinimumInteritemSpacingForSectionWithCollectionLayout:layout atIndex:attr.indexPath.section];
            }else{
                frame.origin.x = [JJCollectionViewFlowLayoutUtils evaluatedSectionInsetForItemWithCollectionLayout:layout atIndex:attr.indexPath.section].left;
            }
        }else{
            //横向
            if (pAttr) {
                frame.origin.y = pAttr.frame.origin.y + pAttr.frame.size.height + [JJCollectionViewFlowLayoutUtils evaluatedMinimumInteritemSpacingForSectionWithCollectionLayout:layout atIndex:attr.indexPath.section];
            }else{
                frame.origin.y = [JJCollectionViewFlowLayoutUtils evaluatedSectionInsetForItemWithCollectionLayout:layout atIndex:attr.indexPath.section].top;
            }
        }
        attr.frame = frame;
        pAttr = attr;
    }
}

/// 计算AttributesAttrs左顶对齐
/// @param layout JJCollectionViewRoundFlowLayout
/// @param layoutAttributesAttrs 需计算的AttributesAttrs列表
- (void)evaluatedCellSettingFrameByLeftTopWithWithJJCollectionLayout:(JJCollectionViewRoundFlowLayout *)layout layoutAttributesAttrs:(NSArray *)layoutAttributesAttrs{
    UICollectionViewLayoutAttributes *pAttr = nil;
    CGFloat minPointY = MAXFLOAT;
    // 调整x坐标
    for (UICollectionViewLayoutAttributes *attr in layoutAttributesAttrs) {
        if (attr.representedElementKind != nil) {
            //nil when representedElementCategory is UICollectionElementCategoryCell
            continue;
        }
        CGRect frame = attr.frame;
        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            //竖向
            minPointY = MIN(minPointY, attr.frame.origin.y);
            if (pAttr) {
                frame.origin.x = pAttr.frame.origin.x + pAttr.frame.size.width + [JJCollectionViewFlowLayoutUtils evaluatedMinimumInteritemSpacingForSectionWithCollectionLayout:layout atIndex:attr.indexPath.section];
            }else{
                frame.origin.x = [JJCollectionViewFlowLayoutUtils evaluatedSectionInsetForItemWithCollectionLayout:layout atIndex:attr.indexPath.section].left;
            }
        }// 不支持横向
        attr.frame = frame;
        pAttr = attr;
    }
    // 调整y坐标
    for (UICollectionViewLayoutAttributes *attr in layoutAttributesAttrs) {
        if (attr.representedElementKind != nil) {
            // 非cell
            continue;
        }
        CGRect newFrame = attr.frame;
        newFrame.origin.y = minPointY;
        attr.frame = newFrame;
    }
}

/// 计算AttributesAttrs居中对齐
/// @param layout JJCollectionViewRoundFlowLayout
/// @param layoutAttributesAttrs 需计算的AttributesAttrs列表
- (void)evaluatedCellSettingFrameByCentertWithWithJJCollectionLayout:(JJCollectionViewRoundFlowLayout *)layout layoutAttributesAttrs:(NSArray *)layoutAttributesAttrs{
    
    //center
    UICollectionViewLayoutAttributes *pAttr = nil;
    
    CGFloat useWidth = 0;
            NSInteger theSection = ((UICollectionViewLayoutAttributes *)layoutAttributesAttrs.firstObject).indexPath.section;
            for (UICollectionViewLayoutAttributes *attr in layoutAttributesAttrs) {
                useWidth += attr.bounds.size.width;
            }
    CGFloat firstLeft = (self.collectionView.bounds.size.width - useWidth - ([JJCollectionViewFlowLayoutUtils evaluatedMinimumInteritemSpacingForSectionWithCollectionLayout:layout atIndex:theSection]*layoutAttributesAttrs.count))/2.0;
    
    for (UICollectionViewLayoutAttributes *attr in layoutAttributesAttrs) {
        if (attr.representedElementKind != nil) {
            //nil when representedElementCategory is UICollectionElementCategoryCell (空的时候为cell)
            continue;
        }
        CGRect frame = attr.frame;

        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            //竖向
            if (pAttr) {
                frame.origin.x = pAttr.frame.origin.x + pAttr.frame.size.width + [JJCollectionViewFlowLayoutUtils evaluatedMinimumInteritemSpacingForSectionWithCollectionLayout:layout atIndex:attr.indexPath.section];
            }else{
                frame.origin.x = firstLeft;
            }
            attr.frame = frame;
            pAttr = attr;
        }else{
            //横向
            if (pAttr) {
                frame.origin.y = pAttr.frame.origin.y + pAttr.frame.size.height + [JJCollectionViewFlowLayoutUtils evaluatedMinimumInteritemSpacingForSectionWithCollectionLayout:layout atIndex:attr.indexPath.section];
            }else{
                frame.origin.y = [JJCollectionViewFlowLayoutUtils evaluatedSectionInsetForItemWithCollectionLayout:layout atIndex:attr.indexPath.section].top;
            }
        }
        attr.frame = frame;
        pAttr = attr;
    }
}


/// 计算AttributesAttrs右对齐
/// @param layout JJCollectionViewRoundFlowLayout
/// @param layoutAttributesAttrs 需计算的AttributesAttrs列表
- (void)evaluatedCellSettingFrameByRightWithWithJJCollectionLayout:(JJCollectionViewRoundFlowLayout *)layout layoutAttributesAttrs:(NSArray *)layoutAttributesAttrs{
//    right
    UICollectionViewLayoutAttributes *pAttr = nil;
    for (UICollectionViewLayoutAttributes *attr in layoutAttributesAttrs) {
        if (attr.representedElementKind != nil) {
            //nil when representedElementCategory is UICollectionElementCategoryCell (空的时候为cell)
            continue;
        }
        CGRect frame = attr.frame;

        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            //竖向
            if (pAttr) {
                frame.origin.x = pAttr.frame.origin.x - [JJCollectionViewFlowLayoutUtils evaluatedMinimumInteritemSpacingForSectionWithCollectionLayout:layout atIndex:attr.indexPath.section] - frame.size.width;
            }else{
                frame.origin.x = layout.collectionView.bounds.size.width - [JJCollectionViewFlowLayoutUtils evaluatedSectionInsetForItemWithCollectionLayout:layout atIndex:attr.indexPath.section].right - frame.size.width;
            }
        }else{
            
        }
        attr.frame = frame;
        pAttr = attr;
    }
}

@end
