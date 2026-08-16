# Standalone test project for the controller navigation repeat clock.
#
# Deliberately NOT a SUBDIRS entry of moonlight-qt.pro: nothing about the
# shipping build or the packaging scripts should change because a test exists.
# Build and run it on its own --
#
#   qmake tests/navigationrepeat/navigationrepeat.pro && jom && tst_navigationrepeat
#
# The helper under test is header-only and has no SDL or Qt GUI dependency, so
# this needs nothing from app.pro beyond the include path.

QT += testlib
QT -= gui

CONFIG += console testcase c++17
CONFIG -= app_bundle

TEMPLATE = app
TARGET = tst_navigationrepeat

INCLUDEPATH += $$PWD/../../app/gui

HEADERS += $$PWD/../../app/gui/navigationrepeat.h
SOURCES += tst_navigationrepeat.cpp
