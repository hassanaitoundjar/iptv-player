// هذا الملف جزء من ملف channels_bloc.dart الرئيسي
part of 'channels_bloc.dart';

// الكلاس المجرد الأساسي الذي ترث منه جميع حالات Bloc
@immutable
abstract class ChannelsState {}

// الحالة التي تشير إلى أن البيانات يتم تحميلها حاليًا (حالة انتظار)
class ChannelsLoading extends ChannelsState {}

// حالة النجاح عند تحميل قنوات البث المباشر
class ChannelsLiveSuccess extends ChannelsState {
  final List<ChannelLive> channels; // قائمة القنوات المباشرة

  ChannelsLiveSuccess(this.channels); // المُنشئ يستقبل القنوات
}

// حالة النجاح عند تحميل قنوات الأفلام
class ChannelsMovieSuccess extends ChannelsState {
  final List<ChannelMovie> channels; // قائمة قنوات الأفلام

  ChannelsMovieSuccess(this.channels); // المُنشئ يستقبل القنوات
}

// حالة النجاح عند تحميل قنوات المسلسلات
class ChannelsSeriesSuccess extends ChannelsState {
  final List<ChannelSerie> channels; // قائمة قنوات المسلسلات

  ChannelsSeriesSuccess(this.channels); // المُنشئ يستقبل القنوات
}
