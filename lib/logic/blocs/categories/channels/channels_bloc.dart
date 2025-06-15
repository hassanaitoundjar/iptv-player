// استيراد الحزم الضرورية من فلاتر و Bloc
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:player/helpers/helpers.dart'; // يحتوي على تعريف enum TypeCategory
import 'package:player/repository/models/channel_movie.dart'; // نموذج قنوات الأفلام

// استيراد ملفات API والنماذج الخاصة بالقنوات
import '../../../../repository/api/api.dart';
import '../../../../repository/models/channel_live.dart'; // نموذج قنوات البث المباشر
import '../../../../repository/models/channel_serie.dart'; // نموذج قنوات المسلسلات

// تضمين ملفات الأحداث (Event) والحالات (State)
part 'channels_event.dart';
part 'channels_state.dart';

// كلاس Bloc لإدارة حالات جلب القنوات (بث مباشر، أفلام، مسلسلات)
class ChannelsBloc extends Bloc<ChannelsEvent, ChannelsState> {
  final IpTvApi api; // كائن API لتنفيذ الطلبات

  // المُنشئ الذي يحدد الحالة الابتدائية ويقوم بربط الحدث بالمعالج
  ChannelsBloc(this.api) : super(ChannelsLoading()) {
    // التعامل مع حدث GetLiveChannelsEvent
    on<GetLiveChannelsEvent>((event, emit) async {
      emit(ChannelsLoading()); // عرض حالة التحميل

      // التحقق من نوع الفئة المطلوبة (بث مباشر، أفلام، أو مسلسلات)
      if (event.typeCategory == TypeCategory.live) {
        // إذا كانت الفئة بث مباشر، يتم جلب القنوات المباشرة
        final result = await api.getLiveChannels(event.catyId);
        emit(ChannelsLiveSuccess(result)); // إرسال الحالة مع القنوات
      } else if (event.typeCategory == TypeCategory.movies) {
        // إذا كانت الفئة أفلام، يتم جلب قنوات الأفلام
        final result = await api.getMovieChannels(event.catyId);
        emit(ChannelsMovieSuccess(result)); // إرسال الحالة مع القنوات
      } else if (event.typeCategory == TypeCategory.series) {
        // إذا كانت الفئة مسلسلات، يتم جلب قنوات المسلسلات
        final result = await api.getSeriesChannels(event.catyId);
        emit(ChannelsSeriesSuccess(result)); // إرسال الحالة مع القنوات
      }
    });
  }
}
