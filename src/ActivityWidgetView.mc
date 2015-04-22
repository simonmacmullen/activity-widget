// -*- mode: Javascript;-*-

using Toybox.Graphics;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.System as System;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class ActivityWidgetView extends Ui.View {
    var mode = "STEPS";

    function cycleView() {
        if (mode.equals("STEPS")) {
            mode = "DISTANCE";
        }
        else if (mode.equals("DISTANCE")) {
            mode = "CALORIES";
        }
        else if (mode.equals("CALORIES")) {
            mode = "STEPS";
        }
        Ui.requestUpdate();
    }

    //! Load your resources here
    function onLayout(dc) {
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

    // For some reason distance is in cm.
    var distanceDivisor =
        (System.getDeviceSettings().distanceUnits == System.UNIT_METRIC) ?
        100000f :
        160900f; // cm in a mile

    //! Update the view
    function onUpdate(dc) {
        var hist = ActivityMonitor.getHistory();
        //hist = fakeHistory();
        var max = 0;
        for (var i = 0; i < hist.size(); i++) {
            if (mode.equals("STEPS")) {
                if (hist[i].steps > max) {
                    max = hist[i].steps;
                }
                if (hist[i].stepGoal > max) {
                    max = hist[i].stepGoal;
                }
            }
            else if (mode.equals("DISTANCE")) {
                if (hist[i].distance > max) {
                    max = hist[i].distance;
                }
            }
            else {
                if (hist[i].calories > max) {
                    max = hist[i].calories;
                }
            }
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(109, 15, Graphics.FONT_XTINY, mode,
                    Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        if (hist.size() == 0) {
            dc.drawText(109, 109, Graphics.FONT_TINY, "NO DATA",
                        Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var x1 = 65;
        var y1 = 40;
        var x2 = 180;
        var y2 = 180;
        
        var x_scale = 1.0 * (x2 - x1) / max;
        var y_scale = (y2 - y1) / hist.size();

        for (var i = 0; i < hist.size(); i++) {
            var y = y1 + y_scale * i;

            var str;
            var data;
            var goal = null;

            if (mode.equals("STEPS")) {
                data = hist[i].steps;
                goal = hist[i].stepGoal;
                str = "" + data;
            }
            else if (mode.equals("DISTANCE")) {
                data = hist[i].distance;
                str = (data / distanceDivisor).format("%.1f");
            }
            else {
                data = hist[i].calories;
                str = "" + data;
            }

            if (goal == null) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1, y, x_scale * data, y_scale - 1);
            }
            else if (data < goal) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1 + x_scale * goal - 1, y, 2, y_scale - 1);
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1, y, x_scale * data, y_scale - 1);
            }
            else {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1, y, x_scale * data, y_scale - 1);
            }
            
            var moment = Time.Gregorian.info(hist[i].startOfDay, Time.FORMAT_LONG);
            var text_y = y - 1;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x1 - 5, text_y, Graphics.FONT_XTINY,
                        moment.day_of_week.substring(0, 1) + " " + moment.day,
                        Graphics.TEXT_JUSTIFY_RIGHT);

            var text_x = x_scale * data;
            var w = dc.getTextWidthInPixels(str, Graphics.FONT_XTINY);
            if (w + 10 > text_x) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x1 + text_x + 5, text_y, Graphics.FONT_XTINY,
                            str, Graphics.TEXT_JUSTIFY_LEFT);
            }
            else {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x1 + text_x - 5, text_y, Graphics.FONT_XTINY,
                            str, Graphics.TEXT_JUSTIFY_RIGHT);            
            }
        }
    }

    function fakeHistory() {
        var h = new [7];
        for (var i = 0; i < 7; i++) {
            var f = new FakeHistory(i);
            h[i] = f;
        }
        return h;
    }
}

class FakeHistory {
    function initialize(dayMinus) {
        calories = 1800 + Math.rand() % 400;
        distance = 100000 + Math.rand() % 1000000;
        stepGoal = 5000 + dayMinus * 1000;
        steps = 5000 + Math.rand() % 5000;
        startOfDay = Time.today().add(new Time.Duration(-86400 * dayMinus));
    }

    var calories;
    var distance;
    var startOfDay;
    var stepGoal;
    var steps;
}

class ActivityWidgetDelegate extends Ui.InputDelegate {
    function onKey(evt) {
        if (evt.getKey() == Ui.KEY_ENTER) {
            widget.cycleView();
            return true;
        }
        return false;
    } 
}

var widget;

class ActivityWidgetApp extends App.AppBase {
    function onStart() {
    }

    function onStop() {
    }

    function getInitialView() {
        widget = new ActivityWidgetView();
        return [widget, new ActivityWidgetDelegate()];
    }
}
