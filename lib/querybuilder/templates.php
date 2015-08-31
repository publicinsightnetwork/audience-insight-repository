<?php
define('MYSQL_TEXT_SIZE', 65535);
define('MYSQL_INT_SIZE', 2147483647);

/**
 * Define templates for querybuilder questions.
 *
 * The configurations should start with a character-only key (this will be
 * POSTed to create a new question from that template).
 *
 * Valid parameters for each template (starred are required):
 * *display         - UI display value for this template
 * *display_group           - UI value to help group types of templates together
 *  ques_value      - Default text label for this question
 *  ques_choices    - Default choices for answering this question - applies
 *                    only to certain ques_types
 * *ques_type       - Which type of UI input will be used to collect the
 *                    answer to this question
 *                    @see Question::$TYPE
 * *ques_public_flag- If a src_response_set is set to public, this field
 *                    determines which responses to which questions are
 *                    considered public within the response set.
 * *ques_resp_type  - Which kind of response data can be expected - field
 *                    validators rely on this parameter
 *                    @see Question::$DTYPE
 *  ques_resp_opts  - Options which apply to this specific resp_type. Will be
 *                    editable once copied to the question, though the
 *                    question's settings. Valid options are:
 *                        require - force a response to the question
 *                                  (default false)
 *                        minlen  - for string data, specify a min-length
 *                        maxlen  - for string data, specify a max-length
 *                        minnum  - for numeric data, specify a minimum
 *                        maxnum  - for numeric data, specify a maximum
 *                        intnum  - for numeric data, restrict to integers
 *  ques_locks      - Determines if some of the question's fields and options
 *                    will be locked and non-editable after creation.  These
 *                    fields default to being unlocked if not included in this
 *                    list.  Valid lock options are:
 *                        ques_value
 *                        ques_choices
 *                        ques_public_flag
 *                        require
 *                        minlen
 *                        maxlen
 *                        minnum
 *                        maxnum
 *                        intnum
 *  ques_pmap_id    - Optionally set the profile_mapping id for a piece of the
 *                    source profile that responses to this question will
 *                    map to.
 *
 */
