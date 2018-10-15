#!/bin/sh
#
# Copyright (C) 2018  Antonio Ospite <ao2@ao2.it>
#

test_description='Test reading/writing .gitmodules when not in the working tree

This test verifies that, when .gitmodules is in the current branch but is not
in the working tree reading from it still works but writing to it does not.

The test setup uses a sparse checkout, however the same scenario can be set up
also by committing .gitmodules and then just removing it from the filesystem.
'

. ./test-lib.sh

test_expect_success 'sparse checkout setup which hides .gitmodules' '
	echo file >file &&
	git add file &&
	test_tick &&
	git commit -m upstream &&
	git clone . super &&
	git clone super submodule &&
	git clone super new_submodule &&
	(cd super &&
		git submodule add ../submodule &&
		test_tick &&
		git commit -m submodule &&
		cat >.git/info/sparse-checkout <<-\EOF &&
		/*
		!/.gitmodules
		EOF
		git config core.sparsecheckout true &&
		git read-tree -m -u HEAD &&
		test_path_is_missing .gitmodules
	)
'

test_expect_success 'reading gitmodules config file when it is not checked out' '
	(cd super &&
		echo "../submodule" >expect &&
		git submodule--helper config submodule.submodule.url >actual &&
		test_cmp expect actual
	)
'

test_expect_success 'not writing gitmodules config file when it is not checked out' '
	 test_must_fail git -C super submodule--helper config submodule.submodule.url newurl
'

test_expect_success 'initialising submodule when the gitmodules config is not checked out' '
	git -C super submodule init
'

test_expect_success 'showing submodule summary when the gitmodules config is not checked out' '
	git -C super submodule summary
'

test_expect_success 'updating submodule when the gitmodules config is not checked out' '
	(cd submodule &&
		echo file2 >file2 &&
		git add file2 &&
		git commit -m "add file2 to submodule"
	) &&
	git -C super submodule update
'

test_expect_success 'not adding submodules when the gitmodules config is not checked out' '
	test_must_fail git -C super submodule add ../new_submodule
'

# This test checks that the previous "git submodule add" did not leave the
# repository in a spurious state when it failed.
test_expect_success 'init submodule still works even after the previous add failed' '
	git -C super submodule init
'

test_done
