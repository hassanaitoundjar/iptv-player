// استيراد جزء من ملفات الشاشة
part of '../screens.dart';

// تعريف واجهة الشاشة LiveChannelsScreen كودجت ذات حالة (Stateful)
class LiveChannelsScreen extends StatefulWidget {
  const LiveChannelsScreen({super.key, required this.catyId});
  final String catyId; // معرّف الفئة المستخدمة لعرض القنوات الحية

  @override
  State<LiveChannelsScreen> createState() => _ListChannelsScreen();
}

// الحالة المرتبطة بشاشة LiveChannelsScreen
class _ListChannelsScreen extends State<LiveChannelsScreen> {
  VlcPlayerController? _videoPlayerController; // المتحكم في مشغل الفيديو VLC

  int? selectedVideo; // رقم الفيديو المحدد
  String? selectedStreamId; // معرف البث المباشر المحدد
  ChannelLive? channelLive; // القناة الحالية المحددة
  double lastPosition = 0.0; // آخر موقع تم الوصول إليه في الفيديو
  String keySearch = ""; // مفتاح البحث عن القنوات
  final FocusNode _remoteFocus = FocusNode(); // عنصر التركيز للتحكم عن بعد

  // دالة لتهيئة تشغيل الفيديو من خلال معرف البث
  _initialVideo(String streamId) async {
    // استدعاء بيانات المستخدم من التخزين المحلي
    UserModel? user = await LocaleApi.getUser();

    // إذا تم تهيئة المشغل مسبقاً، نقوم بإيقافه أولاً
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.pause(); // إيقاف مؤقت
      _videoPlayerController!.stop(); // إيقاف كامل
      _videoPlayerController = null;
      await Future.delayed(const Duration(milliseconds: 300)); // تأخير بسيط
    } else {
      _videoPlayerController = null;
      setState(() {}); // تحديث واجهة المستخدم
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // توليد رابط تشغيل الفيديو
    var videoUrl =
        "${user!.serverInfo!.serverUrl}/${user.userInfo!.username}/${user.userInfo!.password}/$streamId";

    debugPrint("Load Video: $videoUrl"); // طباعة الرابط في وحدة التصحيح

    // إعداد المتحكم الجديد لمشغل الفيديو باستخدام VLC
    _videoPlayerController = VlcPlayerController.network(
      videoUrl,
      hwAcc: HwAcc.full, // استخدام تسريع العتاد الكامل
      autoPlay: true, // التشغيل التلقائي
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000), // التخزين المؤقت للشبكة
          VlcAdvancedOptions.liveCaching(2000), // التخزين المؤقت للبث المباشر
        ]),
        http: VlcHttpOptions([
          VlcHttpOptions.httpReconnect(true), // إعادة الاتصال تلقائياً
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true), // استخدام بروتوكول RTSP
        ]),
      ),
    );
    setState(() {}); // إعادة بناء الواجهة لعرض المشغل
  }

  @override
  void initState() {
    // عند بدء الشاشة، نطلب القنوات الحية من Bloc باستخدام معرف الفئة
    context.read<ChannelsBloc>().add(GetLiveChannelsEvent(
          catyId: widget.catyId,
          typeCategory: TypeCategory.live,
        ));
    super.initState();
  }

  @override
  void dispose() async {
    _remoteFocus.dispose(); // تحرير التحكم في التركيز
    super.dispose();
    // إذا كان المشغل مفعلاً، نوقفه ونتخلص منه بشكل آمن
    if (_videoPlayerController != null) {
      await _videoPlayerController!.stopRendererScanning();
      await _videoPlayerController!.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام BlocBuilder لمراقبة حالة الفيديو من VideoCubit
    return BlocBuilder<VideoCubit, VideoState>(
      builder: (context, stateVideo) {
        return WillPopScope(
          // معالجة زر الرجوع
          onWillPop: () async {
            debugPrint("Back pressed"); // طباعة عند الضغط على الرجوع
            if (stateVideo.isFull) {
              // إذا كان الفيديو بوضع ملء الشاشة، نعيده للحجم الطبيعي
              context.read<VideoCubit>().changeUrlVideo(false);
              return Future.value(false); // منع الرجوع
            } else {
              return Future.value(true); // السماح بالرجوع
            }
          },
          // مراقبة حالة تسجيل الدخول من AuthBloc
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, stateAuth) {
              if (stateAuth is AuthSuccess) {
                final userAuth = stateAuth.user; // استخراج بيانات المستخدم

                return Scaffold(
                  body: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Ink(
                        width: 100.w,
                        height: 100.h,
                        decoration: kDecorBackground,
                        // padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 10),
                        child: Column(
                          children: [
                            Builder(
                              builder: (context) {
                                if (stateVideo.isFull) {
                                  return const SizedBox();
                                }
                                return WillPopScope(
                                  onWillPop: () async {
                                    debugPrint("Back pressed");
                                    if (stateVideo.isFull) {
                                      context
                                          .read<VideoCubit>()
                                          .changeUrlVideo(false);
                                      return Future.value(false);
                                    } else {
                                      return Future.value(true);
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 3.h),
                                      BlocBuilder<FavoritesCubit,
                                          FavoritesState>(
                                        builder: (context, state) {
                                          final isLiked = channelLive == null
                                              ? false
                                              : state.lives
                                                  .where((live) =>
                                                      live.streamId ==
                                                      channelLive!.streamId)
                                                  .isNotEmpty;
                                          return AppBarLive(
                                            isLiked: isLiked,
                                            onLike: channelLive == null
                                                ? null
                                                : () {
                                                    context
                                                        .read<FavoritesCubit>()
                                                        .addLive(channelLive,
                                                            isAdd: !isLiked);
                                                  },
                                            onSearch: (String value) {
                                              setState(() {
                                                keySearch = value;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      bool setFull = stateVideo.isFull;
                                      if (setFull) {
                                        return const SizedBox();
                                      }
                                      return Expanded(
                                        child: BlocBuilder<ChannelsBloc,
                                            ChannelsState>(
                                          builder: (context, state) {
                                            if (state is ChannelsLoading) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            } else if (state
                                                is ChannelsLiveSuccess) {
                                              final categories = state.channels;

                                              List<ChannelLive> searchList =
                                                  categories
                                                      .where((element) =>
                                                          element.name!
                                                              .toLowerCase()
                                                              .contains(
                                                                  keySearch))
                                                      .toList();

                                              return GridView.builder(
                                                padding: const EdgeInsets.only(
                                                  left: 10,
                                                  right: 10,
                                                  bottom: 80,
                                                ),
                                                itemCount: keySearch.isEmpty
                                                    ? categories.length
                                                    : searchList.length,
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      selectedVideo == null
                                                          ? 2
                                                          : 1,
                                                  mainAxisSpacing: 10,
                                                  crossAxisSpacing:
                                                      selectedVideo == null
                                                          ? 10
                                                          : 0,
                                                  childAspectRatio: 7,
                                                ),
                                                itemBuilder: (_, i) {
                                                  final model =
                                                      keySearch.isEmpty
                                                          ? categories[i]
                                                          : searchList[i];

                                                  final link =
                                                      "${userAuth.serverInfo!.serverUrl}/${userAuth.userInfo!.username}/${userAuth.userInfo!.password}/${model.streamId}";

                                                  return CardLiveItem(
                                                    title: model.name ?? "",
                                                    image: model.streamIcon,
                                                    link: link,
                                                    isSelected: selectedVideo ==
                                                            null
                                                        ? false
                                                        : selectedVideo == i,
                                                    onTap: () async {
                                                      try {
                                                        if (selectedVideo ==
                                                                i &&
                                                            _videoPlayerController !=
                                                                null) {
                                                          // OPEN FULL SCREEN
                                                          debugPrint(
                                                              "///////////// OPEN FULL STREAM /////////////");
                                                          context
                                                              .read<
                                                                  VideoCubit>()
                                                              .changeUrlVideo(
                                                                  true);
                                                        } else {
                                                          ///Play new Stream
                                                          debugPrint(
                                                              "Play new Stream");

                                                          _initialVideo(model
                                                              .streamId
                                                              .toString());

                                                          if (mounted) {
                                                            setState(() {
                                                              selectedVideo = i;
                                                              channelLive =
                                                                  model;
                                                              selectedStreamId =
                                                                  model
                                                                      .streamId;
                                                            });
                                                          }
                                                        }
                                                      } catch (e) {
                                                        debugPrint("error: $e");
                                                        //  context.read<VideoCubit>().changeUrlVideo(false);

                                                        // selectedVideo = null;
                                                        _videoPlayerController =
                                                            null;
                                                        setState(() {
                                                          channelLive = model;
                                                          selectedStreamId =
                                                              model.streamId;
                                                        });
                                                      }
                                                    },
                                                  );
                                                },
                                              );
                                            }

                                            return const Center(
                                              child: Text(
                                                  "Failed to load data..."),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  if (selectedVideo != null)
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: StreamPlayerPage(
                                              controller:
                                                  _videoPlayerController,
                                            ),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              if (stateVideo.isFull) {
                                                return const SizedBox();
                                              }

                                              ///Get EPG
                                              return CardEpgStream(
                                                  streamId: selectedStreamId);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const Scaffold();
            },
          ),
        );
      },
    );
  }
}

class CardEpgStream extends StatelessWidget {
  const CardEpgStream({super.key, required this.streamId});
  final String? streamId;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: streamId == null
          ? const SizedBox()
          : FutureBuilder<List<EpgModel>>(
              future: IpTvApi.getEPGbyStreamId(streamId ?? ""),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final list = snapshot.data;

                return Container(
                  decoration: const BoxDecoration(
                      color: kColorCardLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                      )),
                  margin: const EdgeInsets.only(top: 10),
                  child: ListView.separated(
                    itemCount: list!.length,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    itemBuilder: (_, i) {
                      final model = list[i];
                      String description =
                          utf8.decode(base64.decode(model.description ?? ""));

                      String title =
                          utf8.decode(base64.decode(model.title ?? ""));
                      return CardEpg(
                        title:
                            "${getTimeFromDate(model.start ?? "")} - ${getTimeFromDate(model.end ?? "")} - $title",
                        description: description,
                        isSameTime: checkEpgTimeIsNow(
                            model.start ?? "", model.end ?? ""),
                      );
                    },
                    separatorBuilder: (_, i) {
                      return const SizedBox(
                        height: 10,
                      );
                    },
                  ),
                );
              }),
    );
  }
}

class CardEpg extends StatelessWidget {
  const CardEpg(
      {super.key,
      required this.title,
      required this.description,
      required this.isSameTime});
  final String title;
  final String description;
  final bool isSameTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Get.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
            color: isSameTime ? kColorPrimaryDark : Colors.white,
          ),
        ),
        Text(
          description,
          style: Get.textTheme.bodyMedium!.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
