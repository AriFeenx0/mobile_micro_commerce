# mobile_micro_commerce

A new Flutter project.

## Cloudinary Image Uploads

Book cover uploads use Cloudinary's unsigned Upload API preset. In Cloudinary Console, create an **unsigned** upload preset and restrict it to image formats the app accepts (JPG, PNG, or WebP). Set the preset's asset folder to `books`; the app sends `owner_id` and `book_id` as asset context.

Pass the Cloudinary cloud name and preset name when launching the app:

```powershell
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud-name --dart-define=CLOUDINARY_UPLOAD_PRESET=your-unsigned-preset
```

The cloud name and unsigned preset are client-visible. Do not put the Cloudinary API secret in the Flutter app. Configure upload restrictions on the preset because anyone who obtains its name can attempt unsigned uploads. Signed uploads and deleting Cloudinary assets require a trusted backend; removing a book currently removes its Firestore record but does not delete its Cloudinary files.
