part of 'widgets.dart';

class AppBarWelcome extends StatelessWidget {
  const AppBarWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100.w, // ضبط العرض ليكون بعرض الشاشة
      //height: 11.h, // تم التعليق عليه، يمكن استخدامه لضبط الارتفاع
      // margin: EdgeInsets.symmetric(vertical: 7.h, horizontal: 15), // هوامش خارجية اختيارية
      child: Row(
        children: [
          const Image(
            width: 40, // عرض الأيقونة
            height: 40, // ارتفاع الأيقونة
            image: AssetImage(kIconSplash), // مسار صورة الأيقونة
          ),
          const SizedBox(width: 5), // مسافة بين الأيقونة واسم التطبيق
          Text(
            kAppName, // اسم التطبيق
            style: Get.textTheme.headlineMedium, // نمط النص
          ),
          Container(
            width: 1, // عرض الفاصل
            height: 40, // ارتفاع الفاصل
            margin: const EdgeInsets.symmetric(horizontal: 13), // هوامش للفاصل
            color: kColorHint, // لون الفاصل
          ),
          Expanded(
            child: Center(
              child: Text(
                dateNowWelcome(), // التاريخ الحالي
                style: Get.textTheme.titleSmall!.copyWith(
                  color: Colors.white, // لون النص
                  fontWeight: FontWeight.w500, // وزن الخط
                ),
              ),
            ),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                final userInfo = state.user.userInfo; // جلب بيانات المستخدم
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // تاريخ الترحيب كان هنا وتم التعليق عليه
                    Text(
                      "Expiration: ${expirationDate(userInfo!.expDate)}", // عرض تاريخ انتهاء الاشتراك
                      style: Get.textTheme.titleSmall!.copyWith(
                        color: Colors.white, // لون النص
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox(); // عنصر فارغ في حالة عدم تسجيل الدخول
            },
          ),
          IconButton(
            focusColor: kColorFocus, // لون التركيز عند التحديد
            onPressed: () {
              Get.toNamed(screenSettings); // الانتقال إلى صفحة الإعدادات
            },
            icon: Icon(
              FontAwesomeIcons.gear, // أيقونة الترس
              color: Colors.white, // لون الأيقونة
              size: 19.sp, // حجم الأيقونة
            ),
          ),
        ],
      ),
    );
  }
}

class CardWelcomeSetting extends StatelessWidget {
  const CardWelcomeSetting(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap});
  final String title; // عنوان البطاقة
  final IconData icon; // أيقونة البطاقة
  final Function() onTap; // وظيفة عند الضغط

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // تنفيذ الوظيفة عند الضغط
      borderRadius: BorderRadius.circular(20), // الزوايا المستديرة
      focusColor: kColorFocus, // لون التركيز عند التحديد
      child: Row(
        children: [
          Ink(
            width: 7.w, // عرض عنصر الأيقونة
            height: 7.w, // ارتفاع عنصر الأيقونة
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), // زوايا مستديرة
              gradient: const RadialGradient(colors: [
                kColorCardDark,
                kColorCardLight, // تدرج لوني للبطاقة
              ]),
            ),
            child: Center(
              child: Icon(icon), // عرض الأيقونة في منتصف البطاقة
            ),
          ),
          const SizedBox(width: 10), // مسافة بين الأيقونة والنص
          Text(
            title, // عرض العنوان
            style: Get.textTheme.headlineSmall, // نمط النص
          ),
        ],
      ),
    );
  }
}

class CardWelcomeTv extends StatelessWidget {
  const CardWelcomeTv({
    super.key,
    required this.icon,
    required this.onTap,
    required this.title,
    required this.subTitle,
    this.autoFocus = false,
    this.onRefresh,
    this.lastUpdate,
  });
  final String icon; // مسار صورة الأيقونة
  final String title; // عنوان البطاقة
  final String subTitle; // العنوان الفرعي للبطاقة
  final Function() onTap; // الوظيفة عند الضغط
  final Function()? onRefresh; // Function to refresh content
  final DateTime? lastUpdate; // Last update timestamp
  final bool autoFocus; // هل البطاقة تركز تلقائياً

  // Format the last update time
  String get formattedLastUpdate {
    if (lastUpdate == null) return 'Never updated';

    final now = DateTime.now();
    final difference = now.difference(lastUpdate!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastUpdate!.day}/${lastUpdate!.month}/${lastUpdate!.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // تنفيذ الوظيفة عند الضغط
      borderRadius: BorderRadius.circular(30), // الزوايا المستديرة للبطاقة
      focusColor: kColorFocus, // لون التركيز
      autofocus: autoFocus, // تفعيل التركيز التلقائي
      onFocusChange: (value) {}, // الاستجابة لتغيير حالة التركيز
      child: Ink(
        decoration: BoxDecoration(
          color: kColorCardLight, // لون خلفية البطاقة
          borderRadius: BorderRadius.circular(30), // الزوايا المستديرة
        ),
        padding: const EdgeInsets.all(5), // حشوة داخلية
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي للمحتوى
          crossAxisAlignment: CrossAxisAlignment.center, // توسيط أفقي
          children: [
            // Content icon
            Image(
              width: 8.w, // عرض صورة الأيقونة
              image: AssetImage(icon), // مسار الصورة
            ),
            SizedBox(height: 3.h), // مسافة رأسية
            // Title
            Text(
              title, // عنوان البطاقة
              style: Get.textTheme.displaySmall, // نمط العنوان
            ),
            SizedBox(height: 1.h), // مسافة بين العنوان والنص الفرعي
            // Subtitle
            Text(
              "◍ $subTitle", // عرض العنوان الفرعي مع أيقونة صغيرة
              style: Get.textTheme.titleSmall!
                  .copyWith(color: Colors.white70), // نمط النص الفرعي
            ),
            // Last update timestamp and refresh button
            if (onRefresh != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Last update timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Update:',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          formattedLastUpdate,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  ElevatedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kColorPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CardTallButton extends StatelessWidget {
  const CardTallButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.radius = 5,
      this.isLoading = false});
  final String label; // النص داخل الزر
  final Function() onTap; // وظيفة عند الضغط
  final double radius; // الزوايا المستديرة
  final bool isLoading; // هل الزر بحالة تحميل

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        width: 100.w, // عرض الزر بعرض الشاشة
        height: 55, // ارتفاع الزر
        duration: const Duration(milliseconds: 300), // مدة الحركة عند التغيير
        child: ElevatedButton(
          onPressed: onTap, // تنفيذ الوظيفة عند الضغط
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all(kColorPrimary), // لون الزر
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(radius), // الزوايا المستديرة
              ))),
          child: isLoading
              ? LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.white, // لون المؤشر
                  size: 40, // حجم المؤشر
                )
              : Text(
                  label, // النص في الزر
                  style: Get.textTheme.headlineLarge!.copyWith(
                    color: Colors.white, // لون النص
                    fontSize: 16.sp, // حجم الخط
                    fontWeight: FontWeight.bold, // وزن الخط
                  ),
                ),
        ),
      ),
    );
  }
}
