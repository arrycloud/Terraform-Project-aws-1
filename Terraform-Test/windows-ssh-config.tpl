add-content -path c:/users/dipo/.ssh/config -value @'

Host $(hostname)
  HostName $(hostname)
  User $(user)
  IdentityFile $(identityfile)
  '@