<?php
/**************************************************************************
 *
 *   Copyright 2010 American Public Media Group
 *
 *   This file is part of AIR2.
 *
 *   AIR2 is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   AIR2 is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with AIR2.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************/

/*
|--------------------------------------------------------------------------
| Print-friendly bin view
|--------------------------------------------------------------------------
*/
if (!isset($bin)) {
    throw new Exception("bin var not defined");
}

// define the major objects
$bunch = $bin['bin'];
$sources = $bin['sources'];
// fact keys and display values
$facts = array(
    'gender'                => 'Gender',
    'household_income'      => 'Household Income',
    'education_level'       => 'Education Level',
    'political_affiliation' => 'Political Affiliation',
    'ethnicity'             => 'Ethnicity',
    'religion'              => 'Religion',
    'birth_year'            => 'Birth Year',
    'source_website'        => 'Source website',
    'lifecycle'             => 'Lifecycle',
    'timezone'              => 'Timezone',
);

?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
 <head>
  <title><?php echo $bunch['bin_name']; ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link href="<?php echo $c->uri_for('favicon.ico'); ?>" rel="shortcut icon" type="image/ico" />
  <link rel="stylesheet" href="<?php echo $c->uri_for('css/print.css') ?>"/>
 </head>
 <body>

  <!-- Bin -->
  <div>
   <h1>Bin '<?php echo $bunch['bin_name']; ?>'</h1>
   <strong><?php echo $bunch['bin_desc']; ?></strong>
   <p>Created by <?php $c->airprinter->user($bunch['User']); ?>
       on <?php $c->airprinter->date($bunch['bin_cre_dtim']); ?>
   </p>
   <p><?php echo $bunch['src_count']; ?> Sources -
       Last modified on <?php $c->airprinter->date($bunch['bin_upd_dtim']); ?>
   </p>
  </div>

  <!-- Sources -->
  <div>
   <?php if (count($sources) == 0): ?>
    <h2>No sources in bin</h2>
   <?php else: ?>
    <ol>
    <?php foreach ($sources as $src): ?>
     <li>
      <!-- Profile -->
      <div>
       <h2><?php $c->airprinter->source($src, true); ?></h2>
       <?php if ($src['bsrc_notes'] && preg_match('/\w/', $src['bsrc_notes'])): ?>
       <p><i><b>Notes</b> - <?php echo $src['bitem_notes']; ?></i></p>
       <?php endif; ?>
       <p><?php $c->airprinter->source_email($src); ?></p>
       <p><?php $c->airprinter->source_phone($src); ?></p>
       <p><?php $c->airprinter->source_address($src); ?></p>
       <?php foreach ($facts as $ident => $label): ?>
        <?php if (isset($src[$ident]) && $src[$ident]): ?>
         <p><?php echo "<b>$label</b>: {$src[$ident]}"; ?></p>
        <?php endif; ?>
       <?php endforeach; ?>
      </div>

      <!-- Submissions -->
      <?php foreach ($src['response_sets'] as $subm): ?>
      <div>

       <!-- Query Q&A -->
       <h3><?php echo $subm['inq_ext_title']; ?></h3>
       <p><strong>Submitted on <?php $c->airprinter->date($subm['srs_date']); ?></strong></p>

       <!-- Submission annotations -->
       <?php foreach ($subm['annotations'] as $annot): ?>
        <p><?php $c->airprinter->user($annot); ?> -
          <strong><?php $c->airprinter->date($annot['srsan_cre_dtim']); ?></strong> -
          <?php echo $annot['srsan_value']; ?></p>
       <?php endforeach; ?>

       <!-- Responses -->
       <ul>
       <?php foreach ($subm['responses'] as $sr): ?>
        <li>
         <h4><?php echo strip_tags($sr['ques_value'], '<a><i>'); ?></h4>
         <p><?php if ($sr['sr_mod_value']) { echo '<strong>Original: </strong>'; } $c->airprinter->original_response($sr); ?></p>

         <?php if ($sr['sr_mod_value'] != '') {
            echo '<br />';
            echo '<p><strong>Modified: </strong>';
            $c->airprinter->response($sr);
            echo '</p>';
            echo '<p><em>Last Updated by ';
            $c->airprinter->user($sr); 
            echo ' on ';
            $c->airprinter->date($sr['sr_upd_dtim']);
            echo '</em></p>';
         } ?>

         <!-- Response Annotations -->
         <?php if (count($sr['annotations']) > 0): ?>
         <ul><?php foreach ($sr['annotations'] as $annot): ?>
          <li><p><?php $c->airprinter->user($annot); ?> -
           <strong><?php $c->airprinter->date($annot['sran_cre_dtim']); ?></strong> -
           <?php echo $annot['sran_value']; ?></p></li>
          <?php endforeach; ?></ul>
         <?php endif; ?>
        </li>
       <?php endforeach; ?>
       </ul>
      </div>
      <?php endforeach; ?>
     </li>
    <?php endforeach; ?>
    </ol>
   <?php endif; ?>
  </div>

 </body>
</html>
