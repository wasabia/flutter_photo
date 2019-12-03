part of '../photo_main_page.dart';

class _BottomWidget extends StatefulWidget {
  final ValueChanged<AssetPathEntity> onGalleryChange;

  final Options options;

  final I18nProvider provider;

  final SelectedProvider selectedProvider;

  final String galleryName;

  final GalleryListProvider galleryListProvider;
  final VoidCallback onTapPreview;
  final Function sure;

  const _BottomWidget({
    Key key,
    this.onGalleryChange,
    this.options,
    this.provider,
    this.selectedProvider,
    this.galleryName = "",
    this.galleryListProvider,
    this.onTapPreview,
    this.sure
  }) : super(key: key);

  @override
  __BottomWidgetState createState() => __BottomWidgetState();
}

class __BottomWidgetState extends State<_BottomWidget> with SelectedProvider {
  Options get options => widget.options;

  I18nProvider get i18nProvider => widget.provider;

  @override
  Widget build(BuildContext context) {
    var textStyle = TextStyle(fontSize: 14.0, color: Colors.white);
    return Container(
      color: options.bottomBarColor,
      child: SafeArea(
        bottom: true,
        top: false,
        child: Container(
          height: 52.0,
          child: Row(
            children: <Widget>[
              FlatButton(
                onPressed: widget.onTapPreview,
                textColor: Colors.white,
                splashColor: Colors.transparent,
                disabledTextColor: options.disableColor,
                child: Container(
                  height: 44.0,
                  alignment: Alignment.center,
                  child: Text(
                    i18nProvider.getPreviewText(options, widget.selectedProvider),
                    style: selectedCount == 0
                      ? textStyle.copyWith(color: options.disableColor)
                      : textStyle,
                  ),
                ),
              ),

              Expanded(
                child: Container(),
              ),

              FlatButton(
                splashColor: Colors.transparent,
                child: Text(
                  i18nProvider.getSureText(options, widget.selectedProvider.selectedCount),
                  style: widget.selectedProvider.selectedCount == 0
                      ? textStyle.copyWith(color: options.disableColor)
                      : textStyle,
                ),
                onPressed: widget.selectedProvider.selectedCount == 0 ? null : sure,
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  bool isUpperLimit() {
    // TODO: implement isUpperLimit
    return null;
  }

  @override
  void sure() {
    widget.sure();
    // TODO: implement sure
  }
}
