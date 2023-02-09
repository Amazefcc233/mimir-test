import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rettulf/rettulf.dart';

import '../init.dart';
import '../using.dart';

class LoginPage extends StatefulWidget {
  final bool disableOffline;

  const LoginPage({super.key, required this.disableOffline});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text field controllers.
  final TextEditingController $account = TextEditingController();
  final TextEditingController $password = TextEditingController();
  final TextEditingController $proxy = TextEditingController();

  final GlobalKey _formKey = GlobalKey<FormState>();

  // State
  bool isPasswordClear = false;
  bool isProxySettingShown = false;
  bool enableLoginButton = true;

  @override
  void initState() {
    super.initState();
    final oaCredential = Auth.oaCredential;
    if (oaCredential != null) {
      $account.text = oaCredential.account;
      $password.text = oaCredential.password;
    }
  }

  /// 用户点击登录按钮后
  Future<void> onLogin(BuildContext ctx) async {
    bool formValid = (_formKey.currentState as FormState).validate();
    final account = $account.text;
    final password = $password.text;
    if (!formValid || account.isEmpty || password.isEmpty) {
      await ctx.showTip(
        title: i18n.formatError,
        desc: i18n.validateInputAccountPwdRequest,
        ok: i18n.close,
        serious: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() => enableLoginButton = false);
    final connectionType = await Connectivity().checkConnectivity();
    if (connectionType == ConnectivityResult.none) {
      if (!mounted) return;
      setState(() => enableLoginButton = true);
      await ctx.showTip(
        title: i18n.networkError,
        desc: i18n.networkNoAccessTip,
        ok: i18n.close,
        serious: true,
      );
      return;
    }

    try {
      final credential = OACredential(account, password);
      await LoginInit.ssoSession.loginActive(credential);
      final personName = await LoginInit.authServerService.getPersonName();
      Auth.oaCredential = credential;
      Kv.auth.personName = personName;
      // Reset the home
      Kv.home.homeItems = null;
      if (!mounted) return;
      // 后退到就剩一个栈内元素
      final navigator = context.navigator;
      while (navigator.canPop()) {
        navigator.pop();
      }
      navigator.pushReplacementNamed(RouteTable.home);
    } on CredentialsInvalidException catch (e) {
      if (!mounted) return;
      await ctx.showTip(
        title: i18n.loginFailedWarn,
        desc: e.msg,
        ok: i18n.close,
      );
      return;
    } catch (e) {
      if (!mounted) return;
      await ctx.showTip(
        title: i18n.loginFailedWarn,
        desc: i18n.accountOrPwdIncorrectTip,
        ok: i18n.close,
        serious: true,
      );
    } finally {
      if (mounted) {
        setState(() => enableLoginButton = true);
      }
    }
  }

  Widget buildTitleLine() {
    return Container(
        alignment: Alignment.centerLeft,
        child: Text(i18n.loginTitle, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)));
  }

  Widget buildLoginForm(BuildContext ctx) {
    return Form(
      autovalidateMode: AutovalidateMode.always,
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: $account,
            textInputAction: TextInputAction.next,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            validator: studentIdValidator,
            decoration: InputDecoration(
              labelText: i18n.account,
              hintText: i18n.loginLoginAccountHint,
              icon: const Icon(Icons.person),
            ),
          ),
          TextFormField(
            controller: $password,
            autofocus: true,
            textInputAction: TextInputAction.send,
            contextMenuBuilder: (ctx, state) {
              return AdaptiveTextSelectionToolbar.editableText(
                editableTextState: state,
              );
            },
            autocorrect: false,
            enableSuggestions: false,
            obscureText: !isPasswordClear,
            onFieldSubmitted: (inputted) {
              if (enableLoginButton) {
                onLogin(ctx);
              }
            },
            decoration: InputDecoration(
              labelText: i18n.oaPwd,
              hintText: i18n.loginPwdHint,
              icon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(isPasswordClear ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    isPasswordClear = !isPasswordClear;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoginButton(BuildContext ctx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          // Online
          onPressed: enableLoginButton
              ? () {
                  // un-focus the text field.
                  FocusScope.of(context).requestFocus(FocusNode());
                  onLogin(ctx);
                }
              : null,
          child: i18n.loginLoginBtn.text().padAll(5),
        ),
        if (!widget.disableOffline)
          ElevatedButton(
            // Offline
            onPressed: () {
              Navigator.pushReplacementNamed(context, RouteTable.home);
            },
            child: i18n.loginOfflineModeBtn.text().padAll(5),
          ),
      ],
    );
  }

  void _showProxyInput() {
    if (isProxySettingShown) {
      return;
    }
    isProxySettingShown = true;
    $proxy.text = Kv.network.proxy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 40.h,
            left: 10.w,
            child: IconButton(
              icon: Icon(Icons.arrow_back_outlined, size: 35.spMin),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Proxy setting
          Positioned(
            top: 40.h,
            right: 10.w,
            child: IconButton(
              icon: Icon(Icons.settings, size: 35.spMin),
              onPressed: _showProxyInput,
            ),
          ),
          Center(
            child:
                // Create new container and make it center in vertical direction.
                Container(
              width: 1.sw,
              padding: EdgeInsets.fromLTRB(50.w, 0, 50.w, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title field.
                  buildTitleLine(),
                  Padding(padding: EdgeInsets.only(top: 40.h)),
                  // Form field: username and password.
                  buildLoginForm(context),
                  SizedBox(height: 10.h),
                  // Login button.
                  buildLoginButton(context),
                ],
              ).scrolled(physics: const NeverScrollableScrollPhysics()),
            ),
          ),
          [
            TextButton(
              child: Text(
                i18n.loginForgotPwdBtn,
                style: const TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                GlobalLauncher.launch(R.forgotLoginPwdUrl);
              },
            ),
          ]
              .row(mas: MainAxisSize.min)
              .padAll(20)
              .align(at: context.isPortrait ? Alignment.bottomCenter : Alignment.bottomRight),
        ],
      ).safeArea(), //to avoid overflow when keyboard is up.
    );
  }

  @override
  void dispose() {
    super.dispose();
    $account.dispose();
    $password.dispose();
  }
}
