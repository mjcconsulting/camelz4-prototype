# Initialization

**TODO**: Using this section for random notes on setup, prior to better organization and strucutre for them.


### Steps
1.  **Subscribe to Marketplace AMIs used within the POC**

    In the CaMeLz Network Account, Subscribe to: "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance"
    - Search Marketplace for "Cisco Cloud Services Router (CSR) 1000V - BYOL for Maximum Performance"
    - Subscribe

1.  **Get Current AMI IDs for AMIs used within the POC**

    Go into EC2, run instances and see what is the AMI ID for the following:
    - Amazon Linux older kernel
    - Windows 2016 base
    - Windows 2019 base
    - Windows 2022 base
    - Cisco v1000 Virtual Appliance

1.  **Configure Shell for CaMeLz Environment**

    Currently, this code only runs within a Linux Environment. This is being developed and tested in the following setups:
    - MacBook Pro, running macOS Big Sur 11.6.5, using zsh, with Oh-my-zsh extensions.
    - Intel NUC Enthusiast 11, running Windows 11, using WSL subsystem with Ubuntu 20.04 LTS, using zsh, with Oh-my-zsh
      extentions.

    Note the AWS commands should also work in PowerShell, but there is occasionally if/else or other logic needed to
    choose between multiple options, or perform minor manipulation of returned values before they can be used for another
    statement. Also, the `camelz-variable` shell function used to display and store variables would need to be replaced
    with a PowerShell equivalent. Given the need for speed on this, and to avoid extra work not strictly necessary,
    with the WSL within Windows, this can run on Windows and the effort to make this run in pure Windows was not viewed
    as justified.

    Modify your `~/.zshrc` (zsh) or `~/.bashrc` (bash) profile to add the following lines. This shows the location where
    it is assumed the CaMeLz4-Prototype code repo is located. Adjust this if you use an alternate location.

    ```bash
    export CAMELZ_HOME=$HOME/src/mjcconsulting/camelz4-prototype
    export PATH=$PATH:$CAMELZ_HOME/bin
    source camelz-init
    ```