$qb_templates = array(
    /*
     * generic template types
     */
    'textbox' => array(
        'display'           =>  array(
            'en_US' => 'Single-line text',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Single-line text',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'minlen'        => null,
            'maxlen'        => MYSQL_TEXT_SIZE,
        ),
        'single_instance'   => false,
    ),
    'textarea' => array(
        'display'           =>  array(
            'en_US' => 'Paragraph text',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Paragraph text',
        ),
        'ques_type'         => Question::$TYPE_TEXTAREA,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'minlen'        => null,
            'maxlen'        => MYSQL_TEXT_SIZE,
        ),
        'single_instance'   => false,
    ),
    'number' => array(
        'display'           =>  array(
            'en_US' => 'Number',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Number',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_NUMBER,
        'ques_resp_opts'    => array(
            'require'       => false,
            'minnum'        => 0,
            'maxnum'        => MYSQL_INT_SIZE,
            'intnum'        => true,
        ),
        'single_instance'   => false,
    ),
    'dropdown' => array(
        'display'           =>  array(
            'en_US' => 'Drop-down list',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Drop-down list',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'Choice 1'),
                array('value' => 'Choice 2'),
                array('value' => 'Choice 3'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_DROPDOWN,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'single_instance'   => false,
    ),
    'checks' => array(
        'display'           =>  array(
            'en_US' => 'Checkboxes',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Checkboxes',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'Choice 1'),
                array('value' => 'Choice 2'),
                array('value' => 'Choice 3'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_CHECKS,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'direction'     => Question::$DIRECTION_VERTICAL,
            'require'       => false,
        ),
        'single_instance'   => false,
    ),
    'radios' => array(
        'display'           =>  array(
            'en_US' => 'Radio Buttons',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Radio Buttons',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'Choice 1'),
                array('value' => 'Choice 2'),
                array('value' => 'Choice 3'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_RADIO,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'direction'     => Question::$DIRECTION_VERTICAL,
            'require'       => false,
        ),
        'single_instance'   => false,
    ),
    'multipick' => array(
        'display'           =>  array(
            'en_US' => 'Choice List',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Choice List',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'Choice 1'),
                array('value' => 'Choice 2'),
                array('value' => 'Choice 3'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_LISTMULT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'single_instance'   => false,
    ),
    'date' => array(
        'display'           =>  array(
            'en_US' => 'Date',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Date',
        ),
        'ques_type'         => Question::$TYPE_DATE,
        'ques_resp_type'    => Question::$DTYPE_DATE,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'single_instance'   => false,
    ),
    'fileupload' => array(
        'display'           =>  array(
            'en_US' => 'File upload',
        ),
        'display_group'     => 'generic',
        'display_tip'       => array(
            'en_US' => 'Acceptable file types are jpg, jpeg, gif, png, and pdf',
        ),
        'ques_value'        =>  array(
            'en_US' => 'File upload (accepted types: jpg, jpeg, gif, png, and pdf)',
        ),
        'ques_type'         => Question::$TYPE_FILE,
        'ques_resp_type'    => Question::$DTYPE_FILE,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'single_instance'   => true,
    ),
    'link' => array(
        'display'           =>  array(
            'en_US' => 'URL',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'URL',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_URL,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'single_instance'   => false,
    ),
    'break' => array(
        'display'           =>  array(
            'en_US' => 'Section break',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => '',
        ),
        'ques_type'         => Question::$TYPE_BREAK,
        'single_instance'   => false,
    ),
    'display' => array(
        'display'           =>  array(
            'en_US' => 'Display Text',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Display Text',
        ),
        'ques_type'         => Question::$TYPE_DISPLAY,
        'single_instance'   => false,
    ),
    'hidden' => array(
        'display'           =>  array(
            'en_US' => 'Hidden input',
        ),
        'display_group'     => 'generic',
        'ques_value'        =>  array(
            'en_US' => 'Hidden input',
        ),
        'ques_type'         => Question::$TYPE_TEXT_HIDDEN,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'minlen'        => null,
            'maxlen'        => MYSQL_TEXT_SIZE,
        ),
        'ques_locks'        => array('require'),
        'single_instance'   => false,
    ),
    /*
     * demographic templates
     */
    'gender' => array(
        'display'           =>  array(
            'en_US' => 'Gender',
            'es_US' => 'Género',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'What is your gender? (No need for traditional labels, choose the words that you prefer.)',
            'es_US' => '¿Cuál es su género? (No hay necesidad de usar etiquetas tradiciones, escoja las palabras que usted prefiere.)',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 255,
        ),
        'ques_locks'        => array('maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_GENDER,
        'single_instance'   => true,
    ),
    'birth' => array(
        'display'           =>  array(
            'en_US' => 'Birth year',
            'es_US' => 'Año de Nacimiento',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'In what year were you born?',
            'es_US' => '¿En qué año nació?',
        ),
        'ques_type'         => Question::$TYPE_PICK_DROPDOWN,
        'ques_resp_type'    => Question::$DTYPE_YEAR,
        'ques_resp_opts'    => array(
            'require'           => false,
            'startyearoffset'   => 116,
            'endyearoffset'     => 13,
            'order'             => 'desc',
        ),
        'ques_locks'        => array('ques_choices', 'minnum', 'maxnum', 'isint'),
        'ques_pmap_id'      => ProfileMap::$SRC_BIRTH,
        'single_instance'   => true,
    ),
    'income' => array(
        'display'           =>  array(
            'en_US' => 'Household income',
            'es_US' => 'Ingreso por hogar',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'What is your household income?',
            'es_US' => '¿Cuál es el ingreso de los miembros de su hogar?',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'Less than $15,000'),
                array('value' => '$15,000-$25,000'),
                array('value' => '$25,001-$50,000'),
                array('value' => '$50,001-$100,000'),
                array('value' => '$100,001-$200,000'),
                array('value' => 'more than $200,000'),
            ),
            'es_US' => array(
                array('value' => 'Menos de $15,000'),
                array('value' => '$15,000-$25,000'),
                array('value' => '$25,001-$50,000'),
                array('value' => '$50,001-$100,000'),
                array('value' => '$100,001-$200,000'),
                array('value' => 'Más de $200,000'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_DROPDOWN,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'ques_locks'        => array('ques_choices'),
        'ques_pmap_id'      => ProfileMap::$SRC_INCOME,
        'single_instance'   => true,
    ),
    'ethnicity' => array(
        'display'           =>  array(
            'en_US' => 'Race/ethnicity',
            'es_US' => 'Raza/Etnicidad',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'How do you describe your race or ethnicity? (No need for traditional labels, choose the words that you prefer. The US Census uses both race and ethnicity, which is why we have chosen these words as well.)',
            'es_US' => '¿Cómo describe su raza o etnicidad? (No hay necesidad de usar etiquetas tradicionales, escoja las palabras que prefiera. El Censo de los Estados Unidos usa las palabras raza y etnicidad, por eso las hemos usado también.)',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 255,
        ),
        'ques_locks'        => array('maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_ETHNICITY,
        'single_instance'   => true,
    ),
    'religion' => array(
        'display'           =>  array(
            'en_US' => 'Faith Identity',
            'es_US' => 'Religión',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'What faith tradition, if any, do you belong to?',
            'es_US' => '¿Qué religión practica?',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 255,
        ),
        'ques_locks'        => array('maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_RELIGION,
        'single_instance'   => true,
    ),
    'political' => array(
        'display'           =>  array(
            'en_US' => 'Political affiliation',
            'es_US' => 'Afiliación política',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'What political party, if any, do you identify with most closely?',
            'es_US' => '¿Con que partido político se identifica?',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'Democratic'),
                array('value' => 'Green'),
                array('value' => 'Independent'),
                array('value' => 'Libertarian'),
                array('value' => 'Republican'),
                array('value' => 'Unaffiliated'),
                array('value' => 'Other'),
            ),
            'es_US' => array(
                array('value' => 'Demócrata'),
                array('value' => 'Verde'),
                array('value' => 'Independiente'),
                array('value' => 'Libertariano'),
                array('value' => 'Republicano'),
                array('value' => 'No afiliado'),
                array('value' => 'Otro'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_DROPDOWN,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'ques_locks'        => array('ques_choices'),
        'ques_pmap_id'      => ProfileMap::$SRC_POLITICAL,
        'single_instance'   => true,
    ),
    'education' => array(
        'display'           =>  array(
            'en_US' => 'Education level',
            'es_US' => 'Nivel de Estudios',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => "What's your highest level of education?",
            'es_US' => '¿Cual describe mejor su nivel de estudios?',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'No high school degree'),
                array('value' => 'High school degree / GED'),
                array('value' => 'Some college'),
                array('value' => 'Associate degree'),
                array('value' => "Bachelor's degree"),
                array('value' => "Master's degree"),
                array('value' => 'Doctoral degree'),
                array('value' => 'Other professional certification'),
            ),
            'es_US' => array(
                array('value' => 'Sin haber terminado high school'),
                array('value' => 'High school terminado/GED'),
                array('value' => 'Algo de universidad'),
                array('value' => 'Título de Associate’s'),
                array('value' => 'Titulo de Bachelor’s (licenciatura)'),
                array('value' => 'Maestría'),
                array('value' => 'Doctorado'),
                array('value' => 'Otra certificación profesional'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_DROPDOWN,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'ques_locks'        => array('ques_choices'),
        'ques_pmap_id'      => ProfileMap::$SRC_EDUCATION,
        'single_instance'   => true,
    ),
    'expertise' => array(
        'display'           =>  array(
            'en_US' => 'Expertise',
            'es_US' => 'Experiencia',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'What else do you know more about than other people? (This will help us send you relevant questions in the future.)',
            'es_US' => '¿Sobre qué conoce más que otras personas? (Esto nos permitirá enviarle preguntas relevantes en el futuro.)',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 255,
        ),
        'ques_locks'        => array('maxlen'),
        'single_instance'   => true,
    ),
    'preflang' => array(
        'display'           =>  array(
            'en_US' => 'Language pref.',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'In which language do you prefer to receive queries?',
            'es_US' => '¿En qué idioma prefiere recibir preguntas e información?',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'English'),
                array('value' => 'Spanish'),
            ),
            'es_US' => array(
                array('value' => 'Inglés'),
                array('value' => 'Español'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PICK_RADIO,
        'ques_public_flag'  => false,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'ques_locks'        => array('ques_choices'),
        'ques_pmap_id'      => ProfileMap::$SRC_PREF_LANG,
        'single_instance'   => true,
    ),
    'occupation' => array(
        'display'           =>  array(
            'en_US' => 'Occupation',
            'es_US' => 'Ocupación',
        ),
        'display_group'     => 'demographic',
        'display_tip'       => array(
            'en_US' => 'Responses to this question map to Experiences in source profile so this question can be edited to ask for industry, job title, employer, or other work experience related text.',
        ),
        'ques_value'        =>  array(
            'en_US' => 'What do you do for work?',
            'es_US' => '¿Cuál es su trabajo?',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 256,
        ),
        'ques_pmap_id'      => ProfileMap::$SRC_OCCUPATION,
        'single_instance'   => true,
    ),
    'twitter' => array(
        'display'           =>  array(
            'en_US' => 'Twitter Username',
            'es_US' => 'Twitter nombre de usuario',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'Twitter Username',
            'es_US' => 'Twitter nombre de usuario',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
        ),
        'single_instance'   => true,
    ),
    'latitude' => array(
        'display'           =>  array(
            'en_US' => 'Latitude',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'Latitude',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_GEO,
        'ques_resp_opts'    => array(
            'require'       => false,
            'minlen'        => null,
            'maxlen'        => 12,
        ),
        'single_instance'   => true,
    ),
    'longitude' => array(
        'display'           =>  array(
            'en_US' => 'Longitude',
        ),
        'display_group'     => 'demographic',
        'ques_value'        =>  array(
            'en_US' => 'Longitude',
        ),
        'ques_type'         => Question::$TYPE_TEXT,
        'ques_resp_type'    => Question::$DTYPE_GEO,
        'ques_resp_opts'    => array(
            'require'       => false,
            'minlen'        => null,
            'maxlen'        => 12,
        ),
        'single_instance'   => true,
    ),
    /*
     * contact info templates
     */
    'firstname' => array(
        'display'           =>  array(
            'en_US' => 'First name',
            'es_US' => 'Primer Nombre',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'First Name',
            'es_US' => 'Primer Nombre',
        ),
        'ques_type'         => Question::$TYPE_CONTRIBUTOR,
        'ques_public_flag'  => false,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => true,
            'maxlen'        => 64,
        ),
        'ques_locks'        => array('require', 'maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_FIRST,
        'single_instance'   => true,
    ),
    'lastname' => array(
        'display'           =>  array(
            'en_US' => 'Last name',
            'es_US' => 'Apellido',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'Last Name',
            'es_US' => 'Apellido',
        ),
        'ques_type'         => Question::$TYPE_CONTRIBUTOR,
        'ques_public_flag'  => true,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => true,
            'maxlen'        => 64,
        ),
        'ques_locks'        => array('require', 'maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_LAST,
        'single_instance'   => true,
    ),
    'email' => array(
        'display'           =>  array(
            'en_US' => 'Email',
            'es_US' => 'Correo Electrónico',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'Email',
            'es_US' => 'Correo Electrónico',
        ),
        'ques_type'         => Question::$TYPE_CONTRIBUTOR,
        'ques_public_flag'  => false,
        'ques_resp_type'    => Question::$DTYPE_EMAIL,
        'ques_resp_opts'    => array(
            'require'       => true,
            'maxlen'        => 255,
        ),
        'ques_locks'        => array('ques_public_flag', 'require', 'maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_EMAIL,
        'single_instance'   => true,
    ),
    'phone' => array(
        'display'           =>  array(
            'en_US' => 'Phone',
            'es_US' => 'Teléfono',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'Phone',
            'es_US' => 'Teléfono',
        ),
        'ques_type'         => Question::$TYPE_CONTRIBUTOR,
        'ques_public_flag'  => false,
        'ques_resp_type'    => Question::$DTYPE_PHONE,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 16,
        ),
        'ques_locks'        => array('ques_public_flag', 'maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_PHONE,
        'single_instance'   => true,
    ),
    'street' => array(
        'display'           =>  array(
            'en_US' => 'Street address',
            'es_US' => 'Domicilio',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'Street',
            'es_US' => 'Domicilio',
        ),
        'ques_type'         => Question::$TYPE_CONTRIBUTOR,
        'ques_public_flag'  => false,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 128,
        ),
        'ques_locks'        => array('ques_public_flag', 'maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_MAIL_STREET,
        'single_instance'   => true,
    ),
    'city' => array(
        'display'           =>  array(
            'en_US' => 'City',
            'es_US' => 'Ciudad',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'City',
            'es_US' => 'Ciudad',
        ),
        'ques_type'         => Question::$TYPE_CONTRIBUTOR,
        'ques_public_flag'  => true,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 128,
        ),
        'ques_locks'        => array('maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_CITY,
        'single_instance'   => true,
    ),
    'state' => array(
        'display'           =>  array(
            'en_US' => 'State or province',
            'es_US' => 'Estado o provincia',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'State or province',
            'es_US' => 'Estado o provincia',
        ),
        'ques_type'         => Question::$TYPE_PICK_STATE,
        'ques_public_flag'  => true,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => false,
            'maxlen'        => 2,
        ),
        'ques_locks'        => array('maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_STATE,
        'single_instance'   => true,
    ),
    'zip' => array(
        'display'           =>  array(
            'en_US' => 'Postal code',
            'es_US' => 'Código Postal',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'Postal code',
            'es_US' => 'Código Postal',
        ),
        'ques_type'         => Question::$TYPE_CONTRIBUTOR,
        'ques_public_flag'  => false,
        'ques_resp_type'    => Question::$DTYPE_ZIP,
        'ques_resp_opts'    => array(
            'require'       => true,
            'minlen'        => 5,
            'maxlen'        => 10,
        ),
        'ques_locks'        => array('require','minlen', 'maxlen'),
        'ques_pmap_id'      => ProfileMap::$SRC_ZIP,
        'single_instance'   => true,
    ),
    'country' => array(
        'display'           =>  array(
            'en_US' => 'Country',
            'es_US' => 'País',
        ),
        'display_group'     => 'contact',
        'ques_value'        =>  array(
            'en_US' => 'Country',
            'es_US' => 'País',
        ),
        'ques_type'         => Question::$TYPE_PICK_COUNTRY,
        'ques_public_flag'  => false,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'default'       => 'US',
            'require'       => false,
            'maxlen'        => 2,
        ),
        'ques_locks'        => array('maxlen', 'default'),
        'ques_pmap_id'      => ProfileMap::$SRC_COUNTRY,
        'single_instance'   => true,
    ),
    'publicflag'  => array(
        'display'           =>  array(
            'en_US' => 'Publish permission',
            'es_US' => 'Pregunta de permiso',
        ),
        'display_group'     => 'permission',
        'ques_value'        =>  array(
            'en_US' => 'May we publish your insights (and any uploaded files) and attribute them to you? (Your comments may be edited for length or clarity.)',
            'es_US' => '¿Nos da permiso de publicar sus ideas (al igual que archivos subidos) y atribuirlos a usted? (Sus comentarios podrían ser editados para acreditarlos o hacerlos más claros.)',
        ),
        'ques_choices'      => array(
            'en_US' => array(
                array('value' => 'Yes'),
                array('value' => 'No'),
                array('value' => 'Contact me first'),
            ),
            'es_US' => array(
                array('value' => 'Sí'),
                array('value' => 'No'),
                array('value' => 'Avísame primero.'),
            ),
        ),
        'ques_type'         => Question::$TYPE_PERMISSION,
        'ques_resp_type'    => Question::$DTYPE_STRING,
        'ques_resp_opts'    => array(
            'require'       => true,
        ),
        'ques_locks'        => array(),
        'ques_pmap_id'      => ProfileMap::$SRC_RESP_PUBLIC,
        'single_instance'   => true,
    ),
);
