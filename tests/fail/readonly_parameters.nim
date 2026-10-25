import openxy

proc mutate(parameters: openArray[Q31]) =
  parameters[0] = Q31(1)

var parameters: array[ParameterSlots, Q31]
mutate(parameters)
