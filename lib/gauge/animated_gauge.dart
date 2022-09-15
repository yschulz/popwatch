import 'package:flutter/material.dart';
import 'package:popwatch/gauge/gauge_driver.dart';
import 'package:popwatch/gauge/gauge_painter.dart';

class AnimatedGauge extends StatefulWidget {

    const AnimatedGauge({
        required Key key,
        required this.driver
    }) : super(key: key);

    final GaugeDriver driver;

    @override
    GaugeState createState() => GaugeState();

}

class GaugeState extends State<AnimatedGauge> with SingleTickerProviderStateMixin {

    late Animation<double> _animation;
    late AnimationController _controller;

    double begin = 0.0;
    double end = 0.0;

    @override
    void initState() {

        super.initState();
        _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
        widget.driver.listen(on);
    }

    void on(dynamic x) => setState(() {
        begin = end; 
        end = x;
    });

    @override
    Widget build(BuildContext context) {

        final double _diameter = (MediaQuery.of(context).size.width);

        _controller.reset();
        _animation = Tween<double>(begin: begin, end: end).animate(_controller);
        _animation.addStatusListener((status) {
            if (status == AnimationStatus.completed) { begin = end; }
        });
          
        _controller.forward();

        return AnimatedBuilder(

            animation: _animation, 
            builder: (context, widget)  {

                return CustomPaint(
                        
                    foregroundPainter: GaugePainter(percent: _animation.value),
                    child: 
                    Container(
                        constraints: BoxConstraints.expand(height: 30, width: 0.8*_diameter),
                    )
                );
            }
        );
	  }
  }