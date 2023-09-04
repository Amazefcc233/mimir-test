import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rettulf/rettulf.dart';
import '../init.dart';
import "../using.dart";

class EduEmailCredentialForm extends StatefulWidget {
  final String? studentId;

  const EduEmailCredentialForm({
    super.key,
    required this.studentId,
  });

  @override
  State<EduEmailCredentialForm> createState() => _EduEmailCredentialFormState();
}

class _EduEmailCredentialFormState extends State<EduEmailCredentialForm> {
  late final TextEditingController $username = TextEditingController(text: widget.studentId);
  final $password = TextEditingController();
  final GlobalKey _formKey = GlobalKey<FormState>();
  bool isPasswordClear = false;
  bool isLoggingIn = false;

  @override
  void dispose() {
    $username.dispose();
    $password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        buildForm(),
        SizedBox(height: 10.h),
        buildLoginButton(),
      ]
          .column(mas: MainAxisSize.min)
          .scrolled(physics: const NeverScrollableScrollPhysics())
          .padH(25.h)
          .center()
          .safeArea(),
      bottomNavigationBar: [
        const ForgotPasswordButton(),
      ].wrap(align: WrapAlignment.center).padAll(10),
    );
  }

  Widget buildForm() {
    return Form(
      autovalidateMode: AutovalidateMode.always,
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: $username,
            textInputAction: TextInputAction.next,
            autofocus: true,
            readOnly: widget.studentId != null,
            autocorrect: false,
            enableSuggestions: false,
            validator: (account) {
              if (account == null) return null;
              return account.isEmpty ? "Email address cannot be empty" : null;
            },
            decoration: InputDecoration(
              labelText: "Email Address",
              hintText: "your Student ID",
              suffixText: "@${R.eduEmailDomain}",
              icon: const Icon(Icons.alternate_email_outlined),
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
            onFieldSubmitted: (inputted) {},
            decoration: InputDecoration(
              labelText: "Password",
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

  Widget buildLoginButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        $username >>
            (ctx, account) => ElevatedButton(
                  // Online
                  onPressed: !isLoggingIn && account.text.isNotEmpty
                      ? () {
                          // un-focus the text field.
                          FocusScope.of(context).requestFocus(FocusNode());
                          onLogin();
                        }
                      : null,
                  child: isLoggingIn ? const LoadingPlaceholder.drop() : i18n.loginBtn.text().padAll(5),
                ),
      ],
    );
  }

  Future<void> onLogin() async {
    final credential = EmailCredential(
      address: R.formatEduEmail(username: $username.text),
      password: $password.text,
    );
    try {
      await EduEmailInit.service.login(credential);
    } catch (err) {
      if (!mounted) return;
      await context.showTip(title: i18n.failedWarn, desc: "please check your pwd", ok: i18n.ok);
      return;
    }
    CredentialInit.storage.eduEmailCredential = credential;
  }
}

const forgotLoginPasswordUrl =
    "http://imap.mail.sit.edu.cn//edu_reg/retrieve/redirect?redirectURL=http://imap.mail.sit.edu.cn/coremail/index.jsp";

class ForgotPasswordButton extends StatelessWidget {
  const ForgotPasswordButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: i18n.forgotPwdBtn.text(
        style: const TextStyle(color: Colors.grey),
      ),
      onPressed: () {
        guardLaunchUrlString(context, forgotLoginPasswordUrl);
      },
    );
  }
}
