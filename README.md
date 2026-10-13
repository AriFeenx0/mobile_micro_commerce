# mobile_micro_commerce

A new Flutter project.

## Cloudinary Image Uploads

Book cover, order slip, and chat image uploads use Cloudinary's unsigned Upload API preset. In Cloudinary Console, create an **unsigned** upload preset and restrict it to image formats the app accepts (JPG, PNG, or WebP). Set the preset's asset folder as desired; the app sends identifying values as asset context.

Pass the Cloudinary cloud name and preset name when launching the app:

```powershell
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud-name --dart-define=CLOUDINARY_UPLOAD_PRESET=your-unsigned-preset
```

The cloud name and unsigned preset are client-visible. Do not put the Cloudinary API secret in the Flutter app. Configure upload restrictions on the preset because anyone who obtains its name can attempt unsigned uploads. Signed uploads and deleting Cloudinary assets require a trusted backend; removing a book currently removes its Firestore record but does not delete its Cloudinary files.

## Order stock reservations

Checkout reserves the requested quantities in a Firestore transaction for 15
minutes. Submitting a slip in time keeps the reservation active until the shop
confirms or rejects the payment. Rejected payments release the reservation;
confirmed payments convert it to a stock deduction. Expired reservations are
excluded from available stock and are pruned when a later checkout touches the
same volume. An abandoned order document can remain marked as awaiting payment
until the customer tries to submit its slip or the same volume is checked out
again.

Reservations are currently coordinated by the Flutter client and Firestore
Security Rules. For deployments exposed to untrusted clients, move reservation
and payment state transitions to a trusted backend (such as Cloud Functions)
before launch.
