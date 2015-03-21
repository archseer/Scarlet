hear (/dcc/i) do
  clearance :owner
  on do
    Scarlet::DCC.send @event, 'chellocat.jpg'
  end
end
