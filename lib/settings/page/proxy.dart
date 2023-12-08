import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sit/design/adaptive/dialog.dart';
import 'package:sit/design/adaptive/editor.dart';
import 'package:sit/design/adaptive/foundation.dart';
import 'package:sit/design/widgets/navigation.dart';
import 'package:sit/network/checker.dart';
import 'package:sit/qrcode/page/view.dart';
import 'package:sit/qrcode/protocol.dart';
import 'package:sit/settings/settings.dart';
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
  @override
  Widget build(BuildContext context) {
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
              buildProxyTypeTile(ProxyType.http),
              buildProxyTypeTile(ProxyType.https),
              buildProxyTypeTile(ProxyType.all),
              const Divider(),
              const TestConnectionTile(),
              buildShareQrCode(proxyUri),
            ]),
          ),
        ],
      ),
    );
  }

  Widget buildProxyTypeTile(ProxyType type) {
    return ListTile(
      title: type.toString().text(),
      onTap: () async {
        final profile = await context.show$Sheet$<ProxyProfileRecords>((ctx) => ProxyProfileEditorPage(type: type));
        if (profile != null) {
          Settings.proxy.setProfile(type, profile);
        }
      },
    );
  }

  Widget buildShareQrCode(Uri proxyUri) {
    return ListTile(
      leading: const Icon(Icons.qr_code),
      title: i18n.proxy.shareQrCode.text(),
      subtitle: i18n.proxy.shareQrCodeDesc.text(),
      trailing: IconButton(
        icon: const Icon(Icons.share),
        onPressed: () async {
          final qrCodeData = const ProxyDeepLink().encode(proxyUri);
          context.show$Sheet$(
            (context) => QrCodePage(
              title: i18n.proxy.title.text(),
              data: qrCodeData.toString(),
            ),
          );
        },
      ),
    );
  }
}

class ProxyShareQrCodeTile extends StatelessWidget {
  final (String? http, String? https, String? all) profiles;

  const ProxyShareQrCodeTile({
    super.key,
    required this.profiles,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.qr_code),
      title: i18n.proxy.shareQrCode.text(),
      subtitle: i18n.proxy.shareQrCodeDesc.text(),
      trailing: IconButton(
        icon: const Icon(Icons.share),
        onPressed: () async {
          final qrCodeData = const ProxyDeepLink().encode(proxyUri);
          context.show$Sheet$(
            (context) => QrCodePage(
              title: i18n.proxy.title.text(),
              data: qrCodeData.toString(),
            ),
          );
        },
      ),
    );
  }
}

bool _validateHttpProxy(String? proxy) {
  if (proxy == null) return false;
  return proxy.isNotEmpty;
}

Future<void> onProxyFromQrCode({
  required BuildContext context,
  required Uri profiles,
}) async {
  await _setHttpProxy(profiles.toString());
  await HapticFeedback.mediumImpact();
  if (!context.mounted) return;
  context.showSnackBar(content: i18n.proxy.proxyChangedTip.text());
  context.push("/settings/proxy");
}

class ProxyProfileEditorPage extends StatefulWidget {
  final ProxyType type;

  const ProxyProfileEditorPage({
    super.key,
    required this.type,
  });

  @override
  State<ProxyProfileEditorPage> createState() => _ProxyProfileEditorPageState();
}

