// _FittedBaselineAdjust_EOArchive.java
// Generated by EnterpriseObjects palette at Thursday, October 28, 2004 4:29:58 PM US/Eastern

import com.webobjects.eoapplication.*;
import com.webobjects.eocontrol.*;
import com.webobjects.eointerface.*;
import com.webobjects.eointerface.swing.*;
import com.webobjects.foundation.*;
import java.awt.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;
import javax.swing.text.*;

public class _FittedBaselineAdjust_EOArchive extends com.webobjects.eoapplication.EOArchive {
    com.webobjects.eointerface.swing.EOForm _nsForm0;
    com.webobjects.eointerface.swing.EOFormCell _eoFormCell0;
    com.webobjects.eointerface.swing.EOFrame _eoFrame0;
    com.webobjects.eointerface.swing.EOMatrix _nsMatrix0;
    com.webobjects.eointerface.swing.EOTextField _nsTextField0;
    com.webobjects.eointerface.swing.EOView _nsBox0, _nsBox1, _nsBox2, _nsBox3;
    javax.swing.JPanel _nsView0;
    javax.swing.JRadioButton _jRadioButton0, _jRadioButton1, _jRadioButton2, _jRadioButton3, _jRadioButton4, _jRadioButton5, _jRadioButton6, _jRadioButton7;

    public _FittedBaselineAdjust_EOArchive(Object owner, NSDisposableRegistry registry) {
        super(owner, registry);
    }

