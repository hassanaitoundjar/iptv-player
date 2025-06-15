// هذا الملف جزء من ملف favorites_cubit.dart الرئيسي
part of 'favorites_cubit.dart';

/*
// هذا الكلاس كان مجردًا من قبل ويُستخدم مع Bloc بشكل عام
// ولكن تم استبداله بكلاس عادي في هذا المشروع
@immutable
abstract class FavoritesState {}
*/

// الكلاس الذي يمثل حالة المفضلة (يحتوي على القنوات المفضلة بأنواعها)
class FavoritesState {
  final List<ChannelMovie> movies; // قائمة أفلام المفضلة
  final List<ChannelSerie> series; // قائمة مسلسلات المفضلة
  final List<ChannelLive> lives; // قائمة بث مباشر المفضلة

  // المُنشئ الرئيسي الذي يمرر القوائم الثلاث المطلوبة
  FavoritesState({
    required this.movies,
    required this.series,
    required this.lives,
  });

  // مُصنع (Factory) يُستخدم لتوفير حالة افتراضية عند بدء التطبيق
  factory FavoritesState.defaultData() {
    return FavoritesState(
      series: const [], // مسلسلات فارغة
      movies: const [], // أفلام فارغة
      lives: const [], // بث مباشر فارغ
    );
  }
}
