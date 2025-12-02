import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@module
abstract class ConfigModule {
  @lazySingleton
  Dio provideDio() => Dio();
}

