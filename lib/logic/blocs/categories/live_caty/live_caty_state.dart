// هذا الملف جزء من ملف live_caty_bloc.dart الرئيسي
part of 'live_caty_bloc.dart';

// كلاس مجرد يمثل جميع الحالات التي يمكن أن يمر بها LiveCatyBloc
@immutable
abstract class LiveCatyState {}

// الحالة الابتدائية قبل تنفيذ أي إجراء
class LiveCatyInitial extends LiveCatyState {}

// الحالة التي تشير إلى أن التطبيق يقوم بتحميل البيانات (انتظار)
class LiveCatyLoading extends LiveCatyState {}

// الحالة التي تشير إلى نجاح جلب الفئات من API
class LiveCatySuccess extends LiveCatyState {
  final List<CategoryModel> categories; // قائمة الفئات التي تم تحميلها

  LiveCatySuccess(this.categories); // المُنشئ يستقبل البيانات المحمّلة
}
