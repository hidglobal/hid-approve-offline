# HID Approve Offline Activation

This is an example application that shows the sequence to activate a HID Approve token in offline mode.  The sequence is the following:

1. Login as the OIDC application to obtain an access token
2. Find the user you want to register the token for
3. Create a Provisioning Request for the user with device type DT_APPR_OT
4. Create a Deep Link using the provisioning request
5. Present the Deep Link to the user

## Prerequisites

You will need an OpenID Connect client application created. If you are using the HID Authentication Service, create an application in the HID Admin Portal. If you are using the HID Appliance, create a user with a system login static password and then create an adapter of type OpenID Connect with the same name as the user.

To run this example you can define the following environment variables:

```bash
HID_AUTH_URL=https://{appliance or service address}/idp/{tenant}
HID_SCIM_URL=https://{appliance or service address}/scim/{tenant}
HID_CLIENT_ID={oidc client id}
HID_CLIENT_SECRET={oidc client secret}
```
