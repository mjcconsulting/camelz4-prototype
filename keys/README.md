# Keys

This section contains the SSH public keys used to create AWS Key Pairs. The private keys are stored in 1Password as
secure files.

## Dependencies

- No Dependencies

## Public Keys

Links to the public key material, and the current key fingerprint in AWS KeyPair format. Use the fingerprint to confirm
the keys imported match the public key data.

1. **[bootstrap](./camelz_bootstrap_id_rsa.pub)** [35:d3:b4:cb:0a:f1:04:c7:2b:1e:eb:ed:c5:94:b4:fe]
1. **[bootstrapadministrator](./camelz_bootstrapadministrator_id_rsa.pub)** [12:9a:57:9a:2b:0e:73:cc:55:36:69:88:63:e8:00:af]
1. **[bootstrapuser](./camelz_bootstrapuser_id_rsa.pub)** [f7:59:af:a9:7c:e9:38:4b:e8:f8:eb:7c:e6:27:50:b5]
1. **[administrator](./camelz_administrator_id_rsa.pub)** [80:d7:20:6b:d2:79:42:59:e8:99:9e:18:47:fd:30:ca]
1. **[developer](./camelz_developer_id_rsa.pub)** [c8:be:d3:bc:59:b4:00:f9:f3:f8:63:26:7e:e7:5c:c8]
1. **[manager](./camelz_manager_id_rsa.pub)** [bc:0d:5f:0b:c3:2b:66:d4:26:fe:22:6a:31:a3:c4:0a]
1. **[user](./camelz_user_id_rsa.pub)** [65:c1:cc:11:b8:48:bb:0e:61:6c:ae:b5:87:aa:8a:dd]
1. **[example](./camelz_example_id_rsa.pub)** [87:66:e9:a9:5c:1f:e9:0f:85:c8:95:f0:fa:3e:09:b8]
1. **[demo](./camelz_demo_id_rsa.pub)** [7e:97:dd:8b:c3:90:48:a7:d9:12:8b:9b:96:7f:be:be]
1. **[mcrawford](./camelz_mcrawford_id_rsa.pub)** [48:e2:0c:98:29:d7:96:c5:87:87:58:95:16:94:68:40]

## Creating & Storing SSH Keys

This is the list of commands to re-create the SSH keys when needed. For each key in the above list, the following
commands should be run to create the SSH key, generate the AWS Fingerprint, and generate a version of the private key
without a password. A reasonably complex and long (20+ characters) passphrase should be used when generating all keys.

The protected and unprotected private keys, as well as the public key, should be stored in a credentials management
system such as `1Password`. Store the private key along with it's passphrase and fingerprint. Store the public key
along with it's fingerprint.

The unprotected private key should immediately be removed from the filesystem once it is stored. It needs to exist in
an easily-accessible manner to decrypt Windows Administrator passwords in the Console when needed.

1. **Create administrator SSH Key**

    ```bash
    ssh-keygen -t rsa -b 4096 -C administrator@camelz.io -f $CAMELZ_HOME/keys/camelz_administrator_id_rsa
    ```

1. **Create administrator SSH Key** (macOS)

    ```bash
    ssh-keygen -m PEM -t rsa -b 4096 -C administrator@camelz.io -f $CAMELZ_HOME/keys/camelz_administrator_id_rsa
    ```

1. **Generate administrator SSH Key Fingerprint in AWS KeyPair Format**

    ```bash
    openssl pkey -in $CAMELZ_HOME/keys/camelz_administrator_id_rsa -pubout -outform DER | openssl md5 -c
    ```

1. **Remove Passphrase from administrator SSH Private Key**

    ```bash
    openssl rsa -in $CAMELZ_HOME/keys/camelz_administrator_id_rsa -out $CAMELZ_HOME/keys/camelz_administrator_id_rsa.insecure
    ```

1. **Change Passphrase on administrator SSH Private Key**

    ```bash
    ssh-keygen -p -f $CAMELZ_HOME/keys/camelz_administrator_id_rsa
    ```

1. **Change Passphrase on administrator SSH Private Key** (macOS)

    ```bash
    ssh-keygen -m PEM -p -f $CAMELZ_HOME/keys/camelz_administrator_id_rsa
    ```
