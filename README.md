# Remove-VMTools

Script to Remove VMtools based on Vmware [KB1001354](https://kb.vmware.com/s/article/1001354)


This script must be used after try to remove using VMWARE [KB2010137] (https://kb.vmware.com/s/article/2010137)

What this script does?

1. Stop VMTools Services (only services that exist)
2. Backup Registry Keys related to VmTools
3. Delete Registry Keys related to VmTools
4. Delete Vmtools Services (only services that exist)
5. Delete VmTools Folder

