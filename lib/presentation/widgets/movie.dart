part of 'widgets.dart';

class CardChannelMovieItem extends StatelessWidget {
  const CardChannelMovieItem(
      {super.key, required this.onTap, this.title, this.image});
  final Function() onTap;
  final String? title;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      focusColor: kColorFocus,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          color: kColorCardLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: CachedNetworkImage(
                  imageUrl: image ?? "",
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, i, e) {
                    return const SizedBox();
                  },
                  placeholder: (_, i) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                title ?? 'null',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Get.textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardButtonWatchMovie extends StatefulWidget {
  const CardButtonWatchMovie({
    super.key,
    required this.title,
    required this.onTap,
    this.isFocused = false,
    this.hideBorder = false,
    this.isSelected = false,
    this.index,
    this.onFocusChanged,
    this.icon,
  });
  final String title;
  final Function() onTap;
  final bool isFocused;
  final bool hideBorder;
  final bool isSelected;
  final int? index;
  final Function(int?)? onFocusChanged;
  final IconData? icon;

  @override
  State<CardButtonWatchMovie> createState() => _CardButtonWatchMovieState();
}

class _CardButtonWatchMovieState extends State<CardButtonWatchMovie> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        autofocus: widget.isFocused,
        borderRadius: BorderRadius.circular(10),
        onFocusChange: (bool value) {
          if (widget.onFocusChanged != null) {
            widget.onFocusChanged!(widget.index);
          }

          setState(() {
            isFocused = value;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: widget.hideBorder ? null : BorderRadius.circular(10),
            gradient: isFocused || widget.isSelected
                ? const LinearGradient(
                    colors: [kColorPrimary, kColorPrimaryDark],
                  )
                : LinearGradient(
                    colors: [
                      kColorPrimary.withOpacity(.4),
                      kColorPrimaryDark.withOpacity(.4)
                    ],
                  ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          child: Center(
            child: widget.icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title.toUpperCase(),
                      style: isFocused
                          ? Get.textTheme.headlineMedium
                          : Get.textTheme.headlineSmall,
                    ),
                  ],
                )
              : Text(
                  widget.title.toUpperCase(),
                  style: isFocused
                      ? Get.textTheme.headlineMedium
                      : Get.textTheme.headlineSmall,
                ),
          ),
        ),
      ),
    );
  }
}

class CardInfoMovie extends StatelessWidget {
  const CardInfoMovie(
      {super.key,
      required this.hint,
      required this.title,
      required this.icon,
      this.isShowMore = false});
  final String hint;
  final String title;
  final IconData icon;
  final bool isShowMore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15.sp,
              ),
              const SizedBox(width: 5),
              Text(
                hint,
                style: Get.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 3),
          !isShowMore
              ? Text(
                  title,
                  style: Get.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w100,
                  ),
                )
              : ReadMoreText(
                  title,
                  trimLines: 2,
                  colorClickableText: kColorFocus,
                  trimMode: TrimMode.Line,
                  trimCollapsedText: 'more',
                  trimExpandedText: 'less',
                  style: Get.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w100,
                  ),
                  moreStyle: Get.textTheme.headlineSmall!.copyWith(
                    color: kColorFocus,
                  ),
                  lessStyle: Get.textTheme.headlineSmall!.copyWith(
                    color: kColorFocus,
                  ),
                ),
        ],
      ),
    );
  }
}

class CardMovieImageRate extends StatelessWidget {
  const CardMovieImageRate(
      {super.key, required this.image, required this.rate});
  final String image;
  final String rate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: image,
            width: 18.w,
            height: 55.h,
            fit: BoxFit.cover,
            errorWidget: (_, i, e) {
              return Container(
                color: Colors.grey,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        RatingBarIndicator(
          rating: double.tryParse(rate.toString()) ?? 0,
          itemBuilder: (context, index) => const Icon(
            FontAwesomeIcons.solidStar,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: 18.sp,
          direction: Axis.horizontal,
        ),
      ],
    );
  }
}

