import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/screens/onbroading_screen/widget/item_intro_widget.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnbroadingScreen extends StatefulWidget {
  const OnbroadingScreen({super.key});

  @override
  State<OnbroadingScreen> createState() => _OnbroadingScreenState();
}

class _OnbroadingScreenState extends State<OnbroadingScreen> {
  final PageController _pageController = PageController();
  final StreamController<int> _streamController =
      StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      _streamController.add(_pageController.page!.toInt());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: [
              ItemIntroWidget(
                image: 'assets/food_intro.jpg',
                title: 'chán vl',
                decription: 'Mua hàng ngay',
              ),
              ItemIntroWidget(
                image: 'assets/food_intro.jpg',
                title: 'chán vl',
                decription: 'Mua hàng ngay',
              ),
              ItemIntroWidget(
                image: 'assets/food_intro.jpg',
                title: 'chán vl',
                decription: 'Mua hàng ngay',
              ),
            ],
          ),
          Positioned(
              left: 20,
              right: 20,
              bottom: 5,
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: const ExpandingDotsEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      activeDotColor: Color(0xFFFF7622),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StreamBuilder<int>(
                          stream: _streamController.stream,
                          builder: (context, snapshot) {
                            return GestureDetector(
                              onTap: () {
                                if (_pageController.page != 2) {
                                  _pageController.nextPage(
                                      duration:
                                          const Duration(microseconds: 20),
                                      curve: Curves.easeIn);
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const NavigateScreen()),
                                  );
                                }
                              },
                              child: Container(
                                alignment: Alignment.center,
                                height: 50,
                                width: MediaQuery.of(context).size.width * 0.8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7622),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                child: Text(
                                  snapshot.data != 2 ? 'Next' : 'Get Started',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ),
                            );
                          }),
                      const SizedBox(
                        height: 10,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const NavigateScreen()),
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 50,
                          width: MediaQuery.of(context).size.width * 0.8,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 241, 234, 234),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ))
        ],
      ),
    );
  }
}
