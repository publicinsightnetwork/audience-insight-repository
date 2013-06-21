/***************
 * Get Localized Value
 *
 *
 * @function AIR2.Inquiry.getLocalizedValue
 *
 * Parses out localized strings from value hashes used in XTemplates
 *
 * @param values XTemplate values hash
 * @param valueKey the key of the value whose localized version you'd like to
 * retrieve.
 */

AIR2.Inquiry.getLocalizedValue = function (values, valueKey) {
    var locale, localeKey, localizedValue, strings;

    localizedValue = '';

    if (values[valueKey]) {
        strings = values[valueKey];
        locale = AIR2.Inquiry.inqStore.getAt(0).get('Locale');
        localeKey = locale.loc_key;

        if (strings[localeKey]) {
            localizedValue = strings[localeKey];
        }
        else {
            //no translation fall back to en_US
            localizedValue = strings.en_US;
        }
    }

    return localizedValue;
};
