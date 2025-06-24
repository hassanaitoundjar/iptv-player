part of '../screens.dart'; // تضمين هذا الملف كجزء من ملف screens.dart الرئيسي

class LiveCategoriesScreen extends StatefulWidget {
  // تعريف واجهة من نوع Stateful لأنها تحتاج لإدارة الحالة
  const LiveCategoriesScreen({super.key}); // مُنشئ بدون مفتاح خاص

  @override
  State<LiveCategoriesScreen> createState() =>
      _LiveCategoriesScreenState(); // إنشاء الحالة الخاصة بالواجهة
}

class _LiveCategoriesScreenState extends State<LiveCategoriesScreen> {
  final ScrollController _hideButtonController =
      ScrollController(); // متحكم بالتمرير لاستخدامه في إظهار/إخفاء الزر العائم
  bool _hideButton = true; // متغير لتحديد ما إذا كان الزر العائم مخفي أم لا
  String keySearch = ""; // متغير لتخزين قيمة البحث

  @override
  void initState() {
    // إضافة مستمع لحركة التمرير لتحديد اتجاه التمرير
    _hideButtonController.addListener(() {
      if (_hideButtonController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        // إذا كان التمرير للأسفل
        if (_hideButton == true) {
          setState(() {
            _hideButton = false; // إخفاء الزر العائم
          });
        }
      } else {
        if (_hideButtonController.position.userScrollDirection ==
            ScrollDirection.forward) {
          // إذا كان التمرير للأعلى
          if (_hideButton == false) {
            setState(() {
              _hideButton = true; // إظهار الزر العائم
            });
          }
        }
      }
    });
    super.initState(); // استدعاء التهيئة الأساسية
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // بناء واجهة التطبيق باستخدام Scaffold
      floatingActionButton: Visibility(
        // إظهار أو إخفاء الزر العائم بناءً على التمرير
        visible: !_hideButton, // إظهار الزر فقط إذا كان _hideButton = false
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _hideButtonController.animateTo(
                0, // التمرير إلى الأعلى عند الضغط على الزر
                duration: const Duration(milliseconds: 400),
                curve: Curves.ease,
              );
              _hideButton = true; // تحديث الحالة لإخفاء الزر بعد العودة للأعلى
            });
          },
          backgroundColor: kColorPrimaryDark, // لون خلفية الزر
          child: const Icon(
            FontAwesomeIcons.chevronUp, // رمز السهم لأعلى
            color: Colors.white, // لون الرمز
          ),
        ),
      ),
      body: Stack(
        // استخدام Stack لترتيب العناصر فوق بعضها
        alignment: Alignment.bottomCenter, // محاذاة العناصر أسفل الشاشة
        children: [
          Ink(
            // عنصر حاوية للخلفية بتأثير حبر
            width: 100.w, // عرض بنسبة 100% من الشاشة
            height: 100.h, // ارتفاع بنسبة 100% من الشاشة
            decoration: kDecorBackground, // تعيين خلفية مخصصة
            child: NestedScrollView(
              // ScrollView يمكن أن يحتوي على رأس ومحتوى
              controller: _hideButtonController, // التحكم بالتمرير
              headerSliverBuilder: (_, ch) {
                return [
                  SliverAppBar(
                    // شريط علوي يمكن أن يتم تمريره مع المحتوى
                    automaticallyImplyLeading:
                        false, // إخفاء زر الرجوع التلقائي
                    elevation: 0, // بدون ظل
                    backgroundColor: Colors.transparent, // شفاف
                    flexibleSpace: FlexibleSpaceBar(
                      background: AppBarLive(
                        // مكون يحتوي على شريط بحث مخصص
                        onSearch: (String value) {
                          // دالة يتم تنفيذها عند كتابة نص في شريط البحث
                          setState(() {
                            keySearch = value
                                .toLowerCase(); // تحديث كلمة البحث وتحويلها لحروف صغيرة
                          });
                          debugPrint(
                            "search :$keySearch",
                          ); // طباعة كلمة البحث للمطور
                        },
                      ),
                    ),
                  ),
                ];
              },
              body: BlocBuilder<LiveCatyBloc, LiveCatyState>(
                // الاستماع لتغير حالة Bloc للفئات
                builder: (context, state) {
                  if (state is LiveCatyLoading) {
                    // إذا كانت البيانات قيد التحميل
                    return const Center(
                      child: CircularProgressIndicator(),
                    ); // إظهار مؤشر تحميل
                  } else if (state is LiveCatySuccess) {
                    // عند نجاح تحميل البيانات
                    final categories =
                        state.categories; // الحصول على قائمة الفئات

                    // فلترة الفئات حسب كلمة البحث
                    List<CategoryModel> searchCaty = categories
                        .where(
                          (element) => element.categoryName!
                              .toLowerCase()
                              .contains(keySearch),
                        ) // مطابقة الاسم مع كلمة البحث
                        .toList();

                    return GridView.builder(
                      // عرض الفئات داخل شبكة
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 0,
                        bottom: 80,
                      ),
                      itemCount: keySearch.isNotEmpty
                          ? searchCaty
                              .length // إذا كان هناك بحث، نعرض النتائج فقط
                          : categories.length, // إذا لا يوجد بحث، نعرض الكل
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // عدد الأعمدة
                        crossAxisSpacing: 10, // المسافة بين الأعمدة
                        mainAxisSpacing: 10, // المسافة بين الصفوف
                        childAspectRatio: 4.8, // نسبة عرض إلى ارتفاع العنصر
                      ),
                      itemBuilder: (_, i) {
                        final model = keySearch.isNotEmpty
                            ? searchCaty[i] // العنصر حسب البحث
                            : categories[i]; // أو العنصر الكامل

                        // Wrap the category card with parental control
                        return ParentalControlWrapper(
                          contentName: model.categoryName ?? "",
                          isCategory: true,
                          child: CardLiveItem(
                            // عنصر بطاقة لعرض الفئة
                            title: model.categoryName ?? "", // اسم الفئة
                            onTap: () {
                              // عند الضغط، الانتقال إلى شاشة القنوات الخاصة بالفئة
                              Get.to(
                                () => LiveChannelsScreen(
                                  catyId: model.categoryId ?? '',
                                ),
                              ); // تمرير معرف الفئة
                            },
                          ),
                        );
                      },
                    );
                  }

                  return const Center(
                    // في حال فشل تحميل البيانات
                    child: Text("Failed to load data..."), // رسالة فشل
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
