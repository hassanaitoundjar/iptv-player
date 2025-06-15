// هذا الملف جزء من ملف live_caty_bloc.dart الرئيسي
part of 'live_caty_bloc.dart';

// كلاس مجرد يمثل الأحداث التي يمكن أن يتعامل معها LiveCatyBloc
@immutable
abstract class LiveCatyEvent {}

// حدث يتم إطلاقه لطلب جلب الفئات الخاصة بالبث المباشر
class GetLiveCategories extends LiveCatyEvent {}
