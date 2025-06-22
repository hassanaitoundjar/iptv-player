// هذا الملف جزء من ملف channels_bloc.dart الرئيسي
part of 'channels_bloc.dart';

// تعريف كلاس مجرد (abstract) يمثل الأحداث التي يمكن أن يتعامل معها Bloc
@immutable
abstract class ChannelsEvent {}

// حدث مخصص لطلب جلب القنوات حسب نوع الفئة (بث مباشر، أفلام، مسلسلات)
class GetLiveChannelsEvent extends ChannelsEvent {
  final String catyId; // معرّف الفئة (category ID)
  final TypeCategory typeCategory; // نوع الفئة (live, movies, series)

  // المُنشئ الذي يستقبل النوع ومعرّف الفئة المطلوبة
  GetLiveChannelsEvent({required this.typeCategory, required this.catyId});
}

// حدث مخصص لطلب جلب جميع القنوات المباشرة للبحث العام
class GetAllLiveChannelsEvent extends ChannelsEvent {}

