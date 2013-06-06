Ext.ns('AIR2.Upload');
/***************
 * File uploader modal
 *
 * Upload and import a CSV file into the Tank, using a single modal window.
 * Upload and validation will be done synchronously.
 *
 * @cfg {Object} tankRec (optional) tank record to load
 * @cfg {HTMLElement} originEl (optional) origin element to animate from
 *
 */
AIR2.Upload.Modal = function (cfg) {
    var ccls,
        conbtn,
        isDone,
        meta,
        navButtons,
        navHandler,
        navHeader,
        rebtn,
        startStep,
        stepPreview,
        stepSubmit,
        stepUpload,
        subbtn,
        subhandler,
        tip,
        upbtn,
        uphandler,
        w;

    startStep = 1;
    isDone = false;
    if (cfg.tankRec) {
        meta = Ext.decode(cfg.tankRec.data.tank_meta);
        if (meta.valid_file) {
            startStep = 2;
        }
        if (meta.valid_file && meta.valid_header) {
            if (Ext.isDefined(meta.submit_success)) {
                if (meta.submit_success !== null) {
                    startStep = 3;
                }
            }
        }
        if (meta.submit_success === true) {
            isDone = true;
        }
    }

    // navigation handler
    navHandler = function (stepNum) {
        var lm = w.getLayout();
        lm.setActiveItem((stepNum - 1));
        navButtons.setStep(stepNum);
        navHeader.setStep(stepNum);
    };

    // navigation header element
    ccls = ['', '', ''];
    ccls[startStep - 1] = 'current';
    navHeader = new Ext.Toolbar({
        cls: 'nav-header',
        items: {
            xtype: 'box',
            cls: 'steps',
            html: '<span class="fupl ' + ccls[0] + '">File Upload</span>' +
                  '<span>›</span>' +
                  '<span class="prev ' + ccls[1] + '">Preview Data</span>' +
                  '<span>›</span>' +
                  '<span class="subm ' + ccls[2] + '">Submit Event</span>'
        },
        setStep: function (num) {
            var box, el;

            box = navHeader.get(0).el;

            if (num === 1) {
                el = box.first('.fupl');
            }
            if (num === 2) {
                el = box.first('.prev');
            }
            if (num === 3) {
                el = box.first('.subm');
            }
            if (el) {
                el.radioClass('current');
            }
        }
    });

    // navigation button toolbar
    navButtons = new Ext.Toolbar({
        cls: 'nav-buttons',
        setStep: function (num) {
            this.get(0).setVisible(num === 1);
            this.get(1).setVisible(num === 2 || (num === 3 && !isDone));
            this.get(2).setVisible(num === 2);
            this.get(3).setVisible(num === 3 && !isDone);
            this.get(4).setVisible(num === 4 || isDone);

            this.get(0).disable();
            this.get(1).disable();
            this.get(2).disable();
            this.get(3).disable();
        },
        defaults: {
            xtype: 'air2button',
            air2type: 'UPLOAD',
            air2size: 'MEDIUM'
        },
        items: [{
            text: 'Upload & Preview',
            iconCls: 'air2-icon-forward',
            handler: navHandler.createDelegate(this, [2])
        }, {
            text: 'Re-upload',
            iconCls: 'air2-icon-retry',
            handler: navHandler.createDelegate(this, [1])
        }, {
            text: 'Continue',
            iconCls: 'air2-icon-forward',
            handler: navHandler.createDelegate(this, [3])
        }, {
            text: 'Submit',
            iconCls: 'air2-icon-forward',
            handler: navHandler.createDelegate(this, [4])
        }, {
            text: 'Close',
            iconCls: 'air2-icon-forward',
            handler: function () {
                w.close();
            }
        }]
    });
    navButtons.setStep(startStep);

    // upload step
    stepUpload = AIR2.Upload.FileForm();
    upbtn = navButtons.get(0);
    stepUpload.on('fileselected', function (fld, name) {
        var upbtn = navButtons.get(0);
        upbtn.enable();
    });
    uphandler = upbtn.handler; // intercept handler
    upbtn.setHandler(function () {
        stepUpload.doUpload(function (success) {
            upbtn.setDisabled(!success);
            if (success) {
                uphandler();
            }
        });
    });

    // preview step
    stepPreview = AIR2.Upload.PreviewGrid();
    rebtn = navButtons.get(1);
    conbtn = navButtons.get(2);
    stepPreview.on('afterpreview', function (success, resp) {
        rebtn.enable();
        conbtn.setDisabled(!success);
    });

    // submit step
    stepSubmit = AIR2.Upload.Importer();
    subbtn = navButtons.get(3);
    stepSubmit.on('validpoll', function (isValid) {
        rebtn.enable();
        subbtn.setDisabled(!isValid);
    });
    subhandler = subbtn.handler; // intercept handler
    subbtn.setHandler(function () {
        rebtn.disable();
        subbtn.disable();
        stepSubmit.doSubmit(function (success) {
            rebtn.setDisabled(success);
            subbtn.setDisabled(success);
            if (success) {
                subhandler();
            }
        });
    });

    // support article
    tip = AIR2.Util.Tipper.create({id: 20978401, cls: 'lighter', align: 15});

    // the actual modal window
    w = new AIR2.UI.Window({
        title: 'Upload CSV File ' + tip,
        closeAction: 'close',
        iconCls: 'air2-icon-upload',
        cls: 'air2-upload-modal',
        width: 650,
        height: 350,
        layout: 'card',
        layoutConfig: {deferredRender: true},
        activeItem: startStep - 1,
        tbar: navHeader,
        bbar: navButtons,
        items: [stepUpload, stepPreview, stepSubmit]
    });
    w.tankRec = cfg.tankRec;

    if (cfg.originEl) {
        w.show(cfg.originEl);
    }
    else {
        w.show();
    }
    return w;
};
