import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _initialPage = 1000;

  final PageController _controller = PageController(initialPage: _initialPage);
  int _currentClass = 0;

  final List<ClassItem> _classes = const [
    ClassItem(
      day: 'Lunes',
      title: 'Desarrollo de Software',
      time: '2:00 p. m. - 6:00 p. m.',
      place: 'Aula 301 - Bloque B',
    ),
    ClassItem(
      day: 'Martes',
      title: 'Base de datos',
      time: '8:00 a. m. - 12:00 p. m.',
      place: 'Ambiente TIC 3',
    ),
    ClassItem(
      day: 'Miercoles',
      title: 'Programacion movil',
      time: '1:00 p. m. - 5:00 p. m.',
      place: 'Laboratorio 2',
    ),
    ClassItem(
      day: 'Jueves',
      title: 'Proyecto formativo',
      time: '7:00 a. m. - 11:00 a. m.',
      place: 'Ambiente 207',
    ),
    ClassItem(
      day: 'Viernes',
      title: 'Pruebas de software',
      time: '9:00 a. m. - 12:00 p. m.',
      place: 'Laboratorio QA',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inicio',
                style: TextStyle(
                  color: Color(0xFF092444),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Resumen de tu jornada academica',
                style: TextStyle(
                  color: Color(0xFF607086),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 168,
                child: ScrollConfiguration(
                  behavior: const _CarouselScrollBehavior(),
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) {
                      setState(() {
                        _currentClass = index % _classes.length;
                      });
                    },
                    itemBuilder: (context, index) {
                      final classIndex = index % _classes.length;

                      return _ClassCard(
                        item: _classes[classIndex],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_classes.length, (index) {
                  final isActive = index == _currentClass;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isActive ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF39A900)
                          : const Color(0xFFD4DCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselScrollBehavior extends MaterialScrollBehavior {
  const _CarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.item});

  final ClassItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${item.day} - Proxima clase',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF607086),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF092444),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF607086),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF607086),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ClassItem {
  const ClassItem({
    required this.day,
    required this.title,
    required this.time,
    required this.place,
  });

  final String day;
  final String title;
  final String time;
  final String place;
}
