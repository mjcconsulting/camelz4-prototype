# Saved Links

Saving these links as I've found them until I have time to work on these areas more, so I don't lose them

## PowerShell Tools Links
- [AWS Tools for PowerShell Reference](https://docs.aws.amazon.com/powershell/latest/reference/)

## Systems Manager Links


## Windows Automation Tasks Links
- [Customize Windows 10 Start and taskbar with Group Policy](https://docs.microsoft.com/en-us/windows/configuration/customize-windows-10-start-screens-by-using-group-policy)
- [Customize and export Start layout](https://docs.microsoft.com/en-us/windows/configuration/customize-and-export-start-layout)
- [Pin apps to the Taskbar in Windows 10 1607 with Group Policy](https://4sysops.com/archives/pin-apps-to-the-taskbar-in-windows-10-1607-with-group-policy/)
- [How to Find Out the Equivalent Registry Values for Group Policy Settings](https://www.maketecheasier.com/registry-values-for-group-policy-settings-windows/)  
  This contains a reference on how to use Process Monitor to see what changes to apps or Group Policy is doing to the Registry,
  So you can then just make the change direct during startup to get the same result non-interactively.
- [Process Monitor v3.53](https://docs.microsoft.com/en-us/sysinternals/downloads/procmon)  
  Download link for Process Monitor
- [Group Policy Search](https://gpsearch.azurewebsites.net)  
  Allows lookup of registry entries from Group Policy settings
- [Management of Start Menu and Tiles on Windows 10 and Server 2016, part #1](https://james-rankin.com/articles/management-of-start-menu-and-tiles-on-windows-10-and-server-2016-part-1/)
- [Management of Start Menu and Tiles on Windows 10 and Server 2016, part #2](https://james-rankin.com/articles/management-of-start-menu-and-tiles-on-windows-10-and-server-2016-part-2/)
- [Manage Windows 10 Start and taskbar layout](https://docs.microsoft.com/en-us/windows/configuration/windows-10-start-layout-options-and-policies)  
  This has a section on how to debug issues with modifications to the Start Menu
- [Win10: Start Customization with LayoutModification.xml](https://winpeguy.wordpress.com/2015/10/30/win10-start-customization-with-layoutmodification-xml/)  
  **Finally!** Found the right way to do what I want here. Many of the techniques above only cover part of the answer, this one
  had the missing piece, to write to **C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml**, then
  *no registry modifications are needed*, and each New User created gets the modifications. It was incredibly hard to find
  this - not documented anywhere!
- [Adding Microsoft Authenticator MFA to Windows logon](https://james-rankin.com/articles/adding-microsoft-authenticator-mfa-to-windows-logon-using-manageengine-ad-self-service-plus/)
- [The PowerShell Here-String – Preserve text formatting](https://4sysops.com/archives/the-powershell-here-string-preserve-text-formatting/)
- [Set-ItemProperty](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-itemproperty?view=powershell-7)  
  How to set registry entries. Follow this link for more related Cmdlet descriptions
- [POWERSHELL – UPDATING THE .DEFAULT AND ALL USER PROFILES REGISTRY](https://www.checkyourlogs.net/powershell-updating-the-default-and-all-user-profiles-registry/)  
  This was the inspiration for the DXCP-ConfigureWindowsDefaultUser SSM Document
- [How To Run a Logon Script One Time When a New User Logs On in Windows Server 2003](https://support.microsoft.com/en-us/help/325347/how-to-run-a-logon-script-one-time-when-a-new-user-logs-on-in-windows)  
  Despite the name, this works on Windows Server 2016
- [Configure a RunOnce task on Windows](https://cmatskas.com/configure-a-runonce-task-on-windows/)
- [Wondering why mscorsvw.exe has high CPU usage? You can speed it up.](https://devblogs.microsoft.com/dotnet/wondering-why-mscorsvw-exe-has-high-cpu-usage-you-can-speed-it-up/)  
  This mainly applies to RoyalTS, but potentially to other apps which use the .NET framework. It is a method to optimize
  the code by pre-compiling it so apps run faster.
- [Rename computer and join to domain in one step with PowerShell](https://stackoverflow.com/questions/6217799/rename-computer-and-join-to-domain-in-one-step-with-powershell)  
  This describes a trick to setup the Runonce script to join the domain - AFTER - it has been rebooted to reset the hostname, as opposed to attempting to rename, then join without a reboot in-between. The problem with the no reboot method, is that the host first attempts to join with the existing name, then rename. So, if you are re-creating an instance with the same name over and over, the first join succeeds, but unless you delete the prior host before you re-create, it will fail on the second attempt.
- [Setting Powershell colors with hex values in profile script](https://stackoverflow.com/questions/16280402/setting-powershell-colors-with-hex-values-in-profile-script)  
  This has a reference to how you can set PowerShell Colors by hex code in the registry.
- [PowerShell – Hate The Error Text And Warning Text Colors? Change It!](https://sqljana.wordpress.com/2017/03/01/powershell-hate-the-error-text-and-warning-text-colors-change-it/)  
- [Enable Ping ICMP Replies For Amazon EC2 Windows Instances](http://www.therealtimeweb.com/index.cfm/2011/10/28/amazon-ec2-ping)  
  How to enable ping to Windows, basically  
  ```powershell
  netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
  ```
- [Continue Your Automation To Run Once After Restarting a Headless Windows System](https://cloudywindows.io/post/continue-your-automation-to-run-once-after-restarting-a-headless-windows-system/)  
  This seems like a better solution, as the RunOnce registry key requires a user to login before it completes a task after a reboot.
- [Turn off the Network Location wizard](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/gg252535(v=ws.10)?redirectedfrom=MSDN)  
  How to prevent the annoying Network Wizard Popup on first login.
- [PowerShell regex crash course – Part 4 of 5](https://devblogs.microsoft.com/scripting/powershell-regex-crash-course-part-4-of-5/)  
  Good page on Windows-specific Regular Expressions, including reverse look-behind  


## Linux Automation Task Links
- [GitHub: jq Cookbook](https://github.com/stedolan/jq/wiki/Cookbook#remove-adjacent-matching-elements-from-a-list)


## AMI Links
- [Introducing EC2 Image Builder](https://aws.amazon.com/about-aws/whats-new/2019/12/introducing-ec2-image-builder/)
- [EC2 Image Builder: Building virtual machine images made easy](https://d1.awsstatic.com/events/reinvent/2019/NEW_LAUNCH_REPEAT_1_EC2_Image_Builder_Building_virtual_machine_images_made_easy_CMP214-R1.pdf)
- [Automate OS Image Build Pipelines with EC2 Image Builder](https://aws.amazon.com/blogs/aws/automate-os-image-build-pipelines-with-ec2-image-builder/)
- [AWS re:Invent 2019: [NEW LAUNCH!] EC2 Image Builder: Virtual machine images made easy (CMP214-R1)](https://www.youtube.com/watch?v=9XFuRq0R8nk)
- [HOW TO MANAGE AND RUN IMAGES USING AWS EC2 IMAGE BUILDER](https://www.youtube.com/watch?v=WhhDdAoHftY)
- [How to Create a Custom AMI with Encrypted Amazon EBS Snapshots and Share It with Other Accounts and Regions](https://aws.amazon.com/blogs/security/how-to-create-a-custom-ami-with-encrypted-amazon-ebs-snapshots-and-share-it-with-other-accounts-and-regions/)


## Transit Gateway Links
- [Introduction to AWS Transit Gateway - AWS Online Tech Talks](https://www.youtube.com/watch?v=6fhwoAwYrug)
- [Advanced Architectures with AWS Transit Gateway](https://www.youtube.com/watch?v=S9fEydjJ9qo)
- [AWS Transit Gateway Reference Architectures for Many Amazon VPCs - AWS Online Tech Talks](https://www.youtube.com/watch?v=A_2qq9fFxVU)
- [Securing VPCs Egress using IDS/IPS leveraging Transit Gateway](https://aws.amazon.com/blogs/networking-and-content-delivery/securing-egress-using-ids-ips-leveraging-transit-gateway/)
- [AWS Networking Workshop](https://networking.aworkshop.io)
- [GitHub: geseib/tgwwalk](https://github.com/geseib/tgwwalk)


## Directory Service Links
- [How to Connect Your On-Premises Active Directory to AWS Using AD Connector](https://aws.amazon.com/blogs/security/how-to-connect-your-on-premises-active-directory-to-aws-using-ad-connector/)
- [How to Configure Your EC2 Instances to Automatically Join a Microsoft Active Directory Domain](https://aws.amazon.com/blogs/security/how-to-configure-your-ec2-instances-to-automatically-join-a-microsoft-active-directory-domain/)


## PKI Links
- [Step 3: Create the Trust Relationship](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_tutorial_setup_trust_create.html)
- [Install a Root Certification Authority](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc731183(v=ws.11)?redirectedfrom=MSDN)
- [Install a Subordinate Certification Authority](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc772192(v=ws.11)?redirectedfrom=MSDN)
- [Install the Certification Authority](https://docs.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/install-the-certification-authority)
- [How to Enable Server-Side LDAPS for Your AWS Microsoft AD Directory](https://aws.amazon.com/blogs/security/how-to-enable-ldaps-for-your-aws-microsoft-ad-directory/)
- [How to seamlessly domain join Amazon EC2 instances to a single AWS Managed Microsoft AD Directory from multiple accounts and VPCs](https://aws.amazon.com/blogs/security/how-to-domain-join-amazon-ec2-instances-aws-managed-microsoft-ad-directory-multiple-accounts-vpcs/)
- [AWS Client VPN Tutorial](https://nicovibert.com/2019/09/16/aws-client-vpn-tutorial/)
- [QueuingKoala/setup.sh - setup EasyRSA to use multiple CAs on one host](https://gist.github.com/QueuingKoala/e2c1c067a312384915b5)
- [Setting up an AWS VPC Client VPN](https://smartshifttech.com/guide-setting-up-an-aws-vpc-client-vpn/)
- [Using LetsEncrypt SSL certificates in AWS Certificate Manager](https://itnext.io/using-letsencrypt-ssl-certificates-in-aws-certificate-manager-c2bc3c6ae10)
- [Configuring DynamoDB VPC Endpoints with AWS CloudFormation](https://shaun.net/notes/configuring-dynamodb-vpc-endpoints-aws-cloudformation/)
- [Easy-RSA Advanced Reference](https://github.com/OpenVPN/easy-rsa/blob/master/doc/EasyRSA-Advanced.md)
- [Site-to-site VPN between GCP and AWS with dynamic BGP routing](https://medium.com/@oleg.pershin/site-to-site-vpn-between-gcp-and-aws-with-dynamic-bgp-routing-7d7e0366036d)
- [Google Cloud Platform (login)](https://accounts.google.com/ServiceLogin/webreauth?service=cloudconsole&passive=1209600&osid=1&continue=https%3A%2F%2Fconsole.cloud.google.com%2Fnetworking%2Fnetworks%2Flist%3Fproject%3Dmjc-quickstart-linux-vm%26organizationId%3D1097237294852%26ref%3Dhttps%3A%2F%2Fcloud.google.com%2Fcompute%2Fdocs%2Fquickstart-linux&followup=https%3A%2F%2Fconsole.cloud.google.com%2Fnetworking%2Fnetworks%2Flist%3Fproject%3Dmjc-quickstart-linux-vm%26organizationId%3D1097237294852%26ref%3Dhttps%3A%2F%2Fcloud.google.com%2Fcompute%2Fdocs%2Fquickstart-linux&authuser=0&flowName=GlifWebSignIn&flowEntry=ServiceLogin)


## Cisco CSR Router Links
- [Cisco CSR 1000v and Cisco ISRv Software Configuration Guide](https://www.cisco.com/c/en/us/td/docs/routers/csr1000/software/configuration/b_CSR1000v_Configuration_Guide/b_CSR1000v_Configuration_Guide_chapter_00.html)
- [IPsec Troubleshooting: Understanding and Using debug Commands](https://www.cisco.com/c/en/us/support/docs/security-vpn/ipsec-negotiation-ike-protocols/5409-ipsec-debug-00.html#isakmp_sa)
- [Is there a run a set of commands from a file in flash:?](https://community.cisco.com/t5/small-business-switches/is-there-a-run-a-set-of-commands-from-a-file-in-flash/m-p/4065935/highlight/false#M22866)
- [Running a tcl script on Cisco router](https://www.reddit.com/r/networking/comments/6asrbx/running_a_tcl_script_on_cisco_router/)

## ClientVPN Links
- [Introducing AWS Client VPN to Securely Access AWS and On-Premises Resources](https://aws.amazon.com/blogs/networking-and-content-delivery/introducing-aws-client-vpn-to-securely-access-aws-and-on-premises-resources/?sc_ichannel=ha&sc_icampaign=pac_blogfoot1&sc_isegment=en&sc_iplace=2up&sc_icontent=vpnblog&sc_segment=-1)
- [Better Security and Performance with AWS VPN Innovations - AWS Online Tech Talks](https://www.youtube.com/watch?v=FrhVV9nG4UM)
