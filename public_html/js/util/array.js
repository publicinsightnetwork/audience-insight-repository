(function () {
    Ext.applyIf(Array.prototype, {
        /**
         * Alternative to Array.indexOf for when index doesn't matter
         * Checks whether or not the specified object exists in the array.
         * @param {Object} o The object to check for
         * @param {Number} from (Optional) The index at which to begin searching
         * @return {Boolean} Whether the object exists in the array
         */
        contains : function (o, from) {
            return (this.indexOf(o, from) > -1);
        }

    });
})();
