with open('ios/Runner.xcodeproj/project.pbxproj', 'r') as file:
    filedata = file.read()

# CODE_SIGN_IDENTITY所在行进行替换更改，变为CODE_SIGN_IDENTITY = "Apple Distribution";
filedata = filedata.replace('CODE_SIGN_IDENTITY = "Apple Development";', 'CODE_SIGN_IDENTITY = "Apple Distribution";')

# CODE_SIGN_STYLE所在行进行替换更改，变为CODE_SIGN_STYLE = Manual;
filedata = filedata.replace('CODE_SIGN_STYLE = Automatic;', 'CODE_SIGN_STYLE = Manual;')

# DEVELOPMENT_TEAM所在行进行替换更改，变为DEVELOPMENT_TEAM = "6MZL7DZ5BQ";
filedata = filedata.replace('DEVELOPMENT_TEAM = "";', 'DEVELOPMENT_TEAM = "6MZL7DZ5BQ";')

# PROVISIONING_PROFILE_SPECIFIER所在行进行替换更改，变为PROVISIONING_PROFILE_SPECIFIER = "SITLife-Distribution-AppStore";
filedata = filedata.replace('PROVISIONING_PROFILE_SPECIFIER = "";', 'PROVISIONING_PROFILE_SPECIFIER = "SITLife-Distribution-AppStore";')

# 文件替换完成后，写回到文件中
with open('ios/Runner.xcodeproj/project.pbxproj', 'w') as file:
    file.write(filedata)
