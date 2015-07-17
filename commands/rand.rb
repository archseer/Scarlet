require 'scarlet/plugins/klik'

hear (/klik/i) do
  clearance &:registered?
  description 'Displays how many seconds have elapsed between the last klik.'
  usage 'klik'
  on do
    n = Scarlet::Klik.klik.round(2)
    reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
  end
end

hear (/update(?:\s+(\S+))?/i) do
  clearance &:dev?
  description 'Just to nag the crap out of Speed.'
  usage 'update [<name>]'
  on do
    n = Scarlet::Nick.owner
    notice params[1] || n.nick, "%s demandes que tu mettre à jour moi!" % sender.nick
    notify "Notice sent."
  end
end
