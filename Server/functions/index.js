const {
  log,
  info,
  debug,
  warn,
  error,
  write,
} = require("firebase-functions/logger");
const functions = require("firebase-functions");
//const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const { defineInt, defineString, defineSecret } = require('firebase-functions/params');
const secretStripeKey = defineSecret("STRIPE_SECRET_KEY");
//const testStripeKey = defineSecret("TEST_KEY");
//const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
const admin = require("firebase-admin");

//const serviceAccount = require("C:\\Users\\lukep\\Documents\\uni\\movein\\serviceAccount.js");
admin.initializeApp({
    //credential: applicationDefault(),
    //credential : admin.credential.cert(serviceAccount),
    projectId: 'test-7a857',
});

exports.deleteStripeCustomer = functions.region('europe-west2').https.onRequest(async (req, res) => {
  try {
    const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
    const { customerId } = req.body;
    log(req.body);
    const customer = await stripe.customers.retrieve(customerId);

    if (!customer) {
      // If the customer doesn't exist, return an error message
      res.status(404).json({ error: 'Customer not found.' });
      return;
    }
    // Delete the customer in Stripe
    await stripe.customers.del(customerId);
    // Return a success message
    res.status(200).json({ message: 'Customer deleted successfully.' });
  } catch (err) {
    console.error(error);
    res.status(500).json({ error: err });
  }
});

exports.createStripeSetupIntent = functions.region('europe-west2').https.onRequest(async (req, res) => {
  try {
    const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
    // Get the user's Firebase UID from the request (You need to authenticate the user)
    const { uid } = req.body;
    const userRecord = await admin.auth().getUser(uid);
    // Check if the user already has a Stripe customer ID associated with their account
    const customer = await stripe.customers.list({ email: userRecord.email });
    let stripeCustomerId;
    if (customer.data.length === 0) {
        const stripeCustomer = await stripe.customers.create({
        email: userRecord.email,
        // You can add more customer data here as needed
      });
      stripeCustomerId = stripeCustomer.id;
      // Associate the Stripe customer ID with the Firebase user UID
      await admin.firestore().collection('Users').doc(uid).update({
        StripeCustomerId: stripeCustomer.id,
      });
    } else {
      stripeCustomerId = customer.data[0].id;
    }
    // Create a Setup Intent for the customer
    const setupIntent = await stripe.setupIntents.create({
      customer: stripeCustomerId, // Use existing customer ID if available
      usage: 'off_session', // Indicates that this Setup Intent is for future off-session payments
    });

    // Return the Setup Intent client secret to the client
    res.status(200).json({
    clientSecret: setupIntent.client_secret,
    customerId: stripeCustomerId,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err });
  }
});

exports.checkCustomerSubscriptions = functions.region('europe-west2').https.onRequest(async (req, res) => {
  try {
    const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
    // Extract the customerId from the request body
    const { customerId } = req.body;

    // Retrieve the customer from Stripe using the customerId
    const customer = await stripe.customers.retrieve(customerId);

    if (!customer) {
      // If the customer doesn't exist, return an error message
      res.status(404).json({ error: 'Customer not found.' });
      return;
    }

    // Retrieve the customer's subscriptions from Stripe
    const subscriptions = await stripe.subscriptions.list({
      customer: customerId,
    });

    const activeSubscriptions = subscriptions.data.filter(subscription => subscription.plan.active === true);

    if (activeSubscriptions.length > 0) {
      res.status(200).json({ hasActiveSubscriptions: true });
    } else {
      res.status(200).json({ hasActiveSubscriptions: false });
    }
  } catch (err) {
    console.error(error);
    res.status(500).json({ error: err });
  }
});

