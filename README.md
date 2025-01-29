# HID Approve Offline Activation

This is an example application that shows the sequence to activate a HID Approve token in offline mode.  The sequence is the following:

1. Login as the OIDC application to obtain an access token
2. Find the user you want to register the token for
3. Create a Provisioning Request for the user with device type DT_APPR_OT
4. Create a Deep Link using the provisioning request
5. Present the Deep Link to the user

## Prerequisites

You will need an OpenID Connect client application created. If you are using the HID Authentication Service, create an application in the HID Admin Portal. If you are using the HID Appliance, create a user with a system login static password and then create an adapter of type OpenID Connect with the same name as the user.

Users in Active Directory are visible through SCIM in the appliance only when they have an associated authentication record. The application attempts a dummy authentication to create an LDAP passthrough record. For this to work, you need to configure the adapter to use the `CH_SSP` in the field 'Code of the channel thought which an end user of the client authenticates and `AT_LDAP` in the field 'Code of the default authentication policy for the end user'.

The application is served with TLS, so you will need a certificate and key file in PKCS#12 format. Put them in `server_cert.pfx` in the root of the project. By default, the application will try to use port 443 but that requires that you run in with elevated privileges. In Windows open a command prompt as administrator and in Linux use sudo to run `npm run start`.

To run this example you must define the following environment variables:

```bash
HID_AUTH_URL=https://{appliance or service address}/idp/{tenant}
HID_SCIM_URL=https://{appliance or service address}/scim/{tenant}
HID_CLIENT_ID={oidc client id}
HID_CLIENT_SECRET={oidc client secret}
P12_PASSPHRASE={p12 passphrase}
```

If you prefer to provide cretentials when launching the application, then provide the client_id, client_secret and p12_passphrase as command line arguments, like this:

```
node server.js {client_id} {client_secret} {p12_passphrase}
```

Also note that if your appliance is using a certificate issued by an internal CA, you may need to set the `NODE_EXTRA_CA_CERTS` environment variable to point to the CA certificate file.

## Installation

You need to install [node.js](https://nodejs.org/) and clone this repository in your machine, either downloading the zip file or using git:
`git clone https://github.com/hidglobal/hid-approve-offline-activation.git`

Then, open a command prompt and navigate to the folder where you cloned the repository and run the following command to install the dependencies:
`npm install`