class _ProxyProfileEditorPageState extends State<ProxyProfileEditorPage> {
  late final profile = Settings.proxy.resolve(widget.type);
  late var address = profile.address == null ? null : Uri.tryParse(profile.address!);
  late var enabled = profile.enabled;
  late var globalMode = profile.globalMode;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final proxy = Settings.proxy.address;
    final proxyUri = Uri.tryParse(proxy) ?? Uri(scheme: "http", host: "localhost", port: 80);
    final userInfoParts = proxyUri.userInfo.split(":");
    final auth = userInfoParts.length == 2 ? (username: userInfoParts[0], password: userInfoParts[1]) : null;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: widget.type.toString().text(),
          ),
          SliverList.list(children: [
            buildEnableProxyToggle(),
            buildProxyModeSwitcher(),
            buildProxyFullTile(proxyUri),
            const Divider(),
            buildProxyProtocolTile(proxyUri.scheme, (newProtocol) {
              setNewAddress(proxyUri.replace(scheme: newProtocol).toString());
            }),
            buildProxyHostnameTile(proxyUri.host, (newHost) {
              setNewAddress(proxyUri.replace(host: newHost).toString());
            }),
            buildProxyPortTile(proxyUri.port, (newPort) {
              setNewAddress(proxyUri.replace(port: newPort).toString());
            }),
            buildProxyAuthTile(auth, (newAuth) {
              if (newAuth == null) {
                setNewAddress(proxyUri.replace(userInfo: "").toString());
              } else {
                setNewAddress(
                  proxyUri
                      .replace(
                          userInfo: newAuth.password.isNotEmpty
                              ? "${newAuth.username}:${newAuth.password}"
                              : newAuth.username)
                      .toString(),
                );
              }
            }),
          ]),
        ],
      ),
    );
  }

  Widget buildProxyFullTile() {
    return ListTile(
      leading: const Icon(Icons.link),
      title: i18n.proxy.title.text(),
      subtitle: address.toString().text(),
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: address.toString()));
        if (!mounted) return;
        context.showSnackBar(content: i18n.copyTipOf(i18n.proxy.title).text());
      },
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final newFullProxy = await Editor.showStringEditor(
            context,
            desc: i18n.proxy.title,
            initial: address.toString(),
          );
          if (newFullProxy == null) return;
          final newUri = Uri.tryParse(newFullProxy.trim());
          if (newUri != null && newUri.isAbsolute && (newUri.scheme == "http" || newUri.scheme == "https")) {
            if (newUri != address) {
              setState(() {
                address = newUri;
              });
            }
          } else {
            if (!mounted) return;
            context.showTip(
              title: i18n.error,
              desc: i18n.proxy.invalidProxyFormatTip,
              ok: i18n.close,
            );
            return;
          }
        },
      ),
    );
  }

  Widget buildProxyProtocolTile(String protocol, ValueChanged<String> onChanged) {
    return ListTile(
      isThreeLine: true,
      leading: const Icon(Icons.https),
      title: i18n.proxy.protocol.text(),
      subtitle: [
        ChoiceChip(
          label: "HTTP".text(),
          selected: protocol == "http",
          onSelected: (value) {
            onChanged("http");
          },
        ),
        ChoiceChip(
          label: "HTTPS".text(),
          selected: protocol == "https",
          onSelected: (value) {
            onChanged("https");
          },
        ),
      ].wrap(spacing: 4),
    );
  }

  Widget buildProxyHostnameTile(String hostname, ValueChanged<String> onChanged) {
    return ListTile(
      leading: const Icon(Icons.link),
      title: i18n.proxy.hostname.text(),
      subtitle: hostname.text(),
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: hostname));
        if (!mounted) return;
        context.showSnackBar(content: i18n.copyTipOf(i18n.proxy.hostname).text());
      },
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final newHostNameRaw = await Editor.showStringEditor(
            context,
            desc: i18n.proxy.hostname,
            initial: hostname,
          );
          if (newHostNameRaw == null) return;
          final newHostName = newHostNameRaw.trim();
          if (newHostName != hostname) {
            onChanged(newHostName);
          }
        },
      ),
    );
  }

  Widget buildProxyPortTile(int port, ValueChanged<int> onChanged) {
    return ListTile(
      leading: const Icon(Icons.settings_input_component_outlined),
      title: i18n.proxy.port.text(),
      subtitle: port.toString().text(),
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: port.toString()));
        if (!mounted) return;
        context.showSnackBar(content: i18n.copyTipOf(i18n.proxy.port).text());
      },
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final newPort = await Editor.showIntEditor(
            context,
            desc: i18n.proxy.port,
            initial: port,
          );
          if (newPort == null) return;
          if (newPort != port) {
            onChanged(newPort);
          }
        },
      ),
    );
  }

  Widget buildProxyAuthTile() {
    final userInfoParts = proxyUri.userInfo.split(":");
    final auth = userInfoParts.length == 2 ? (username: userInfoParts[0], password: userInfoParts[1]) : null;
    final text = auth != null ? "${auth.username}:${auth.password}" : null;
    return ListTile(
      leading: const Icon(Icons.key),
      title: i18n.proxy.authentication.text(),
      subtitle: text?.text(),
      trailing: [
        if (auth != null)
          IconButton(
            onPressed: () {
              onChanged(null);
            },
            icon: const Icon(Icons.delete),
          ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final newAuth = await showAdaptiveDialog<({String username, String password})>(
              context: context,
              builder: (_) => StringsEditor(
                fields: [
                  (name: "username", initial: auth?.username ?? ""),
                  (name: "password", initial: auth?.password ?? ""),
                ],
                title: i18n.proxy.authentication,
                ctor: (values) => (username: values[0].trim(), password: values[1].trim()),
              ),
            );
            if (newAuth != null && newAuth != auth) {
              $address.value = address
                  .replace(
                      userInfo:
                          newAuth.password.isNotEmpty ? "${newAuth.username}:${newAuth.password}" : newAuth.username)
                  .toString();
            }
          },
        ),
      ].wrap(),
    );
  }

  Widget buildEnableProxyToggle() {
    return ListTile(
      title: i18n.proxy.enableProxy.text(),
      subtitle: i18n.proxy.enableProxyDesc.text(),
      leading: const Icon(Icons.vpn_key),
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (newV) async {
          setState(() {
            enabled = newV;
          });
        },
      ),
    );
  }

  Widget buildProxyModeSwitcher() {
    return ListTile(
      isThreeLine: true,
      leading: const Icon(Icons.public),
      title: i18n.proxy.proxyMode.text(),
      subtitle: [
        ChoiceChip(
          label: i18n.proxy.proxyModeGlobal.text(),
          selected: globalMode,
          onSelected: (value) async {
            setState(() {
              globalMode = true;
            });
          },
        ),
        ChoiceChip(
          label: i18n.proxy.proxyModeSchool.text(),
          selected: !globalMode,
          onSelected: (value) async {
            setState(() {
              globalMode = false;
            });
          },
        ),
      ].wrap(spacing: 4),
      trailing: Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        message: globalMode ? i18n.proxy.proxyModeGlobalTip : i18n.proxy.proxyModeSchoolTip,
        child: const Icon(Icons.info_outline),
      ).padAll(8),
    );
  }
}
