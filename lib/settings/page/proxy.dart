import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mimir/design/adaptive/editor.dart';
import 'package:mimir/design/adaptive/foundation.dart';
import 'package:mimir/global/init.dart';
import 'package:mimir/settings/settings.dart';
import 'package:rettulf/rettulf.dart';
import '../i18n.dart';

class ProxySettingsPage extends StatefulWidget {
  const ProxySettingsPage({
    super.key,
  });

  @override
  State<ProxySettingsPage> createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends State<ProxySettingsPage> {
  late final StreamSubscription<BoxEvent> $address;

  @override
  void initState() {
    $address = Settings.httpProxy.watchHttpProxy().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    $address.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proxy = Settings.httpProxy.address;
    final proxyUri = Uri.tryParse(proxy) ?? Uri(scheme: "http", host: "localhost", port: 80);
    final userInfoParts = proxyUri.userInfo.split(":");
    final auth = userInfoParts.length == 2 ? (username: userInfoParts[0], password: userInfoParts[1]) : null;
    return Scaffold(
      body: CustomScrollView(
        physics: const RangeMaintainingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            snap: false,
            floating: false,
            expandedHeight: 100.0,
            flexibleSpace: FlexibleSpaceBar(
              title: i18n.proxy.title.text(style: context.textTheme.headlineSmall),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              buildEnableProxyToggle(),
              buildProxyFullTile(proxyUri, (newProxy) {
                setNewAddress(newProxy);
              }),
              const Divider(),
              buildProxyProtocolTile(proxyUri.scheme, (newProtocol) {
                setNewAddress(proxyUri.replace(scheme: newProtocol));
              }),
              buildProxyHostnameTile(proxyUri.host, (newHost) {
                setNewAddress(proxyUri.replace(host: newHost));
              }),
              buildProxyPortTile(proxyUri.port, (newPort) {
                setNewAddress(proxyUri.replace(port: newPort));
              }),
              buildProxyAuthTile(auth, (newAuth) {
                if (newAuth == null) {
                  setNewAddress(proxyUri.replace(userInfo: ""));
                } else {
                  setNewAddress(proxyUri.replace(
                      userInfo:
                          newAuth.password.isNotEmpty ? "${newAuth.username}:${newAuth.password}" : newAuth.username));
                }
              }),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> setNewAddress(Uri uri) async {
    final old = Settings.httpProxy.address;
    final newAddress = uri.toString();
    if (old != newAddress) {
      Settings.httpProxy.address = newAddress;
      // TODO: subscribe the proxy changes instead of directly calling init.
      await Init.init();
    }
  }

  Widget buildEnableProxyToggle() {
    return Settings.httpProxy.listenEnableHttpProxy() >>
        (ctx, _) => ListTile(
              title: i18n.proxy.enableProxyTitle.text(),
              subtitle: i18n.proxy.enableProxyDesc.text(),
              leading: const Icon(Icons.vpn_key),
              trailing: Switch.adaptive(
                value: Settings.httpProxy.enableHttpProxy,
                onChanged: validateHttpProxy(Settings.httpProxy.address)
                    ? (newV) async {
                        Settings.httpProxy.enableHttpProxy = newV;
                        await Init.init();
                      }
                    : null,
              ),
            );
  }

  Widget buildProxyProtocolTile(String protocol, ValueChanged<String> onChanged) {
    return ListTile(
      leading: const Icon(Icons.https),
      title: i18n.proxy.protocol.text(),
      subtitle: protocol.text(),
      trailing: SegmentedButton<String>(
        selected: {protocol},
        segments: [
          ButtonSegment(value: "http", label: "HTTP".text(), icon: const Icon(Icons.http)),
          ButtonSegment(value: "https", label: "HTTPS".text(), icon: const Icon(Icons.https)),
        ],
        onSelectionChanged: (newSelection) {
          onChanged(newSelection.first);
        },
      ),
    );
  }

  Widget buildProxyFullTile(Uri proxyUri, ValueChanged<Uri> onChanged) {
    return ListTile(
      leading: const Icon(Icons.link),
      title: i18n.proxy.title.text(),
      subtitle: proxyUri.toString().text(),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final newHostName = await Editor.showStringEditor(
            context,
            desc: i18n.proxy.address,
            initial: proxyUri.toString(),
          );
        },
      ),
    );
  }

  Widget buildProxyHostnameTile(String hostname, ValueChanged<String> onChanged) {
    return ListTile(
      leading: const Icon(Icons.link),
      title: i18n.proxy.address.text(),
      subtitle: hostname.text(),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final newHostName = await Editor.showStringEditor(
            context,
            desc: i18n.proxy.address,
            initial: hostname,
          );
          onChanged(newHostName);
        },
      ),
    );
  }

  Widget buildProxyPortTile(int port, ValueChanged<int> onChanged) {
    return ListTile(
      leading: const Icon(Icons.settings_input_component_outlined),
      title: i18n.proxy.port.text(),
      subtitle: port.toString().text(),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final newPort = await Editor.showIntEditor(
            context,
            desc: i18n.proxy.port,
            initial: port,
          );
          onChanged(newPort);
        },
      ),
    );
  }

  Widget buildProxyAuthTile(
    ({String username, String password})? credentials,
    ValueChanged<({String username, String password})?> onChanged,
  ) {
    final text = credentials != null ? "${credentials.username}:${credentials.password}" : null;

    return ListTile(
      leading: const Icon(Icons.key),
      title: i18n.proxy.authentication.text(),
      subtitle: text?.text(),
      trailing: [
        if (credentials != null)
          IconButton(
            onPressed: () {
              onChanged(null);
            },
            icon: const Icon(Icons.clear),
          ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final newAuth = await context.show$Dialog$<({String username, String password})>(
                make: (_) => StringsEditor(
                      fields: [
                        (name: "username", initial: credentials?.username ?? ""),
                        (name: "password", initial: credentials?.password ?? ""),
                      ],
                      title: i18n.proxy.authentication,
                      ctor: (values) => (username: values[0], password: values[1]),
                    ));
            if (newAuth != null) {
              onChanged(newAuth);
            }
          },
        ),
      ].wrap(),
    );
  }
}

bool validateHttpProxy(String? proxy) {
  if (proxy == null) return false;
  return proxy.isNotEmpty;
}