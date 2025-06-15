// استيراد الحزم الضرورية من فلاتر وBloc
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// استيراد ملف واجهة برمجة التطبيقات (API) ونموذج الفئة (Category)
import '../../../../repository/api/api.dart';
import '../../../../repository/models/category.dart';

// ربط ملفات الأحداث (Event) والحالات (State)
part 'live_caty_event.dart';
part 'live_caty_state.dart';

// الكلاس المسؤول عن إدارة الحالة للفئات المباشرة (Live Categories)
class LiveCatyBloc extends Bloc<LiveCatyEvent, LiveCatyState> {
  final IpTvApi api; // متغير API للوصول إلى بيانات IPTV

  // المُنشئ الذي يحدد الحالة الابتدائية (LiveCatyInitial)
  LiveCatyBloc(this.api) : super(LiveCatyInitial()) {
    // التعامل مع الحدث GetLiveCategories عند إطلاقه
    on<GetLiveCategories>((event, emit) async {
      // إرسال حالة التحميل (Loading) عند بدء العملية
      emit(LiveCatyLoading());

      // تنفيذ الطلب من خلال API للحصول على الفئات المباشرة
      final result = await api.getCategories("get_live_categories");

      // إرسال حالة النجاح مع البيانات المسترجعة من API
      emit(LiveCatySuccess(result));
    });
  }
}
