// استيراد الحزمة الخاصة بـ Cupertino Widgets من Flutter
import 'package:flutter/cupertino.dart';
// استيراد الحزمة للتحكم في إعدادات النظام مثل اتجاه الشاشة
import 'package:flutter/services.dart';
// استيراد مكتبة BLoC لإدارة الحالة
import 'package:flutter_bloc/flutter_bloc.dart';
// استيراد API مخصص لتسجيل الدخول والتسجيل
import 'package:player/repository/api/api.dart';
// استيراد نموذج المستخدم
import 'package:player/repository/models/user.dart';
// استيراد خدمة Firebase المخصصة لحفظ البيانات
import 'package:player/repository/services/firebase_service.dart';
// استيراد خدمة التحقق من انتهاء الاشتراك
import 'package:player/repository/services/expiration_service.dart';

// تضمين ملفات الأحداث والحالات الخاصة بـ BLoC
part 'auth_event.dart';
part 'auth_state.dart';

// تعريف BLoC مخصص للمصادقة (تسجيل الدخول، التسجيل، تسجيل الخروج)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // تعريف متغير للوصول إلى واجهات API
  final AuthApi authApi;
  // إنشاء كائن من خدمة Firebase لتخزين البيانات
  final FirebaseService _firebaseService = FirebaseService();
  // إنشاء كائن من خدمة التحقق من انتهاء الاشتراك
  final ExpirationService _expirationService = ExpirationService();

  // المُنشئ الخاص بـ BLoC ويبدأ بالحالة الابتدائية
  AuthBloc(this.authApi) : super(AuthInitial()) {
    // الاستماع لحدث التسجيل
    on<AuthRegister>((event, emit) async {
      // إصدار حالة التحميل أثناء معالجة التسجيل
      emit(AuthLoading());

      // إرسال بيانات المستخدم إلى API للتسجيل واستلام كائن المستخدم
      final user = await authApi.registerUser(
        event.username,
        event.password,
        event.domain,
        event.username,
        event.playlistName.isNotEmpty ? event.playlistName : event.username,
        playlistPin: event.playlistPin,
      );

      // إذا تم تسجيل المستخدم بنجاح
      if (user != null) {
        // محاولة تخزين بيانات المستخدم في Firebase
        try {
          await _firebaseService.storeUserData(user);
          print('تم إرسال بيانات المستخدم إلى Firebase بنجاح');
        } catch (e) {
          // في حالة حدوث خطأ أثناء التخزين، يُطبع الخطأ لكن لا يتم إيقاف العملية
          print('فشل في تخزين بيانات المستخدم في Firebase: $e');
        }

        // تغيير اتجاه الجهاز إلى الوضع الأفقي
        changeDeviceOrient();
        // انتظار بسيط قبل إصدار الحالة التالية
        await Future.delayed(const Duration(milliseconds: 300));
        // إصدار حالة النجاح مع بيانات المستخدم
        emit(AuthSuccess(user));
      } else {
        // إذا فشل التسجيل، إصدار حالة الفشل برسالة
        emit(AuthFailed("فشل في تسجيل الدخول!!"));
      }
    });

    // الاستماع لحدث جلب بيانات المستخدم المحلي
    on<AuthGetUser>((event, emit) async {
      // إصدار حالة التحميل
      emit(AuthLoading());

      // جلب المستخدم المخزن محليًا
      final localeUser = await LocaleApi.getUser();

      // إذا تم العثور على مستخدم
      if (localeUser != null) {
        // محاولة تحديث وقت تسجيل الدخول الأخير في Firebase
        try {
          if (localeUser.userInfo?.username != null) {
            await _firebaseService
                .updateLastLogin(localeUser.userInfo!.username!);
          }
        } catch (e) {
          // إذا فشلت العملية، لا تؤثر على باقي سير العمل
          print('فشل تحديث وقت تسجيل الدخول في Firebase: $e');
        }

        // التحقق من انتهاء الاشتراك وإظهار إشعار إذا لزم الأمر
        _expirationService.showExpirationNotification(localeUser);

        // تغيير اتجاه الجهاز إلى أفقي
        changeDeviceOrient();
        // إصدار حالة النجاح مع المستخدم المحلي
        emit(AuthSuccess(localeUser));
      } else {
        // إذا لم يتم العثور على مستخدم محلي، إصدار فشل
        emit(AuthFailed("فشل في تسجيل الدخول!!"));
      }
    });

    // الاستماع لحدث تسجيل الخروج
    on<AuthLogOut>((event, emit) async {
      // تنفيذ عملية تسجيل الخروج محليًا
      await LocaleApi.logOut();
      // إعادة اتجاه الجهاز للوضع الرأسي
      changeDeviceOrientBack();
      // إصدار حالة فشل لتشير إلى أن المستخدم خرج
      emit(AuthFailed("تم تسجيل الخروج"));
    });
  }

  // دالة لتغيير اتجاه الجهاز إلى الوضع الأفقي
  void changeDeviceOrient() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // دالة لإعادة اتجاه الجهاز إلى الوضع الرأسي
  void changeDeviceOrientBack() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }
}
