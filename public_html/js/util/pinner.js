Ext.ns('AIR2.Util.Pinner');

/**
 *
 * Force a panel to dynamically pin itself
 *
**/
AIR2.Util.Pinner = function (panel, target, offset) {

    panel.air2pinner = {
        init : function (panel, target, offset) {
            this.viewPortOffset = offset || 0;

            this.offsetTarget = target;

            this.panel = panel;

            this.body = Ext.getDoc();


            this.body.on('scroll', this.watchScroll, this);
        },
        resetPanel : function () {
            this.panel.el.scrollTo('top', 0);
            this.panel.el.setStyle('overflow-y', null);

            this.panel.el.setHeight('auto');
            this.originalHeight = this.panel.getHeight();
            this.panel.setWidth('auto');
        },
        resizePanel : function () {
            var panelHeight,
                newElHeight,
                styleSize,
                viewHeight,
                viewSize,
                widthDiff;

            viewHeight = this.body.getViewSize().height - this.viewPortOffset;
            panelHeight = this.panel.el.getHeight();
            newElHeight = viewHeight - this.panel.getFrameHeight();

            if (this.originalHeight && this.originalHeight < viewHeight) {
                this.resetPanel();
            }
            else {
                this.panel.el.setHeight(newElHeight);
                this.panel.el.setStyle('overflow-y', 'scroll');

                // check to see if we added scroll bars
                // and resize the panel as needed
                if (this.panel.el.getWidth() == this.originalWidth) {
                    styleSize = this.panel.el.getStyleSize();
                    viewSize = this.panel.el.getViewSize();

                    widthDiff = styleSize.width - viewSize.width;
                    this.panel.el.setWidth(this.panel.el.getWidth() + widthDiff);
                }
            }

        },
        resetWatcher : function (event, el, config) {
            if (this.panel.el.getY() < this.originalY) {
                this.resetPanel();
                this.panel.el.setStyle({
                    'position' : 'inherit',
                    'top' : null
                });
                Ext.select(window).un('resize', this.resizePanel, this);
                this.body.un('scroll', this.resetWatcher, this);
                this.body.on('scroll', this.watchScroll, this);
            }
        },
        watchScroll : function (event, el, config) {
            var offset,
                y;

            offset = this.panel.el.getOffsetsTo(this.offsetTarget);
            y = offset[1];

            if (y < this.viewPortOffset) {
                this.originalHeight = panel.el.getHeight();
                this.originalWidth = panel.getWidth();

                //probably not visible don't bother pinning
                if (this.originalHeight == 0 || this.originalWidth == 0) {
                    return;
                }

                this.originalY = panel.el.getY();

                //force panel width
                this.panel.setWidth(this.originalWidth);

                this.panel.el.setStyle({'position' : 'fixed', 'top' : '52px'});

                this.resizePanel();
                Ext.select(window).on('resize', this.resizePanel, this);
                this.body.un('scroll', this.watchScroll, this);
                this.body.on('scroll', this.resetWatcher, this);
            }
        }
    };

    panel.air2pinner.init(panel, target, offset);
};
