hear(/dcc/i) do
  clearance(&:root?)
  on do
    Scarlet::DCC.send @event, 'chellocat.jpg'
  end
end
