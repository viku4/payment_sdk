class UpiAppModel {
  final String appName;
  final String packageName;

  const UpiAppModel({required this.appName, required this.packageName});

  factory UpiAppModel.fromMap(Map<dynamic, dynamic> map) {
    return UpiAppModel(
      appName: map['appName']?.toString() ?? 'UPI App',
      packageName: map['packageName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'appName': appName, 'packageName': packageName};
  }

  @override
  String toString() {
    return 'UpiAppModel('
        'appName: $appName, '
        'packageName: $packageName'
        ')';
  }
}
