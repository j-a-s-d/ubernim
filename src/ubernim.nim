# ubernim by Javier Santo Domingo
#-------------------------------------------------------------#
# "Striving to better, oft we mar what's well." - Shakespeare

import
  rodster, xam,
  ubernim / program

when defined(js):
  {.error: "This application needs to be compiled with a c/cpp-like backend".}

withIt newRodsterApplication("ubernim", "0.2.0"):
  it.setEvents(appEvents)
  it.run()
