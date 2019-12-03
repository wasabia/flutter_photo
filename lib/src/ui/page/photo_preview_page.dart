import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo/src/entity/options.dart';
import 'package:photo/src/provider/config_provider.dart';
import 'package:photo/src/provider/selected_provider.dart';
import 'package:photo/src/ui/page/photo_main_page.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoPreviewPage extends StatefulWidget {
  final SelectedProvider selectedProvider;

  final List<AssetEntity> list;

  final int initIndex;

  /// 这个参数是控制在内部点击check后是否实时修改provider状态
  final bool changeProviderOnCheckChange;

  /// 这里封装了结果
  final PhotoPreviewResult result;

  const PhotoPreviewPage({
    Key key,
    @required this.selectedProvider,
    @required this.list,
    @required this.changeProviderOnCheckChange,
    @required this.result,
    this.initIndex = 0,
  }) : super(key: key);

  @override
  _PhotoPreviewPageState createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  ConfigProvider get config => ConfigProvider.of(context);

  Options get options => config.options;

  Color get themeColor => options.themeColor;

  Color get bottomBarColor => options.bottomBarColor;

  Color get textColor => options.textColor;

  SelectedProvider get selectedProvider => widget.selectedProvider;

  List<AssetEntity> get list => widget.list;

  StreamController<int> pageChangeController = StreamController.broadcast();

  Stream<int> get pageStream => pageChangeController.stream;

  bool get changeProviderOnCheckChange => widget.changeProviderOnCheckChange;

  PhotoPreviewResult get result => widget.result;

  /// 缩略图用的数据
  ///
  /// 用于与provider数据联动
  List<AssetEntity> get previewList {
    return selectedProvider.selectedList;
  }

  /// 选中的数据
  List<AssetEntity> _selectedList = [];

  List<AssetEntity> get selectedList {
    if (changeProviderOnCheckChange) {
      return previewList;
    }
    return _selectedList;
  }

  PageController pageController;

  @override
  void initState() {
    super.initState();
    pageChangeController.add(0);
    pageController = PageController(
      initialPage: widget.initIndex,
    );

    _selectedList.clear();
    _selectedList.addAll(selectedProvider.selectedList);

    result.previewSelectedList = _selectedList;
  }

  @override
  void dispose() {
    pageChangeController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var data = Theme.of(context);
    var textStyle = TextStyle(
      color: options.textColor,
      fontSize: 14.0,
    );
    return Theme(
      data: data.copyWith(
        primaryColor: options.themeColor,
      ),
      child: DefaultTextStyle(
        style: textStyle,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: config.options.themeColor,
            // leading: BackButton(
            //   color: options.textColor,
            // ),
            leading: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_left,
                color: options.textColor,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: StreamBuilder(
              stream: pageStream,
              initialData: widget.initIndex,
              builder: (ctx, snap) => Text(
                "${snap.data + 1}/${widget.list.length}",
                style: textStyle,
              ),
            ),
            actions: <Widget>[
              _buildCheckbox(),
            ],
          ),
          body: PageView.builder(
            controller: pageController,
            itemBuilder: _buildItem,
            itemCount: list.length,
            onPageChanged: _onPageChanged,
          ),
          bottomSheet: _buildThumb(),
          bottomNavigationBar: _buildBottom(),
        ),
      ),  
    );
  }

  Widget _buildBottom() {
    return Container(
      color: bottomBarColor,
      child: SafeArea(
        child: Container(
          height: 52.0,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
              
              _buildSure()
            ],
          ),
        ),
      ),
    );
  }

  _buildSure() {
    var textStyle = TextStyle(
      color: options.textColor,
      fontSize: 14.0,
    );

    return StreamBuilder(
      stream: pageStream,
      builder: (ctx, s) => FlatButton(
            splashColor: Colors.transparent,
            onPressed: selectedList.length == 0 ? null : sure,
            child: Text(
              config.provider.getSureText(options, selectedList.length),
              style: selectedList.length == 0
                  ? textStyle.copyWith(color: options.disableColor)
                  : textStyle,
            ),
          ),
    );
  }

  Container _buildCheckbox() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 150.0,
      ),
      child: StreamBuilder<int>(
        builder: (ctx, snapshot) {
          var index = snapshot.data;
          var data = list[index];
          var checked = selectedList.contains(data);
          return Stack(
            children: <Widget>[
              IgnorePointer(
                child: _buildCheckboxContent(checked, index),
              ),
              Positioned(
                top: 0.0,
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: GestureDetector(
                  onTap: () => _changeSelected(!checked, index),
                  behavior: HitTestBehavior.translucent,
                  child: Container(),
                ),
              ),
            ],
          );
        },
        initialData: widget.initIndex,
        stream: pageStream,
      ),
    );
  }

  Widget _buildCheckboxContent(bool checked, int index) {
    BoxDecoration decoration;
    Widget child;

    if(checked) {
      decoration = BoxDecoration(
        color: Color.fromRGBO(2, 195, 95, 1),
        borderRadius: BorderRadius.circular(24.0),
      );
      child = Text(
        (index + 1).toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.0,
          color: options.textColor,
        ),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: Colors.white
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      margin: EdgeInsets.only(top: 16, right: 16),
      // padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: decoration,
        alignment: Alignment.center,
        child: child,
      ),
    );

    // return options.checkBoxBuilderDelegate.buildCheckBox(
    //   context,
    //   checked,
    //   index,
    //   options,
    //   config.provider,
    // );
  }

  void _changeSelected(bool isChecked, int index) {
    if (changeProviderOnCheckChange) {
      _onChangeProvider(isChecked, index);
    } else {
      _onCheckInOnlyPreview(isChecked, index);
    }
  }

  /// 仅仅修改预览时的状态,在退出时,再更新provider的顺序,这里无论添加与否不修改顺序
  void _onCheckInOnlyPreview(bool check, int index) {
    var item = list[index];
    if (check) {
      selectedList.add(item);
    } else {
      selectedList.remove(item);
    }
    pageChangeController.add(index);
  }

  /// 直接修改预览状态,会直接移除item
  void _onChangeProvider(bool check, int index) {
    var item = list[index];
    if (check) {
      selectedProvider.addSelectEntity(item);
    } else {
      selectedProvider.removeSelectEntity(item);
    }
    pageChangeController.add(index);
  }

  Widget _buildItem(BuildContext context, int index) {
    var data = list[index];
    return BigPhotoImage(
      assetEntity: data,
      loadingWidget: _buildLoadingWidget(data),
    );
  }

  Widget _buildLoadingWidget(AssetEntity entity) {
    return options.loadingDelegate
        .buildBigImageLoading(context, entity, themeColor);
  }

  void _onPageChanged(int value) {
    pageChangeController.add(value);
  }

  Widget _buildThumb() {
    return StreamBuilder(
      builder: (ctx, snapshot) => Container(
        height: 80.0,
        child: ListView.builder(
          itemBuilder: _buildThumbItem,
          itemCount: previewList.length,
          scrollDirection: Axis.horizontal,
        ),
      ),
      stream: pageStream,
    );
  }

  Widget _buildThumbItem(BuildContext context, int index) {
    var item = previewList[index];


    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => changeSelected(item, index),
        child: Container(
          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
          width: 80.0,
          child: Stack(
            children: <Widget>[
              ImageItem(
                themeColor: themeColor,
                entity: item,
                size: options.thumbSize,
                loadingDelegate: options.loadingDelegate,
              ),
              IgnorePointer(
                child: StreamBuilder(
                  stream: pageStream,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (selectedList.contains(item)) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color.fromRGBO(2, 195, 95, 1),
                            width: 3,
                          ),
                        ),
                      );
                    }
                    return Container(
                      color: Colors.white.withOpacity(0.5),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void changeSelected(AssetEntity entity, int index) {
    var itemIndex = list.indexOf(entity);
    if (itemIndex != -1) pageController.jumpToPage(itemIndex);
  }

  void sure() {
    Navigator.pop(context, selectedList);
  }
}

class BigPhotoImage extends StatefulWidget {
  final AssetEntity assetEntity;
  final Widget loadingWidget;

  const BigPhotoImage({
    Key key,
    this.assetEntity,
    this.loadingWidget,
  }) : super(key: key);

  @override
  _BigPhotoImageState createState() => _BigPhotoImageState();
}

class _BigPhotoImageState extends State<BigPhotoImage>
    with AutomaticKeepAliveClientMixin {
  Widget get loadingWidget {
    return widget.loadingWidget ?? Container();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return FutureBuilder(
      future:
          widget.assetEntity.thumbDataWithSize(width.floor(), height.floor()),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        var file = snapshot.data;
        if (snapshot.connectionState == ConnectionState.done && file != null) {
          print(file.length);
          return Image.memory(
            file,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          );
        }
        return loadingWidget;
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class PhotoPreviewResult {
  List<AssetEntity> previewSelectedList = [];
}
