# ubernim by Javier Santo Domingo
#-------------------------------------------------------------#
# "Striving to better, oft we mar what's well." - Shakespeare

import
  rodster, xam,
  ubernim / program

when defined(js):
  {.error: "This application needs to be compiled with a c/cpp-like backend".}

let app = newRodsterApplication("ubernim", "0.1.0")
app.setInitializationHandler(onInitialize)
app.setMainRoutine(programRun)
app.setFinalizationHandler(onFinalize)
app.run()
