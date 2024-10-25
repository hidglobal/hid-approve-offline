require('dotenv').config();
const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static('public'));

app.post('/register', (req, res) => {
  console.log(`Registering user: ${req.body.username}`);
  const authBasic = Buffer.from(`${process.env.HID_CLIENT_ID}:${process.env.HID_CLIENT_SECRET}`, 'utf8').toString('base64');

  // 1. Get application access token
  fetch(`${process.env.HID_AUTH_URL}/token`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${authBasic}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials'
  })
  .then((response) => {
    if (response.ok) {
      response.json().then((data) => {
        let access_token = data.access_token;
        if (typeof(access_token) === 'undefined') {
          console.log('Error: ' + JSON.stringify(data));
          res.status(500).send('Server is not configured correctly');
          return;
        }
        // 2. Find the user
        fetch(`${process.env.HID_SCIM_URL}/Users/.search`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${access_token}`,
            'Content-Type': 'application/scim+json'
          },
          body: JSON.stringify({filter: `userName eq "${req.body.username}"`})
        })
        .then((response) => {
          if (response.ok) {
            response.json().then((data) => {
              console.log(`User: ${data.resources[0].displayName} (${data.resources[0].id})`);
              let userid = data.resources[0].id;
              // 3. Create provisioning request
              const provisionRequest = {
                schemas: [
                  "urn:hid:scim:api:idp:2.0:Provision"
                ],
                deviceType: "DT_APPR_OT",
                owner: {
                  value: userid
                },
                attributes: [
                  {
                    name: "AUTH_TYPE",
                    value: "AT_EMPOTP",
                    readOnly: false
                  }
                ]
              };
              fetch(`${process.env.HID_SCIM_URL}/Device/Provision`, {
                method: 'POST',
                headers: {
                  'Authorization': `Bearer ${access_token}`,
                  'Content-Type': 'application/scim+json'
                },
                body: JSON.stringify(provisionRequest)
              })
              .then((response) => {
                if (response.ok) {
                  response.json().then((data) => {
                    let payload = data.attributes[0].value;
                    let code = [...payload.match(/secret=(.*)&issuer/)];
                    console.log(`Provisioning response: ${payload}`);
                    let deepLink = `https://approve.app.link/activate?name=HID%20Approve%20OTP&qrcode=${Buffer.from(payload).toString('base64')}`;
                    res.status(200).send(`
                      <html>
                        <header><title>Activation Link</title><link rel="stylesheet" type="text/css" href="/css/styles.css"></header>
                        <body><div class="page page--full-width"><main class="page__content"><div class="region region--content"><section class="section section--layout-onecol">
                          <h2>Activation Link</h2>
                          <p>Click the link below to activate HID Approve on your device:</p>
                          <div>
                          <a href="${deepLink}"><button class="button button-primary">Activate</button></a>
                          </div>
                          <p class="description">Or manually enter the following code into the HID Approve app: ${code[1]}</p>
                        </section></div></main></div></body>
                      </html>
                    `);
                  });
                }
              })
            });
          }
        })
      });
    } else {
      console.log('Error:', response.statusText);
    }
  })
  .catch((error) => {
    console.error('Error:', error);
  });
});
      

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});