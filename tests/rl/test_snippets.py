#! /usr/bin/env py.test
# -*- coding: utf-8 -*-

# Copyright (c) 2007-2008 PediaPress GmbH
# See README.txt for additional licensing information.

from renderhelper import renderMW
from mwlib import snippets
import pytest


def doit(ex):
    print("rendering", ex)
    renderMW(ex.txt)


@pytest.mark.parametrize("ex", snippets.get_all())
def test_examples(ex):
    doit(ex)

    # FIXME: move snippets to test directory
