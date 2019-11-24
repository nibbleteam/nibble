local Click = {}

function Click.press()
  channel(CH7)

  freqs(0.05, 0.125, 0.05, 1.0)

  envelope(OP1, 0, 0, 0.0, 0.01, 1.0, 0.05, 0)
  envelope(OP2, 0, 0, 0.0, 0.01, 1.0, 0.05, 0)
  envelope(OP3, 0, 0, 0.0, 0.01, 1.0, 0.5, 0)
  envelope(OP4, 0, 0, 0.0, 0.01, 1.0, 0.05, 0)

  -- Reset
  local ops = {OP1, OP2, OP3, OP4}
  for i=1,4 do
    for j=1,4 do
      route(ops[i], ops[j], 0)
      route(ops[i], OUT, 0)
    end
  end

  -- Gritty
  route(OP1, OUT, 0.5)
  route(OP1, OP1, 0.5)

  -- Ressonant
  route(OP2, OUT, 0.5)

  -- Lowfreq
  route(OP3, OP1, 1.0)
  route(OP3, OUT, 1.0)

  -- Highfreq
  --route(OP4, OUT, 1.0)

  noteon(32, 255)
end

function Click.release()
  channel(CH7)

  freqs(0.05, 0.125, 0.05, 1.0)

  envelope(OP1, 0, 0, 0.0, 0.01, 1.0, 0.05, 0)
  envelope(OP2, 0, 0, 0.0, 0.01, 1.0, 0.05, 0)
  envelope(OP3, 0, 0, 0.0, 0.01, 1.0, 0.5, 0)
  envelope(OP4, 0, 0, 0.0, 0.01, 1.0, 0.05, 0)

  -- Reset
  local ops = {OP1, OP2, OP3, OP4}
  for i=1,4 do
    for j=1,4 do
      route(ops[i], ops[j], 0)
      route(ops[i], OUT, 0)
    end
  end

  -- Gritty
  route(OP1, OUT, 0.5)
  route(OP1, OP1, 0.5)

  -- Ressonant
  route(OP2, OUT, 0.5)

  -- Lowfreq
  route(OP3, OP1, 1.0)
  route(OP3, OUT, 1.0)

  -- Highfreq
  --route(OP4, OUT, 1.0)

  noteon(16, 255)
end

return Click