exports.makeDefaultPayment = functions.region('europe-west2').https.onRequest(async (req, res) => {
  try {
      const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
    const {customerId, paymentId } = req.body; // Include the user UID, Stripe Customer ID, and plan ID in the request body

    await stripe.customers.update(customerId, {
          invoice_settings: {
            default_payment_method: paymentId,
          },
        });

    res.status(200).json({message: "succeeded"});
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

exports.createStripeSubscription = functions.region('europe-west2').https.onRequest(async (req, res) => {
  try {
      const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
    const {uid, customerId, planId } = req.body; // Include the user UID, Stripe Customer ID, and plan ID in the request body

    // Create a subscription for the user
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ plan: planId }], // Replace with your specific plan ID
      // You can add more subscription options here as needed
    });

    await admin.firestore().collection('Users').doc(uid).update({
            Subscribed: true,
          });

    // Return the created subscription object to the client
    res.status(200).json({ subscription });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

exports.deleteStripeSubscription = functions.region('europe-west2').https.onRequest(async (req, res) => {
  try {
      const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
     const sig = req.headers['stripe-signature'];

    // Create a subscription for the user
    let event;

      try {
      const requestBodyString = Buffer.from(req.body).toString();
        event = stripe.webhooks.constructEvent(requestBodyString, sig, process.env.STRIPE_DEL_SECRET);
      } catch (err) {
        res.status(400).send(`Webhook Error: ${err.message}`);
        return;
      }

      // Handle the event
      switch (event.type) {
        case 'customer.subscription.deleted':
          const customerSubscriptionDeleted = event.data.object;

          const userSnapshot = await admin.firestore().collection('Users')
                  .where('StripeCustomerId', '==', customerId)
                  .get();

                // Update the "Subscribed" field to false for the matching document
                if (!userSnapshot.empty) {
                  const userDoc = userSnapshot.docs[0];
                  await userDoc.ref.update({
                    Subscribed: false,
                  });
                }
          break;
        // ... handle other event types
        default:
          console.log(`Unhandled event type ${event.type}`);
      }
    res.status(200).json({ message : "subscription deleted successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

exports.checkDefaultPaymentMethod = functions.region('europe-west2').https.onRequest(async (req, res) => {
  try {
        const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

    const { customerId } = req.body; // Include the Stripe Customer ID in the request body


    const customer = await stripe.customers.retrieve(customerId);

    // Check if the customer has a default payment method set
    const hasDefaultPaymentMethod = !!customer.invoice_settings.default_payment_method;

    let paymentMethod = null;

    // If a default payment method is set, retrieve its details
    if (hasDefaultPaymentMethod) {
      // Retrieve the payment method using retrievePaymentMethod
      const paymentMethodId = customer.invoice_settings.default_payment_method;
      const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);

    }

    // Return the result to the client
    res.status(200).json({ hasDefaultPaymentMethod, paymentMethod });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err });
  }
});

exports.updateEmailVerificationStatus = functions.region('europe-west2').pubsub.schedule("every day 00:00").timeZone("GMT").onRun(async (context) => {
    try {
        // Query for users with emailVerified == false
        const usersQuery = await admin.firestore().collection("Users").where("EmailVerified", "==", false).get();

        const batch = admin.firestore().batch();

        // Check email verification status for each user
        usersQuery.forEach(async (doc) => {
            const user = doc.data();

            // Check if the user's email is verified in Firebase Authentication
            const userRecord = await admin.auth().getUser(user.uid);

            if (userRecord && userRecord.emailVerified) {
                // Update the email verification status for this user
                batch.update(doc.ref, { emailVerified: true });
                console.log(`Email verification status updated for user ${user.uid}`);
            }
        });

        // Commit the batch update
        await batch.commit();

        console.log("Email verification status update completed.");
    } catch (err) {
        console.error("Error updating email verification status:", err);
    }
    return null;
});

exports.pruneTokens = functions.region('europe-west2').pubsub.schedule('0 0 1,16 * *').timeZone('GMT').onRun(async (context) => {
  const EXPIRATION_TIME = 1000 * 60 * 60 * 24 * 182;

  const staleTokensResult = await admin.firestore().collection('fcmTokens')
      .where("timestamp", "<", Date.now() - EXPIRATION_TIME)
      .get();
  // Delete devices with stale tokens
  staleTokensResult.forEach(function(doc) { doc.ref.delete(); });
});

exports.sendGroupNotification = functions.region('europe-west2').firestore.document('Groups/{groupId}/Messages/{message}').onCreate(async (snap, context) => {
        const message = snap.data();
        const groupId = context.params.groupId;
        const sentBy = message.sentBy;

        // Fetch the group document to get the "Members" field
        const groupDocRef = admin.firestore().collection('Groups').doc(groupId);
        const groupDocSnapshot = await groupDocRef.get();

        if (groupDocSnapshot.exists) {
            const groupName = groupDocSnapshot.data().GroupName;
            const memberIds = groupDocSnapshot.data().Members || [];

            // Fetch FCM tokens for each member
            const tokensPromises = memberIds.map(async (memberId) => {
                const tokenDocRef = admin.firestore().collection('fcmTokens').doc(memberId);
                const tokenDocSnapshot = await tokenDocRef.get();

                if (tokenDocSnapshot.exists) {
                    return tokenDocSnapshot.data().Token;
                } else {
                    console.error(`FCM token document for member ${memberId} does not exist.`);
                    return null;
                }
            });

            const tokens = await Promise.all(tokensPromises);

            // Filter out null values (in case of missing tokens)
            const validTokens = tokens.filter((token) => token !== null);

            // Fetch sender's name from the Users collection
            const senderDocRef = admin.firestore().collection('Users').doc(sentBy);
            const senderDocSnapshot = await senderDocRef.get();

            if (senderDocSnapshot.exists) {
                const senderData = senderDocSnapshot.data();
                const senderName = `${senderData.ForeName} ${senderData.SurName}`;

                // Customize the payload with the sender's name and a custom image URL
                const payload = {
                    notification: {
                        title: `${groupName}: ${senderName}`,
                        body: message.text,
                        imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
                    },
                    data: {
                        sender: senderName,
                        time: message.sent.toDate().toString(),
                    },
                    tokens: validTokens,
                };

                return admin.messaging().sendMulticast(payload);
            } else {
                console.error(`Sender document with ID ${sentBy} does not exist.`);
                return null;
            }
        } else {
            console.error(`Group document with ID ${groupId} does not exist.`);
            return null;
        }
    });

exports.sendDmNotification = functions.region('europe-west2').firestore.document('DirectMessages/{groupId}/Messages/{message}').onCreate(async (snap, context) => {
        const message = snap.data();
        const groupId = context.params.groupId;
        const sentBy = message.sentBy;

        // Fetch the group document to get the "Members" field
        const groupDocRef = admin.firestore().collection('DirectMessages').doc(groupId);
        const groupDocSnapshot = await groupDocRef.get();

        if (groupDocSnapshot.exists) {
            const memberIds = groupDocSnapshot.data().Members || [];

            // Fetch FCM tokens for each member
            const tokensPromises = memberIds.map(async (memberId) => {
                const tokenDocRef = admin.firestore().collection('fcmTokens').doc(memberId);
                const tokenDocSnapshot = await tokenDocRef.get();

                if (tokenDocSnapshot.exists) {
                    return tokenDocSnapshot.data().Token;
                } else {
                    console.error(`FCM token document for member ${memberId} does not exist.`);
                    return null;
                }
            });

            const tokens = await Promise.all(tokensPromises);

            // Filter out null values (in case of missing tokens)
            const validTokens = tokens.filter((token) => token !== null);

            // Fetch sender's name from the Users collection
            const senderDocRef = admin.firestore().collection('Users').doc(sentBy);
            const senderDocSnapshot = await senderDocRef.get();

            if (senderDocSnapshot.exists) {
                const senderData = senderDocSnapshot.data();
                const senderName = `${senderData.ForeName} ${senderData.SurName}`;

                // Customize the payload with the sender's name and a custom image URL
                const payload = {
                    notification: {
                        title: `$senderName`,
                        body: message.text,
                        imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
                    },
                    data: {
                        sender: senderName,
                        time: message.sent.toDate().toString(),
                    },
                    tokens: validTokens,
                };

                return admin.messaging().sendMulticast(payload);
            } else {
                console.error(`Sender document with ID ${sentBy} does not exist.`);
                return null;
            }
        } else {
            console.error(`DM document with ID ${groupId} does not exist.`);
            return null;
        }
    });

exports.userDocUpdated = functions.region('europe-west2').firestore.document('Users/{userId}').onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const newData = change.after.data();
    const oldData = change.before.data();

    if (newData && oldData) {
        const newFriends = newData.Friends || [];
        const oldFriends = oldData.Friends || [];
        const newInvites = newData.FriendInvites || [];
        const oldInvites = oldData.FriendInvites || [];
        const newGroupInvites = newData.GroupInvites || [];
        const oldGroupInvites = oldData.GroupInvites || [];
        const newJoined = newData.GroupJoined || [];
        const oldJoined = oldData.GroupJoined || [];

        // Fetch the FCM token for the user once
        const tokenDocRef = admin.firestore().collection('fcmTokens').doc(userId);
        const tokenDocSnapshot = await tokenDocRef.get();
        if (!tokenDocSnapshot.exists) {
            console.error(`FCM token document for user ${userId} does not exist.`);
            return null;
        }
        const token = tokenDocSnapshot.data().Token;

        // Send notifications for each event
        const notifications = [];

        if (newFriends.length > oldFriends.length) {
            notifications.push({
                title: 'Accepted Friend Request',
                imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
            });
        }

        if (newInvites.length > oldInvites.length) {
            notifications.push({
                title: 'New Friend Request',
                imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
            });
        }

        if (newGroupInvites.length > oldGroupInvites.length) {
            notifications.push({
                title: 'New Group Invite',
                imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
            });
        }

        if (newJoined.length > oldJoined.length) {
            notifications.push({
                title: 'Application Accepted!',
                imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
            });
        }

        const payloadPromises = notifications.map((notification) => {
            const payload = {
                notification: notification,
                tokens: [token], // Send to the user's token
            };

            return admin.messaging().sendMulticast(payload);
        });

        await Promise.all(payloadPromises);
    }

    return null; // Return a result if needed
});

exports.groupDocUpdated = functions.region('europe-west2').firestore.document('Groups/{groupId}').onUpdate(async (change, context) => {
    const groupId = context.params.groupId;
    const newData = change.after.data();
    const oldData = change.before.data();
    if (newData && oldData) {
        const newMembers = newData.Members || [];
        const oldMembers = oldData.Members || [];
        const newApplicants = newData.Applicants || [];
        const oldApplicants = oldData.Applicants || [];

        const addedMembers = newMembers.filter(memberId => !oldMembers.includes(memberId));
        const addedApplicants = newApplicants.filter(applicantId => !oldApplicants.includes(applicantId));

        const groupDocRef = admin.firestore().collection('Groups').doc(groupId);
        const groupDocSnapshot = await groupDocRef.get();
        if (groupDocSnapshot.exists) {
            const groupName = groupDocSnapshot.data().GroupName;
            const memberIds = groupDocSnapshot.data().Members || [];

            // Fetch FCM tokens for each member
            const tokensPromises = memberIds.map(async (memberId) => {
                const tokenDocRef = admin.firestore().collection('fcmTokens').doc(memberId);
                const tokenDocSnapshot = await tokenDocRef.get();

                if (tokenDocSnapshot.exists) {
                    return tokenDocSnapshot.data().Token;
                } else {
                    console.error(`FCM token document for member ${memberId} does not exist.`);
                    return null;
                }
            });
            const tokens = await Promise.all(tokensPromises);
            const validTokens = tokens.filter((token) => token !== null);
            if (addedMembers.length > 0) {
                const payload = {
                    notification: {
                        title: `New ${groupName} Member!`,
                        imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
                    },
                    tokens: validTokens,
                };
                await admin.messaging().sendMulticast(payload);
            }

            if (addedApplicants.length > 0) {
                const payload = {
                    notification: {
                        title: `New ${groupName} applicant`,
                        imageUrl: 'https://movein.blob.core.windows.net/movein/moveinlogo2.jpg',
                    },
                    tokens: validTokens,
                };

                await admin.messaging().sendMulticast(payload);
            }
        } else {
            console.error(`Group document with ID ${groupId} does not exist.`);
        }
    }

    return null; // Return a result if needed
});
