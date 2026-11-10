---
source: kbase
url: https://kbase.zetaris.com/knowledge/installation-guide-for-security-truststore-and-certificates
title: "Installation Guide for Security - TrustStore and Certificates"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: cba02f3ee2c875d5bcff1943410b601ed4937ff9230984c353001fec26a29df8
---
# Installation Guide for Security - TrustStore and Certificates

## Zetaris NDP provides one-way SSL connections over TLS and uses a global truststore to manage all trusted Root CA and Intermediary certificate chain entries and is located in src/data/key-trust-store.

### Overview

Zetaris NDP provides one-way SSL connections over TLS and uses a global truststore to manage all trusted Root CA and Intermediary certificate chain entries and is located in src/data/key-trust-store.

Truststore format is pkcs12 with the file extension .p12 and follows the JSSE 4.0 Standard <reference to standard>.

[OpenSSL](https://zetaris.atlassian.net/wiki/spaces/LIGT/pages/2244640821/Installation+Guide+for+Security+-+TrustStore+and+Certificates#Appendix-1---OpenSSL-and-KeyTool-operations) is used to generate keys, certificates and is the preferred method since it is open source.

[Keytool](https://zetaris.atlassian.net/wiki/spaces/LIGT/pages/2244640821/Installation+Guide+for+Security+-+TrustStore+and+Certificates#Appendix-1---OpenSSL-and-KeyTool-operations) is specifically used to conduct operations on keystores and truststores, including changing password, changing format and more.

In order to secure JDBC connections over SSL/TLS, Zetaris NDP provides some supported database drivers.

### Truststore

#### How to Configure Zetaris NDP with Truststore

1.  By default, Zetaris NDP generates an initialised truststore. First, rename the change\_it.p12 file. The default type is pkcs12. Optionally, you can use Keytool or OpenSSL to create a new truststore file if you wish to use a different format.
    
2.  Change the password using the Keytool command.
    
3.  Modify start-lightning-with-xxx.sh , start-lightning-server-with-xxx.sh(see Truststore Location below)
    
    1.  Make sure the filename matches the TRUSTSTORE\_PATH and the new password matches TRUSTSTORE\_PASSWD.
        
        ```
        1 TRUSTSTORE_PATH="$FWDIR/data/key-trust-store/change_it.p12"2 TRUSTSTORE_PASSWD=<REDACTED> TRUSTSTORE_TYPE="pkcs12"45 # if using java 8, type is "jks", java 9+ is "pkcs12"
        ```
        

### Truststore Location

Location is src/data/key-trust-store. This can also be set to the system $JAVA\_HOME/jre/security/cacerts within the following \`Zetaris NDP\` bootstrap scripts, depending on your application’s running mode:

-   ```
    src/universal/bin/lightning-sql-with-xxx.sh
    ```
    
-   ```
    src/universal/bin/start-lightning-server-with-xxx.sh
    ```
    

The scripts running derby are only used for internal purposes, but can be also changed.

-   ```
    src/universal/bin/lightning-sql-with-derby.sh
    ```
    
-   ```
    src/universal/bin/start-lightning-server-with-derby.sh
    ```
    

### Change Truststore Password

```
1 keytool -storepasswd2 -new newpassword3 -keystore truststore.p124 -storepass change_it5 -storetype pkcs12 
```

### IMPORTANT: User-Defined Truststore is restricted

Efforts have been made to restrict users from providing their own truststore path, in order to enforce the use of the Zetaris NDP Truststore.

It is the responsibility of the administrator to setup and then manage the truststore as a precursor to enabling JDBC over SSL/TLS.

### Certificates

#### Server Certificates

TrustStore Certificates follow X.509 Standard [\[1\]](https://datatracker.ietf.org/doc/html/rfc5280) and are comparable by fingerprint (SHA1 encoded) and unique alias.

### Import Certificate into the Truststore

Import Certificate command must contain a unique alias and certificate path.

Prior to import, a certificate must be uploaded to Zetaris NDP File System (dffs://) before being imported into the Truststore.

```
1 IMPORT CERTIFICATE OPTIONS(2   alias "mysql",3   certificate "dffs://key-trust-store/BaltimoreCyberTrustRoot.crt.pem"4 );
```

### List Certificates of the Truststore

List Certificate command will return a list of validated and unique certificate entries created by the logged-in user from a given organisation.

```
1 LIST CERTIFICATES;
```

### Delete Certificates from the Truststore

Delete Certificate relies on the unique alias created by a user within an organisation to remove the given certificate.

```
1 DELETE CERTIFICATE “mysql”;
```

### References

1.  [Internet X.509 Public Key Infrastructure Certificate and Certificate Revocation List (CRL) Profile](https://datatracker.ietf.org/doc/html/rfc5280) [![](https://www.ietf.org/lib/dt/8.4.0/ietf/images/ietf-logo-nor-16.png)RFC 5280 - Internet X.509 Public Key Infrastructure Certificate and Certificate Revocation List (CRL) Profile](https://datatracker.ietf.org/doc/html/rfc5280)
    
2.  [The Transport Layer Security (TLS) Protocol Version 1.2](https://datatracker.ietf.org/doc/html/rfc5246) [![](https://www.ietf.org/lib/dt/8.3.1/ietf/images/ietf-icon-blue3.png)RFC 5246 - The Transport Layer Security (TLS) Protocol Version 1.2](https://datatracker.ietf.org/doc/html/rfc5246)[](https://datatracker.ietf.org/doc/html/rfc5246)
    
3.  [Application-Layer TLS draft-friel-tls-atls-01](https://datatracker.ietf.org/doc/html/draft-friel-tls-atls-01) [![](https://www.ietf.org/lib/dt/8.4.0/ietf/images/ietf-logo-nor-16.png)draft-friel-tls-atls-01](https://datatracker.ietf.org/doc/html/draft-friel-tls-atls-01)
    
4.  [Automated Certificate Management Environment (ACME) TLS Application-Layer Protocol Negotiation (ALPN) Challenge Extension](https://datatracker.ietf.org/doc/html/rfc8737) [![](https://www.ietf.org/lib/dt/8.4.0/ietf/images/ietf-logo-nor-16.png)RFC 8737 - Automated Certificate Management Environment (ACME) TLS Application-Layer Protocol Negotiation (ALPN) Challenge Extension](https://datatracker.ietf.org/doc/html/rfc8737)
