# https://codepoints.net/U+1D47E
local MAGIC_CAPITAL_W='\U0001D47E'

# https://codepoints.net/U+1D496
local MAGIC_SMALL_U='\U0001D496'

# https://codepoints.net/U+1D499
local MAGIC_SMALL_X='\U0001D499'

# https://codepoints.net/U+1D489
local MAGIC_SMALL_H='\U0001D489'

# https://codepoints.net/U+1D7F7
local MAGIC_NUMBER_ONE='\U0001D7F7'

# https://codepoints.net/U+1D7FA
local MAGIC_NUMBER_FOUR='\U0001D7FA'

# https://codepoints.net/U+1D7FC
local MAGIC_NUMBER_SIX='\U0001D7FC'

local _MAGIC_ID=(
  $MAGIC_CAPITAL_W
  $MAGIC_SMALL_X
  $MAGIC_SMALL_H
  $MAGIC_NUMBER_ONE
  $MAGIC_NUMBER_SIX
  $MAGIC_NUMBER_ONE
  $MAGIC_NUMBER_FOUR
  $MAGIC_NUMBER_FOUR
)

local _MAGIC_NAME=(
  $MAGIC_CAPITAL_W
  $MAGIC_SMALL_U
  $MAGIC_SMALL_X
  $MAGIC_SMALL_H
)

export MAGIC_ID=$(printf "%s" "${_MAGIC_ID[@]}")
export MAGIC_NAME=$(printf "%s" "${_MAGIC_NAME[@]}")