class CardMovieImagesBackground extends StatefulWidget {
  const CardMovieImagesBackground({super.key, required this.listImages});
  final List<String> listImages;

  @override
  State<CardMovieImagesBackground> createState() =>
      _CardMovieImagesBackgroundState();
}

class _CardMovieImagesBackgroundState extends State<CardMovieImagesBackground> {
  late bool isNotEmpty;
  late int sizeList;
  int indexImage = 0;

  _runAnimation() async {
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      setState(() {
        if ((indexImage + 1) >= sizeList) {
          indexImage = 0;
        } else {
          indexImage = indexImage + 1;
        }
      });
      _runAnimation();
    }
  }

  @override
  void initState() {
    isNotEmpty = widget.listImages.isNotEmpty;

    if (isNotEmpty) {
      sizeList = widget.listImages.length;
      _runAnimation();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!isNotEmpty) {
      return const SizedBox();
    }

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(seconds: 3),
          switchInCurve: Curves.easeIn,
          child: CachedNetworkImage(
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            imageUrl: widget.listImages[indexImage],
            errorWidget: (_, i, e) {
              return const SizedBox();
            },
          ),
        ),
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              end: Alignment.topCenter,
              begin: Alignment.bottomCenter,
              colors: [
                kColorBackDark.withOpacity(1),
                kColorBack.withOpacity(.5),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

///Serie
class CardEpisodeItem extends StatelessWidget {
  const CardEpisodeItem(
      {super.key,
      required this.episode,
      required this.isSelected,
      required this.onFocused,
      required this.onTap,
      required this.index});
  final Episode? episode;
  final bool isSelected;
  final int index;
  final Function(bool) onFocused;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        onFocusChange: onFocused,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                width: isSelected ? 26.w : 25.w,
                height: isSelected ? 35.h : 34.h,
                imageUrl: episode!.info!.movieImage ?? "",
                fit: BoxFit.cover,
                placeholder: (_, i) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorWidget: (_, i, e) {
                  return Opacity(
                    opacity: .7,
                    child: Container(
                      decoration: kDecorBackground,
                      child: const Center(
                        child: Icon(
                          FontAwesomeIcons.image,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode!.info!.name ?? "Episode $index",
                    maxLines: 1,
                    style: Get.textTheme.headlineMedium!.copyWith(
                      fontSize: isSelected ? 18.sp : 17.sp,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    episode!.info!.plot ?? "",
                    maxLines: 3,
                    style: Get.textTheme.titleMedium!.copyWith(
                      color: Colors.grey.shade400,
                      fontSize: 15.sp,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.clock,
                        color: Colors.grey.shade400,
                        size: 16.sp,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        getDurationMovie(episode!.info!.duration),
                        maxLines: 3,
                        style: Get.textTheme.titleMedium!.copyWith(
                          color: Colors.grey.shade400,
                          fontSize: 15.sp,
                        ),
                      ),
                      const Spacer(flex: 2),
                      Icon(
                        FontAwesomeIcons.circlePlay,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        size: isSelected ? 17.sp : 16.sp,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Play",
                        maxLines: 3,
                        style: Get.textTheme.titleMedium!.copyWith(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade400,
                          fontSize: isSelected ? 16.sp : 15.sp,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardSeasonItem extends StatelessWidget {
  const CardSeasonItem({
    super.key,
    required this.number,
    required this.isSelected,
    required this.onFocused,
    required this.onTap,
  });
  final String number;
  final bool isSelected;
  final Function(bool) onFocused;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onFocusChange: onFocused,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 9.h,
              decoration: BoxDecoration(
                color: isSelected ? kColorFocus : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            SizedBox(width: isSelected ? 15 : 10),
            Text(
              '$number SEASONS',
              style: isSelected
                  ? Get.textTheme.headlineMedium
                  : Get.textTheme.titleMedium!.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 17.sp,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
