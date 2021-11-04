import 'package:flutter/material.dart';
import 'package:lendme/exceptions/general.dart';
import 'package:lendme/models/resource.dart';
import 'package:lendme/models/user.dart';
import 'package:lendme/routes/auth_routes.dart';
import 'package:lendme/routes/main_routes.dart';
import 'package:lendme/screens/settings/edit_profile.dart';
import 'package:provider/provider.dart';

import 'other/error.dart';
import 'other/splash.dart';

enum _Screen {
  splash, auth, main, fillProfile, error
}

class Proxy extends StatefulWidget {
  const Proxy({Key? key}) : super(key: key);

  @override
  State<Proxy> createState() => _ProxyState();
}

class _ProxyState extends State<Proxy> {

  late _Screen _screen;
  late Widget _view;

  final Map<_Screen, Widget> _screenViews = {
    _Screen.splash: const Splash(),
    _Screen.auth: PreMadeNavigator(routes: authRoutes, key: UniqueKey(),),
    _Screen.main: PreMadeNavigator(routes: mainRoutes, key: UniqueKey()),
    _Screen.fillProfile: const EditProfile(afterLoginVariant: true),
    _Screen.error: const ErrorScreen(),
  };

  @override
  void initState() {
    _screen = _getScreenForUser(Resource<User>.loading());
    _view = _screenViews[_screen]!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userResource = Provider.of<Resource<User>>(context);

    var newScreen = _getScreenForUser(userResource);
    if(_screen != newScreen) {
      setState(() {
        _screen = newScreen;
        _view = _screenViews[_screen]!;
      });
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      transitionBuilder: (Widget child, Animation<double> animation) =>
        SlideTransition(
          position: Tween<Offset>(
              begin: const Offset(1.2, 0),
              end: const Offset(0, 0)
          ).animate(animation),
          child: child,
        ),
      child: _view,
    );
  }

  _Screen _getScreenForUser(Resource<User> userResource) {
    if(userResource.isError) {
      if(userResource.error is ResourceNotFoundException) {
        return _Screen.auth;
      }
      else {
        return _Screen.error;
      }
    }
    else if(userResource.isSuccess) {
      if(userResource.data!.info.isFilled()) {
        return _Screen.main;
      }
      else {
        return _Screen.fillProfile;
      }
    }

    return _Screen.splash;
  }
}

class PreMadeNavigator extends StatelessWidget {
  PreMadeNavigator({required this.routes, this.initialRoute='/', Key? key}) : super(key: key);

  final GlobalKey<NavigatorState> _navigator = GlobalKey();
  final String initialRoute;
  final Route<dynamic>? Function(RouteSettings) routes;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigator.currentState?.maybePop();
        return false;
      },
      child: Navigator(
        key: _navigator,
        initialRoute: initialRoute,
        onGenerateRoute: routes,
      ),
    );
  }
}
