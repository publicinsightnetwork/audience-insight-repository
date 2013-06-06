#!/bin/sh

FROM=`date --date="3 months ago" +'%F'`
TODAY=`date +'%F'`
PERL=/opt/pij/bin/perl

if [ -z "$AIR2_ROOT" ]; then
    echo "AIR2_ROOT not set";
    exit 2;
fi
