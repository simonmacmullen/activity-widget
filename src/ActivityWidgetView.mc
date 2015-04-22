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
        (System.getDeviceSettings().paceUnits == System.UNIT_METRIC) ?
        100000f :
        160900f; // cm in a mile


    //! Update the view
    function onUpdate(dc) {
        var hist = ActivityMonitor.getHistory();
        //hist = fakeHistory();
        var max = 0;
        for (var i = 0; i < hist.size(); i++) {
            if (hist[i].steps > max) {
                max = hist[i].steps;
            }
            if (hist[i].stepGoal > max) {
                max = hist[i].stepGoal;
            }
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(109, 15, Graphics.FONT_XTINY, mode,
                    Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        var x1 = 65;
        var y1 = 40;
        var x2 = 180;
        var y2 = 180;
        
        var x_scale = 1.0 * (x2 - x1) / max;
        var y_scale = (y2 - y1) / hist.size();

        for (var i = 0; i < hist.size(); i++) {
            var y = y1 + y_scale * i;
            var steps = hist[i].steps;
            var goal = hist[i].stepGoal;
            if (steps < goal) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1 + x_scale * goal - 1, y, 2, y_scale - 1);
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1, y, x_scale * steps, y_scale - 1);
            }
            else {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1, y, x_scale * steps, y_scale - 1);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x1 + x_scale * goal - 1, y, 1, y_scale - 1);
            }
            
            var info = Time.Gregorian.info(hist[i].startOfDay, Time.FORMAT_LONG);
            var text_y = y - 1;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x1 - 5, text_y, Graphics.FONT_XTINY,
                        info.day_of_week.substring(0, 1) + " " + info.day,
                        Graphics.TEXT_JUSTIFY_RIGHT);

            var text_x = x_scale * steps;
            var str = "";
            if (mode.equals("STEPS")) {
                str = "" + steps;
            }
            else if (mode.equals("DISTANCE")) {
                str = (hist[i].distance / distanceDivisor).format("%.1f");
            }
            else if (mode.equals("CALORIES")) {
                str = "" + hist[i].calories;
            }
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
        calories = 2000;
        distance = 100000;
        stepGoal = 10000 - dayMinus * 1000;
        steps = dayMinus * 2000;
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
