import 'package:flutter/material.dart';

import 'web_utils.dart';

Widget createButton(
  Function onPressed, {
  String title,
  TextAlign align = TextAlign.start,
  IconData iconData,
  Color regularColor,
  Color hoverColor,
  Color textColor,
}) {
  return HoverButton(
      onPressed, title, align, iconData, regularColor, hoverColor, textColor);
}

class HoverButton extends StatefulWidget {
  Function onPressed;
  final String title;
  TextAlign align;
  IconData iconData;
  Color regularColor;
  Color hoverColor;
  Color textColor = Colors.white;

  HoverButton(this.onPressed, this.title, this.align, this.iconData,
      this.regularColor, this.hoverColor, this.textColor);

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (e) => hover(true),
        onExit: (e) => hover(false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          child: Row(
              children: [
            widget.iconData == null ? null : Icon(widget.iconData, color: Colors.black,),
            (widget.iconData != null && widget.title != null)
                ? SizedBox(
                    width: 20,
                  )
                : null,
            widget.title == null
                ? null
                : Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
//              fontWeight: FontWeight.w800,
                      color: widget.textColor,
                      decoration: TextDecoration.none,
                    ),
                  )
          ].where((element) => element != null).toList()),
          decoration: BoxDecoration(
            color: _hovering ? widget.hoverColor : widget.regularColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  hover(bool hovering) {
    setCursor(hovering);
    setState(() {
      _hovering = hovering;
    });
  }
}