    protected void _construct() {
        Object owner = _owner();
        EOArchive._ObjectInstantiationDelegate delegate = (owner instanceof EOArchive._ObjectInstantiationDelegate) ? (EOArchive._ObjectInstantiationDelegate)owner : null;
        Object replacement;

        super._construct();

        _nsTextField0 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField2");
        _nsForm0 = (com.webobjects.eointerface.swing.EOForm)_registered(new com.webobjects.eointerface.swing.EOForm(1, 1, 1, 2), "");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "windowWidthID")) != null)) {
            _eoFormCell0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOFormCell)replacement;
            _replacedObjects.setObjectForKey(replacement, "_eoFormCell0");
        } else {
            _eoFormCell0 = (com.webobjects.eointerface.swing.EOFormCell)_registered(new com.webobjects.eointerface.swing.EOFormCell(), "");
        }

        _jRadioButton7 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("8"), "");
        _jRadioButton6 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("7"), "");
        _jRadioButton5 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("6"), "");
        _jRadioButton4 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("5"), "");
        _jRadioButton3 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("4"), "");
        _jRadioButton2 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("3"), "");
        _jRadioButton1 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("2"), "");
        _jRadioButton0 = (javax.swing.JRadioButton)_registered(new javax.swing.JRadioButton("1"), "");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "channelSelID")) != null)) {
            _nsMatrix0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOMatrix)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsMatrix0");
        } else {
            _nsMatrix0 = (com.webobjects.eointerface.swing.EOMatrix)_registered(new com.webobjects.eointerface.swing.EOMatrix(2, 4, 0, 3), "");
        }

        _nsBox3 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "");
        _nsBox2 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "");
        _nsBox1 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "inspectorView")) != null)) {
            _nsBox0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOView)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsBox0");
        } else {
            _nsBox0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "Box");
        }

        _eoFrame0 = (com.webobjects.eointerface.swing.EOFrame)_registered(new com.webobjects.eointerface.swing.EOFrame(), "Panel");
        _nsView0 = (JPanel)_eoFrame0.getContentPane();
    }

    protected void _awaken() {
        super._awaken();
        _eoFormCell0.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "registerValue", _eoFormCell0), ""));
        _connect(_eoFrame0, _owner(), "delegate");

        if (_replacedObjects.objectForKey("_eoFormCell0") == null) {
            _connect(_owner(), _eoFormCell0, "windowWidthID");
        }

        if (_replacedObjects.objectForKey("_nsBox0") == null) {
            _connect(_owner(), _nsBox0, "inspectorView");
        }

        if (_replacedObjects.objectForKey("_nsMatrix0") == null) {
            _connect(_owner(), _nsMatrix0, "channelSelID");
        }
    }

    protected void _init() {
        super._init();
        _setFontForComponent(_nsTextField0, "Lucida Grande", 13, Font.PLAIN + Font.BOLD);
        _nsTextField0.setEditable(false);
        _nsTextField0.setOpaque(false);
        _nsTextField0.setText("Settings\n");
        _nsTextField0.setHorizontalAlignment(javax.swing.JTextField.CENTER);
        _nsTextField0.setSelectable(false);
        _nsTextField0.setEnabled(true);
        _nsTextField0.setBorder(null);
        _eoFormCell0.setSize(0, 0);
        _eoFormCell0.setLocation(-1, 0);
        _nsForm0.add(_eoFormCell0);
        _setFontForComponent(_nsForm0, "Helvetica", 12, Font.PLAIN);

        if (_replacedObjects.objectForKey("_eoFormCell0") == null) {
            _setFontForComponent(_eoFormCell0, "Helvetica", 12, Font.PLAIN);
            _eoFormCell0.setTitle("Window Width:");
            _eoFormCell0.setTitleWidth(90);
            _eoFormCell0.fieldComponent().setPreferredSize(new Dimension(2, 20));
            _eoFormCell0.titleComponent().setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        }

        _setFontForComponent(_jRadioButton7, "Helvetica", 12, Font.PLAIN);
        _setFontForComponent(_jRadioButton6, "Helvetica", 12, Font.PLAIN);
        _setFontForComponent(_jRadioButton5, "Helvetica", 12, Font.PLAIN);
        _setFontForComponent(_jRadioButton4, "Helvetica", 12, Font.PLAIN);
        _setFontForComponent(_jRadioButton3, "Helvetica", 12, Font.PLAIN);
        _setFontForComponent(_jRadioButton2, "Helvetica", 12, Font.PLAIN);
        _setFontForComponent(_jRadioButton1, "Helvetica", 12, Font.PLAIN);
        _setFontForComponent(_jRadioButton0, "Helvetica", 12, Font.PLAIN);

        if (_replacedObjects.objectForKey("_nsMatrix0") == null) {
            _jRadioButton0.setSize(37, 18);
            _jRadioButton0.setLocation(0, 0);
            _nsMatrix0.add(_jRadioButton0);
            _jRadioButton1.setSize(37, 18);
            _jRadioButton1.setLocation(37, 0);
            _nsMatrix0.add(_jRadioButton1);
            _jRadioButton2.setSize(37, 18);
            _jRadioButton2.setLocation(74, 0);
            _nsMatrix0.add(_jRadioButton2);
            _jRadioButton3.setSize(37, 18);
            _jRadioButton3.setLocation(111, 0);
            _nsMatrix0.add(_jRadioButton3);
            _jRadioButton4.setSize(37, 18);
            _jRadioButton4.setLocation(0, 21);
            _nsMatrix0.add(_jRadioButton4);
            _jRadioButton5.setSize(37, 18);
            _jRadioButton5.setLocation(37, 21);
            _nsMatrix0.add(_jRadioButton5);
            _jRadioButton6.setSize(37, 18);
            _jRadioButton6.setLocation(74, 21);
            _nsMatrix0.add(_jRadioButton6);
            _jRadioButton7.setSize(37, 18);
            _jRadioButton7.setLocation(111, 21);
            _nsMatrix0.add(_jRadioButton7);
        }

        if (!(_nsBox3.getLayout() instanceof EOViewLayout)) { _nsBox3.setLayout(new EOViewLayout()); }
        _nsMatrix0.setSize(148, 40);
        _nsMatrix0.setLocation(18, 13);
        ((EOViewLayout)_nsBox3.getLayout()).setAutosizingMask(_nsMatrix0, EOViewLayout.MinYMargin);
        _nsBox3.add(_nsMatrix0);
        if (!(_nsBox2.getLayout() instanceof EOViewLayout)) { _nsBox2.setLayout(new EOViewLayout()); }
        _nsBox3.setSize(187, 71);
        _nsBox3.setLocation(2, 17);
        ((EOViewLayout)_nsBox2.getLayout()).setAutosizingMask(_nsBox3, EOViewLayout.MinYMargin);
        _nsBox2.add(_nsBox3);
        _nsBox2.setBorder(new com.webobjects.eointerface.swing._EODefaultBorder("Apply to Channels", true, "Lucida Grande", 12, Font.PLAIN));
        if (!(_nsBox1.getLayout() instanceof EOViewLayout)) { _nsBox1.setLayout(new EOViewLayout()); }
        _nsBox2.setSize(191, 90);
        _nsBox2.setLocation(28, 172);
        ((EOViewLayout)_nsBox1.getLayout()).setAutosizingMask(_nsBox2, EOViewLayout.MinYMargin);
        _nsBox1.add(_nsBox2);
        _nsForm0.setSize(133, 21);
        _nsForm0.setLocation(57, 139);
        ((EOViewLayout)_nsBox1.getLayout()).setAutosizingMask(_nsForm0, EOViewLayout.MinYMargin);
        _nsBox1.add(_nsForm0);
        _nsTextField0.setSize(114, 32);
        _nsTextField0.setLocation(67, 99);
        ((EOViewLayout)_nsBox1.getLayout()).setAutosizingMask(_nsTextField0, EOViewLayout.MinYMargin);
        _nsBox1.add(_nsTextField0);

        if (_replacedObjects.objectForKey("_nsBox0") == null) {
            if (!(_nsBox0.getLayout() instanceof EOViewLayout)) { _nsBox0.setLayout(new EOViewLayout()); }
            _nsBox1.setSize(246, 278);
            _nsBox1.setLocation(2, 16);
            ((EOViewLayout)_nsBox0.getLayout()).setAutosizingMask(_nsBox1, EOViewLayout.MinYMargin);
            _nsBox0.add(_nsBox1);
            _nsBox0.setBorder(new com.webobjects.eointerface.swing._EODefaultBorder("Baseline Adjustment", true, "Helvetica", 12, Font.PLAIN));
        }

        if (!(_nsView0.getLayout() instanceof EOViewLayout)) { _nsView0.setLayout(new EOViewLayout()); }
        _nsBox0.setSize(250, 296);
        _nsBox0.setLocation(54, 12);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsBox0, EOViewLayout.MinYMargin);
        _nsView0.add(_nsBox0);
        _nsView0.setSize(362, 387);
        _eoFrame0.setTitle("Panel");
        _eoFrame0.setLocation(276, 552);
        _eoFrame0.setSize(362, 387);
    }
}