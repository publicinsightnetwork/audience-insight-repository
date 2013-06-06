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
| Print-friendly submission view
|--------------------------------------------------------------------------
*/
if (!isset($submission)) {
    throw new Exception("submission var not defined");
}

// define the major objects
$subm = $submission;
$rsps = $subm['SrcResponse'];
$inq  = $subm['Inquiry'];
$proj = isset($inq['ProjectInquiry'][0]) ? $inq['ProjectInquiry'][0]['Project'] : null;
$src  = $subm['Source'];
$srsan = $subm['SrsAnnotation'];

?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
 <head>
  <title><?php echo $subm['title'] ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link href="<?php echo $c->uri_for('favicon.ico'); ?>" rel="shortcut icon" type="image/ico" />
  <link rel="stylesheet" href="<?php echo $c->uri_for('css/print.css') ?>"/>
 </head>
 <body>

  <!-- Inquiry -->
  <div>
   <h2><?php echo $inq['inq_ext_title'];?></h2>
   <?php if($inq['inq_type'] == Inquiry::$TYPE_MANUAL_ENTRY): ?>
   <p>Submission entered by <?php $c->airprinter->user($subm['CreUser']); ?>
       on <?php $c->airprinter->date($subm['srs_cre_dtim']); ?>
       <?php if ($proj) echo "for project '{$proj['prj_display_name']}'"; ?>
   </p>
   <?php else: ?>
   <p>Query published by <?php $c->airprinter->user($inq['CreUser']); ?>
       on <?php $c->airprinter->date($inq['inq_cre_dtim']); ?>
       <?php if ($proj) echo "for project '{$proj['prj_display_name']}'"; ?>
   </p>
   <?php endif; ?>
  </div>

  <!-- Source -->
  <div>
   <h3><?php $c->airprinter->source($src); ?></h3>
   <p><?php $c->airprinter->source_email($src); ?></p>
   <p><?php $c->airprinter->source_phone($src); ?></p>
   <p><?php $c->airprinter->source_address($src); ?></p>
   <?php $c->airprinter->all_facts($src); ?>
   <p><strong>Submitted on <?php $c->airprinter->date($subm['srs_date']); ?></strong></p>
  </div>

  <!-- Submission Annotations -->
  <?php if (count($srsan) > 0): ?>
  <div>
   <h3>Submission Annotations</h3>
   <ul>
   <?php foreach ($srsan as $annot): ?>
    <li>
     <?php $c->airprinter->user($annot['CreUser']); ?> -
     <strong><?php $c->airprinter->date($annot['srsan_cre_dtim']); ?></strong> -
     <?php echo $annot['srsan_value']; ?>
    </li>
   <?php endforeach; ?>
   </ul>
  </div>
  <?php endif; ?>

  <!-- Q & A -->
  <?php foreach (air2_sort_responses_for_display($rsps) as $sr): ?>
  <div>
   <h3><?php echo $sr['Question']['ques_value']; ?></h3>
     <p><?php if ($sr['sr_mod_value']) { echo '<strong>Original: </strong>'; } $c->airprinter->original_response($sr); ?></p>
     <?php if ($sr['sr_mod_value'] != '') {
        echo '<br />';
        echo '<p><strong>Modified: </strong>';
        $c->airprinter->response($sr);
        echo '</p>';
        echo '<p><em>Last Updated by ';
        $c->airprinter->user($sr['UpdUser']); 
        echo ' on ';
        $c->airprinter->date($sr['sr_upd_dtim']);
        echo '</em></p>';
     } ?>
   

   <!-- Response Annotations -->
   <?php if (count($sr['SrAnnotation']) > 0): ?>
   <ul>
    <?php foreach ($sr['SrAnnotation'] as $annot): ?>
    <li>
     <?php $c->airprinter->user($annot['CreUser']); ?> -
     <strong><?php $c->airprinter->date($annot['sran_cre_dtim']); ?></strong> -
     <?php echo $annot['sran_value']; ?>
    </li>
    <?php endforeach; ?>
   </ul>
   <?php endif; ?>
  </div>
  <?php endforeach; ?>

 </body>
</html>
