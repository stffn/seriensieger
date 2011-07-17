#!/bin/env ruby

require "./seriensieger"

# command switch: guess next day, guess a season

sieger = Seriensieger.new
sieger.load(2010)
sieger.guess_all

# vim: ai sw=2 expandtab smarttab ts=2
