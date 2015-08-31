require 'scarlet/plugins/klik'

hear(/klik/i) do
  clearance(&:registered?)
  description 'Displays how many seconds have elapsed between the last klik.'
  usage 'klik'
  on do
    n = Scarlet::Klik.klik.round(2)
    reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
  end
end
