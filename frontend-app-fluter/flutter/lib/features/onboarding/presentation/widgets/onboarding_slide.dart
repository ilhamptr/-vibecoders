import 'package:flutter/material.dart';

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.card,
    required this.title,
    required this.description,
  });

  final Widget card;
  final String title;
  final String description;
}

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.data});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 62),
          SizedBox(
            height: data.title == 'Wujudkan Rencana Tanam'
                ? 444
                : data.title == 'Ikuti Setiap Perkembangan'
                ? 444
                : 444,
            child: Align(alignment: Alignment.topCenter, child: data.card),
          ),
          const SizedBox(height: 18),
          Transform.translate(
            offset: Offset(
              0,
              data.title == 'Wujudkan Rencana Tanam'
                  ? 58
                  : data.title == 'Ikuti Setiap Perkembangan'
                  ? 58
                  : 58,
            ),
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF20252B),
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF969696),
                      fontSize: 16,
                      height: 1.28,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
