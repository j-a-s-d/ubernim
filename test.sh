#!/usr/bin/env bash

function RUN_TEST {
	nim c -r $1
	rm $1
}

cd tests
RUN_TEST test_ubernim_INIT
RUN_TEST test_ubernim_SWITCHES
RUN_TEST test_ubernim_FSACCESS
RUN_TEST test_ubernim_SHELLCMD
RUN_TEST test_ubernim_REQUIRES
RUN_TEST test_ubernim_UNIMCMDS
RUN_TEST test_ubernim_UNIMPRJS
RUN_TEST test_ubernim_TARGETED
RUN_TEST test_ubernim_LANGUAGE
cd ..
