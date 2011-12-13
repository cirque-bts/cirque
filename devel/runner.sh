#!/bin/sh

if [ -z "$DEPLOY_ENV" ] ; then
    DEPLOY_ENV=dev
fi

export DEPLOY_ENV=$DEPLOY_ENV
export PERL5OPT='-Mlib=./extlib/lib/perl5 -Ilib'
exec /usr/bin/env perl bin/cirqued
 
