# SaunaModel
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://bhalonen.github.io/SaunaModel.jl/)

This package is estimate of how a lumped sum sauna would behave. A lumped sum system modeling means approximating each component of the system with one number. This is a rough and ready approximation: obviously, the stove isn't all one temperature, and the air has has a very complex fluid dynamics problem, which could heat a small sized sauna with the heat given off with all the computers needed to solve in granular detail.

To use, install julia, then run from the REPL
`] add https://github.com/bhalonen/SaunaModel.jl` (the directive `]` causes julia to enter `pkg>` mode)

Then, re-enter `julia>` mode, and run 
`using SaunaModel:dictionary_api;dictionary_api(Dict())`
