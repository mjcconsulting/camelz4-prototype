# This is just a snippet of the statements needed to set colors, with their actual R,G,B values as seen if you want to change them
# Note that (I lost days to this) unlike every other entity which exists, Windows stores colors in BGR order
# Also note that Colors are overridden at multiple levels, so getting the console to actually show what you want is
# very, very challenging to figure out. You have:
# 1. HKCU:\Console - this stores colors which are the "default", used for both PowerShell and Cmd
# 2. HTCU:\Console\...a powershell path - this stores colors which are overridden and just for PowerShell
#    - The standard behavior is to override ColorTable05 and ColorTable06 with a blue and white and use them.
#    - This is a huge hack and not done properly. I thought it best to just not use this and work direct with the Console
# 3. The PowerShell Shortcut itself. There's no way to adjust the layout and colors in this - what exists in the registry
#    at the time the Shortcut is created is then preserved. So, you need to first remove the PowerShell-specific registry
#    keys, in the Administrator Account, then you can create a new Shortcut, which no longer has any overrides and defaults
#    to the Console, and create a new Shortcut, before this will work. I did that, and then also used this new Shortcut
#    to create the Default User Shortcuts, so all new users should have the correct new behavior as well.
#    - This process is best understood by studying the user profile setup section of the windows-wb-user-data.ps1 script

        $Path = "Registry::HKEY_CURRENT_USER\Console"
        Set-ItemProperty -Path $Path -Name ColorTable00 -Value 0x001e1414 -Force | Out-Null # Black       (20,20,30)
        Set-ItemProperty -Path $Path -Name ColorTable01 -Value 0x00642800 -Force | Out-Null # DarkBlue    (0,40,100)
        Set-ItemProperty -Path $Path -Name ColorTable02 -Value 0x00144632 -Force | Out-Null # DarkGreen   (50,70,20)
        Set-ItemProperty -Path $Path -Name ColorTable03 -Value 0x00aa9600 -Force | Out-Null # DarkCyan    (0,150,170)
        Set-ItemProperty -Path $Path -Name ColorTable04 -Value 0x00100880 -Force | Out-Null # DarkRed     (128,8,16)
        Set-ItemProperty -Path $Path -Name ColorTable05 -Value 0x00400820 -Force | Out-Null # DarkMagenta (32,8,64)
        Set-ItemProperty -Path $Path -Name ColorTable06 -Value 0x0000aaff -Force | Out-Null # DarkYellow  (255,170,0)
        Set-ItemProperty -Path $Path -Name ColorTable07 -Value 0x00e6dcd2 -Force | Out-Null # Gray        (210,220,230)
        Set-ItemProperty -Path $Path -Name ColorTable08 -Value 0x00beb4a0 -Force | Out-Null # DarkGray    (160,180,190)
        Set-ItemProperty -Path $Path -Name ColorTable09 -Value 0x00f08c28 -Force | Out-Null # Blue        (40,140,240)
        Set-ItemProperty -Path $Path -Name ColorTable10 -Value 0x0028c882 -Force | Out-Null # Green       (130,200,40)
        Set-ItemProperty -Path $Path -Name ColorTable11 -Value 0x00dcc850 -Force | Out-Null # Cyan        (80,200,220)
        Set-ItemProperty -Path $Path -Name ColorTable12 -Value 0x004040ff -Force | Out-Null # Red         (255,64,64)
        Set-ItemProperty -Path $Path -Name ColorTable13 -Value 0x00d28caa -Force | Out-Null # Magenta     (170,140,210)
        Set-ItemProperty -Path $Path -Name ColorTable14 -Value 0x0014d2ff -Force | Out-Null # Yellow      (255,210,20)
        Set-ItemProperty -Path $Path -Name ColorTable15 -Value 0x00f0faff -Force | Out-Null # White       (255,250,240)
