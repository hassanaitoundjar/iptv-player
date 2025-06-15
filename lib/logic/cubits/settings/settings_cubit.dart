// استيراد مكتبة Bloc لإدارة الحالة
import 'package:flutter_bloc/flutter_bloc.dart';
// استيراد مكتبة واجهة المستخدم الخاصة بـ Cupertino
import 'package:flutter/cupertino.dart';
// استيراد مكتبة القنوات للتواصل مع كود النظام (Android/iOS)
import 'package:flutter/services.dart';

// تضمين ملف الحالة المرتبطة بـ SettingsCubit
part 'settings_state.dart';

// تعريف قناة MethodChannel للتواصل مع كود النظام الأصلي (Android مثلاً)
const platform = MethodChannel('main_activity_channel');

// الكلاس المسؤول عن إدارة حالة الإعدادات باستخدام Cubit
class SettingsCubit extends Cubit<SettingsState> {
  // الحالة الابتدائية تحتوي على "null" كسلسلة نصية
  SettingsCubit() : super(SettingsState("null"));

  // دالة لجلب الإعدادات من الكود الأصلي (Android مثلاً)
  void getSettingsCode() async {
    try {
      // استدعاء دالة "getData" من الكود الأصلي عبر MethodChannel
      String data = await platform.invokeMethod('getData');

      // طباعة البيانات المستلمة في نافذة التصحيح (debug console)
      debugPrint("DATA: $data");

      // إرسال حالة جديدة تحتوي على البيانات المستلمة
      emit(SettingsState(data));
    } catch (e) {
      // في حالة حدوث خطأ، تتم طباعته في نافذة التصحيح
      debugPrint("Error: $e");
    }
  }
}
