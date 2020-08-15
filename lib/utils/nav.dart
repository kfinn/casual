import 'package:flutter/material.dart';

class Nav {
  final NavigatorState navigator;

  const Nav(this.navigator);

  factory Nav.of(BuildContext context, {bool root = false}) {
    return Nav(Navigator.of(context, rootNavigator: root));
  }

  Future<T> presentScreen<T>(WidgetBuilder builder) async {
    return navigator.push(
      AppPageRoute(
        builder: builder,
        fullscreenDialog: true,
      ),
    );
  }

  Future<T> pushScreen<T>(WidgetBuilder builder) async {
    return navigator.push(AppPageRoute(builder: builder));
  }

  Future<T> replaceScreen<T>(WidgetBuilder builder) async {
    return navigator.pushReplacement(
      AppPageRoute(
        builder: builder,
        animated: false,
      ),
    );
  }

  void pop<T>([T result]) {
    return navigator.pop(result);
  }
}

class AppPageRoute<T> extends MaterialPageRoute<T> {
  final bool animated;

  AppPageRoute({
    WidgetBuilder builder,
    RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    this.animated = true,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return animated
        ? super.buildTransitions(context, animation, secondaryAnimation, child)
        : child;
  }
}
