import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:player/repository/models/channel_movie.dart';

import '../models/category.dart';
import '../models/channel_live.dart';
import '../models/channel_serie.dart';
import '../models/epg.dart';
import '../models/movie_detail.dart';
import '../models/serie_details.dart';
import '../models/user.dart';
import '../models/watching.dart';

part '../locale/locale.dart';
part 'auth.dart';
part 'iptv.dart';
part '../locale/favorites.dart';

// Configure Dio with appropriate settings for IPTV API requests
final _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  followRedirects: true,
  maxRedirects: 5,
  validateStatus: (status) {
    return status != null && status < 500; // Accept all status codes less than 500
  },
));
final locale = GetStorage();
final favoritesLocale = GetStorage("favorites");
