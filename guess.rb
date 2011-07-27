#!/bin/env ruby

require "./seriensieger"

# command switch: guess next day, guess a season

sieger = Seriensieger.new
if ARGV[0] == "training"
  sieger.load(2010)
  sieger.guess_all
else
  sieger.load(2011)
  sieger.guess_next
end

# vim: ai sw=2 expandtab smarttab ts=2
