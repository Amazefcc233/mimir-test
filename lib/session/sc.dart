import 'package:dio/dio.dart';

import '../network/session.dart';

class Class2ndSession extends ISession {
  final ISession _session;

  Class2ndSession(this._session);

  Future<void> _refreshCookie() async {
    await _session.request(
      'https://authserver.sit.edu.cn/authserver/login?service=http%3A%2F%2Fsc.sit.edu.cn%2Flogin.jsp',
      ReqMethod.get,
    );
  }

  bool _isRedirectedToLoginPage(String data) {
    return data.startsWith('<script');
  }

  @override
  Future<Response> request(
    String url,
    ReqMethod method, {
    Map<String, String>? para,
    data,
    SessionOptions? options,
    SessionProgressCallback? onSendProgress,
    SessionProgressCallback? onReceiveProgress,
  }) async {
    Future<Response> fetch() async {
      return await _session.request(
        url,
        method,
        para: para,
        data: data,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    }

    Response response = await fetch();
    // 如果返回值是登录页面，那就从 SSO 跳转一次以登录.
    if (_isRedirectedToLoginPage(response.data as String)) {
      await _refreshCookie();
      response = await fetch();
    }
    return response;
  }
}
