import 'package:flutter/material.dart';

const kAlertHeight = 80.0;

enum AlertPriority {
  error(2),
  warning(1),
  info(0);

  const AlertPriority(this.value);
  final int value;
}

class Alert extends StatelessWidget {
  const Alert({
    super.key,
    required this.backgroundColor,
    required this.child,
    required this.leading,
    required this.priority,
  });

  final Color backgroundColor;
  final Widget child;
  final Widget leading;
  final AlertPriority priority;

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;
    return Material(
      child: Ink(
        color: backgroundColor,
        height: kAlertHeight + statusbarHeight,
        child: Column(
          children: [
            SizedBox(height: statusbarHeight),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 28.0),
                  IconTheme(
                    data: const IconThemeData(
                      color: Colors.white,
                      size: 36,
                    ),
                    child: leading,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28.0),
          ],
        ),
      ),
    );
  }
}

class AlertMessenger extends StatefulWidget {
  const AlertMessenger({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AlertMessenger> createState() => AlertMessengerState();

  static AlertMessengerState of(BuildContext context) {
    try {
      final scope = _AlertMessengerScope.of(context);
      return scope.state;
    } catch (error) {
      throw FlutterError.fromParts(
        [
          ErrorSummary('No AlertMessenger was found in the Element tree'),
          ErrorDescription(
              'AlertMessenger is required in order to show and hide alerts.'),
          ...context.describeMissingAncestor(
              expectedAncestorType: AlertMessenger),
        ],
      );
    }
  }
}

class AlertMessengerState extends State<AlertMessenger>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  Alert? alertWidget;
  List<Alert> minorPriorityAlertWidget = [];

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alertHeight = MediaQuery.of(context).padding.top + kAlertHeight;
    animation = Tween<double>(begin: -alertHeight, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool showAlert({required Alert alert}) {
    generatePriorityList(alert);
    if (alert.priority.value == 0 &&
        (alertWidget?.priority.value == 2 ||
            alertWidget?.priority.value == 1)) {
      return false;
    } else if (alert.priority.value == 1 &&
        (alertWidget?.priority.value == 2)) {
      return false;
    } else if (alert.priority.value == 2 &&
        (alertWidget?.priority.value == 2)) {
      return false;
    } else {
      setState(() {
        alertWidget = alert;
      });
      minorPriorityAlertWidget
          .removeWhere((element) => element.priority == alertWidget!.priority);
      controller.forward();
      return true;
    }
  }

  generatePriorityList(Alert alert) {
    if (alert.priority.value == 2) {
      minorPriorityAlertWidget.insert(0, alert);
    } else if (alert.priority.value == 1) {
      if (minorPriorityAlertWidget.isEmpty) {
        minorPriorityAlertWidget.add(alert);
      } else {
        List<Alert> priorities = minorPriorityAlertWidget
            .where((element) => element.priority.value != 2)
            .toList();
        int index = priorities.isNotEmpty
            ? minorPriorityAlertWidget.indexOf(priorities.last)
            : minorPriorityAlertWidget.length;
        minorPriorityAlertWidget.insert(index, alert);
      }
    } else {
      if (minorPriorityAlertWidget.isNotEmpty) {
        List<Alert> priorities = minorPriorityAlertWidget
            .where((element) =>
                element.priority.value != 1 && element.priority.value != 2)
            .toList();
        int index = priorities.isNotEmpty
            ? minorPriorityAlertWidget.indexOf(priorities.last)
            : minorPriorityAlertWidget.length;
        minorPriorityAlertWidget.insert(index, alert);
      } else {
        minorPriorityAlertWidget.insert(0, alert);
      }
    }
  }

  Future<String> hideAlert() async {
    controller.reverse();
    if (minorPriorityAlertWidget.isNotEmpty) {
      alertWidget = null;
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() => alertWidget = minorPriorityAlertWidget[0]);
      minorPriorityAlertWidget.removeAt(0);
      controller.forward();
      return getText(alertWidget!);
    } else {
      alertWidget = null;
      return 'Não existem alertas a serem exibidos.';
    }
  }

  getText(Alert alert) {
    switch (alert.priority) {
      case AlertPriority.error:
        return 'Oops, ocorreu um erro. Pedimos desculpas.';
      case AlertPriority.warning:
        return 'Atenção! Você foi avisado.';
      case AlertPriority.info:
        return 'Este é um aplicativo escrito em Flutter.';
      default:
        return 'Não existem alertas a serem exibidos.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final position = animation.value + kAlertHeight;
        return Stack(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          children: [
            Positioned.fill(
              top: position <= statusbarHeight ? 0 : position - statusbarHeight,
              child: _AlertMessengerScope(
                state: this,
                child: widget.child,
              ),
            ),
            Positioned(
              top: animation.value,
              left: 0,
              right: 0,
              child: alertWidget ?? const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _AlertMessengerScope extends InheritedWidget {
  const _AlertMessengerScope({
    required this.state,
    required super.child,
  });

  final AlertMessengerState state;

  @override
  bool updateShouldNotify(_AlertMessengerScope oldWidget) =>
      state != oldWidget.state;

  static _AlertMessengerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AlertMessengerScope>();
  }

  static _AlertMessengerScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No _AlertMessengerScope found in context');
    return scope!;
  }
}
