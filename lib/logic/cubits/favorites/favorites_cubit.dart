// استيراد حزمة Bloc الخاصة بفلاتر
import 'package:flutter_bloc/flutter_bloc.dart';

// استيراد API والنماذج الخاصة بالقنوات (بث مباشر، أفلام، مسلسلات)
import '../../../repository/api/api.dart';
import '../../../repository/models/channel_live.dart';
import '../../../repository/models/channel_movie.dart';
import '../../../repository/models/channel_serie.dart';

// تضمين ملف الحالة الخاص بـ FavoritesCubit
part 'favorites_state.dart';

// كلاس FavoritesCubit لإدارة المفضلة (قنوات وأفلام ومسلسلات)
class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoriteLocale
  favoriteLocale; // كائن مسؤول عن حفظ واسترجاع البيانات محليًا

  // المُنشئ يبدأ بالحالة الافتراضية (قوائم فارغة)
  FavoritesCubit(this.favoriteLocale) : super(FavoritesState.defaultData());

  // جلب البيانات المحفوظة محليًا عند بدء التطبيق
  void initialData() async {
    emit(
      FavoritesState(
        series: await favoriteLocale.getFavSeries(), // المسلسلات المفضلة
        movies: await favoriteLocale.getFavMovies(), // الأفلام المفضلة
        lives: await favoriteLocale.getFavLives(), // القنوات المباشرة المفضلة
      ),
    );
  }

  // إضافة أو حذف فيلم من المفضلة
  void addMovie(ChannelMovie? value, {required bool isAdd}) async {
    final oldList = state.movies; // القائمة الحالية
    List<ChannelMovie> newList = List.of(oldList); // إنشاء نسخة منها

    if (isAdd) {
      newList.insert(0, value!); // إضافة الفيلم في أول القائمة
    } else {
      // حذف الفيلم بناءً على streamId
      newList = oldList
          .where((movie) => movie.streamId != value!.streamId)
          .toList();
    }

    await favoriteLocale.saveFavoriteMovie(newList); // حفظ التغييرات محليًا

    // إرسال الحالة الجديدة بعد التعديل
    emit(
      FavoritesState(movies: newList, lives: state.lives, series: state.series),
    );
  }

  // إضافة أو حذف مسلسل من المفضلة
  void addSerie(ChannelSerie? value, {required bool isAdd}) async {
    final oldList = state.series;
    List<ChannelSerie> newList = List.of(oldList);

    if (isAdd) {
      newList.insert(0, value!);
    } else {
      newList = oldList
          .where((serie) => serie.seriesId != value!.seriesId)
          .toList();
    }

    await favoriteLocale.saveFavoriteSerie(newList);

    emit(
      FavoritesState(series: newList, movies: state.movies, lives: state.lives),
    );
  }

  // إضافة أو حذف قناة بث مباشر من المفضلة
  void addLive(ChannelLive? value, {required bool isAdd}) async {
    final oldList = state.lives;
    List<ChannelLive> newList = List.of(oldList);

    if (isAdd) {
      newList.insert(0, value!);
    } else {
      newList = oldList
          .where((live) => live.streamId != value!.streamId)
          .toList();
    }

    await favoriteLocale.saveFavoriteLives(newList);

    emit(
      FavoritesState(
        lives: newList,
        series: state.series,
        movies: state.movies,
      ),
    );
  }
}
