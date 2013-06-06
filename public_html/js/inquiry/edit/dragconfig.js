/***********************
 * Sets up a drag proxy per the excellent example from
 * http://extjsinaction.com/ Chapter 13
 */
AIR2.Inquiry.QuestionDragConfig = function () {
    var config;

    config = {

        /***********************
         * canDrop:
         * checks to see if we can add this question type to this target
         */
        canDrop : function (event, targetEl) {
            var dragEl, moving, newRec, targetDv;


            dragEl = Ext.get(this.getDragEl());

            newRec = dragEl.newRec;
            targetEl = Ext.get(targetEl);
            targetDv = this.getTargetDataView(targetEl);

            moving = !newRec.phantom;

            if (targetDv.isAllowed(newRec.data, moving)) {
                return true;
            }

            return false;
        },

        /***********************
         * getTargetDataView:
         */
        getTargetDataView : function (targetEl) {
            var targetDataView;

            Ext.each(
                AIR2.Inquiry.QuestionDataViews,
                function (dv) {
                    if (dv.el.contains(targetEl)) {
                        targetDataView = dv;
                    }
                }
            );

            return targetDataView;
        },
        /***********************
         * isBefore:
         * checks to see if the mouse position in event
         * is above the middle of targetEl
         */
        isBefore : function (event, targetEl) {

            //check to see if the mouse is closer to the top or bottom
            //of the drag target
            var centerY;

            centerY = targetEl.getY() + (targetEl.getHeight() / 2);
            return (event.getPageY() < centerY);
        },

        /***********************
         * startDrag:
         * called when this element is dragged
         */
        startDrag : function () {
            var dragEl, el, newRec;

            dragEl = Ext.get(this.getDragEl());
            el = Ext.get(this.getEl());

            dragEl.setOpacity(0.70);
            dragEl.update(el.dom.innerHTML);
            dragEl.setSize(el.getSize());
            dragEl.addClass('air2-tpl-proxy');


            // setup the question rec based on existing rec, or new
            // rec based on a question template

            dragRecId = el.getAttribute('data-record-uuid');

            if (dragRecId) {
                dragRecIndex = AIR2.Inquiry.quesStore.find(
                    'ques_uuid',
                    dragRecId
                );
                newRec = AIR2.Inquiry.quesStore.getAt(dragRecIndex);
//                 newRec = oldRec.copy();
                //generate a new id
//                 Ext.data.Record.id(newRec);
            }
            else {
                tplKey = el.getAttribute('data-air2qtpl');
                newRec = AIR2.Inquiry.createQuestionRecord(tplKey);
            }

            dragEl.newRec = newRec;


            this.originalXY = el.getXY();
        },

        /***********************
         * onDragEnter:
         * called when a proxy is dragged over this element
         */
        onDragEnter : function (event, targetElId) {
            var dragEl, targetEl;

            dragEl = Ext.get(this.getDragEl());
            targetEl = Ext.get(targetElId);

            if (targetEl && this.canDrop(event, targetElId)) {
                dragEl.addClass('go');
                dragEl.removeClass('nogo');
                if  (this.isBefore(event, targetEl)) {
                    targetEl.removeClass('drag-after');
                    targetEl.addClass('drag-before');
                }
                else {
                    targetEl.removeClass('drag-before');
                    targetEl.addClass('drag-after');
                }

                targetEl.addClass('ques-over');

            }
            else {
                dragEl.addClass('nogo');
                dragEl.removeClass('go');
            }
        },

        /***********************
         * onDragOut:
         * called when a proxy is dragged off this element
         */
        onDragOut : function (evtObj, targetElId) {
            var dragEl, targetEl;

            dragEl = Ext.get(this.getDragEl());
            targetEl =  Ext.get(targetElId);

            if (targetEl) {
                targetEl.removeClass('drag-after');
                targetEl.removeClass('drag-before');
                targetEl.removeClass('ques-over');
            }

            if (dragEl) {
                dragEl.removeClass('go');
                dragEl.removeClass('nogo');
            }
        },

        /***********************
         * onDragOver:
         * called when a proxy is dragged around over this element
         */
        onDragOver : function (evtObj, targetElId) {
            var dragEl, targetEl;

            dragEl = Ext.get(this.getDragEl());

            targetEl = Ext.get(targetElId);

            if (targetEl && this.canDrop(evtObj, targetElId)) {
                dragEl.addClass('go');
                dragEl.removeClass('nogo');
                if  (this.isBefore(evtObj, targetEl)) {
                    targetEl.removeClass('drag-after');
                    targetEl.addClass('drag-before');
                }
                else {
                    targetEl.removeClass('drag-before');
                    targetEl.addClass('drag-after');
                }
                targetEl.addClass('ques-over');
            }
            else {
                dragEl.addClass('nogo');
                dragEl.removeClass('go');
            }
        },

        /***********************
         * setupReturn:
         * Called when element needs to be animated back to it's start xy
         * (ie reusable field templates, bad drops etc)
         */
        setupReturn : function () {
            this.shouldReturnProxy = true;
        },

        /***********************
         * onDragDrop:
         * called when a proxy is dropped on this element
         */
        onDragDrop : function (event, targetElId) {
            var dragEl,
                dragRecId,
                dragRecIndex,
                targetEl,
                targetRecId,
                newIndex,
                newRec,
                newSeq,
                oldRecIndex,
                targetDataView,
                targetIndex,
                targetRec,
                targetSeq,
                tplKey;

            dragEl = Ext.get(this.getEl());
            targetEl = Ext.get(targetElId);

            targetDataView = this.getTargetDataView(targetEl);

            if (!dragEl || !targetEl) {
                Logger('bad drop', event, targetElId);
                return false;
            }

            //cleanup the target of the drop
            targetEl.removeClass('drag-after');
            targetEl.removeClass('drag-before');
            targetEl.removeClass('ques-over');

            if (!this.canDrop(event, targetEl)) {
                return false;
            }

            targetRecId = targetEl.getAttribute('data-record-uuid');

            if (targetRecId) {
                targetIndex = AIR2.Inquiry.quesStore.find(
                    'ques_uuid',
                     targetRecId
                );

                targetRec = AIR2.Inquiry.quesStore.getAt(targetIndex);
            }

            // fetch the new rec we made in startDrag
            newRec = Ext.get(this.getDragEl()).newRec;

            if (targetRec) {

                //make sure we're dealing with a number
                targetSeq = parseInt(targetRec.get('ques_dis_seq'), 10);

                if (this.isBefore(event, targetEl)) {
                    newSeq = targetSeq;
                    newIndex = targetIndex;
                }
                else {
                    newSeq = targetSeq + 1;
                    newIndex = targetIndex + 1;
                }

                if (newSeq === 0) {
                    newSeq = 1;
                }
            }
            else {
                if (targetDataView.isPublic === true) {
                    newSeq = 10;
                    newIndex = 10;
                }
                else {
                    newSeq = 100;
                    newIndex = 100;
                }
            }

            newRec.forceSet('ques_dis_seq', newSeq);

            // tell the server to check ordering
            newRec.forceSet('resequence', newSeq);
            newRec.forceSet('ques_public_flag', targetDataView.isPublic);

            oldRecIndex = AIR2.Inquiry.quesStore.find('ques_uuid', newRec.id);

            if (oldRecIndex === -1) {
                AIR2.Inquiry.quesStore.insert(newIndex, newRec);
            }

            AIR2.Inquiry.quesStore.save();

            // send templates back
            if (oldRecIndex === -1) {
                this.setupReturn();
            }
            return true;
        },
        b4EndDrag : Ext.emptyFn,
        endDrag : function () {
            var animCfgObj, dragEl, dragProxy;

            dragProxy = Ext.get(this.getDragEl());
            if (this.shouldReturnProxy === true) {
                dragEl = Ext.get(this.getEl());

                animCfgObj = {
                    easing   : 'easeOut',
                    duration : 0.25,
                    callback : function () {
                        dragProxy.hide();
                        dragEl.highlight();
                    }
                };

                dragProxy.moveTo(
                    this.originalXY[0],
                    this.originalXY[1],
                    animCfgObj
                );
            }
            else {
                dragProxy.hide();
            }
            delete this.shouldReturn;
        }
    };

    return config;
};
