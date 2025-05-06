# Audio/Video Processing Pipeline on AWS

This project outlines a modular, cloud-native workflow for automating audio and video media processing using AWS services. It handles media uploads, conversion, metadata extraction, and asset preparation for public delivery.

> **Note:** This is a generic template. You’ll need to customize bucket names, IAM roles, CORS policies, lifecycle rules, file paths, and environment variables to match your environment and security posture.

---

## 🗂 Folder Structure Overview

- `s3://<watch-bucket>/inputs/`: Incoming upload directory (watch folder)
- `s3://<public-bucket>/`: Destination for processed media
  - `/audiovideo/` — Transcoded media files
  - `/closed-caption/` — VTT caption files
  - `/json/` — Video metadata
  - `/original/` — Raw uploaded files
  - `/thumbnail/` — Splash images (JPG)

---

## 📥 Upload & Initial Trigger

1. Files are uploaded via a web interface (e.g., using `plupload`) to the `inputs/` folder.
2. This triggers an AWS Lambda function (e.g., `MediaLambdaHandler`).
3. Determines file type (audio/video) and checks for multipart CHUNK uploads.
   - CHUNK files (e.g., `.CHUNK0`, `.CHUNK1`) are ignored until fully assembled.

---

## 🧠 Media Analysis

Once a complete file is detected:
- A custom-compiled binary (e.g., `pymediainfo`) analyzes the file.
- Extracts key metadata: media type, resolution, duration, etc.

---

## 🎧 Audio File Handling

- MP3 files are moved directly to the final media bucket (e.g., `audiovideo/`).
- No additional processing is required.

---

## 🎞 Video File Conversion

1. Metadata determines which resolutions to create (e.g., skip 1080p for a 720p source).
2. A template job configuration (e.g., `job.json`) is modified in-memory.
3. AWS MediaConvert is invoked to:
   - Create multiple resolution variants (360p, 480p, 720p, 1080p).
   - Append resolution to filenames (`filename_1080p.mp4`).
   - Store the files in the designated output folder.

---

## 🧾 Metadata & Thumbnails

- Video metadata is saved as a `.json` file with a matching name in the `/json/` folder.
- A separate Lambda function (e.g., `SaveVideoFrame`) extracts a JPG frame (default at 7 seconds).
- The thumbnail is saved to the `/thumbnail/` folder.

---

## 📝 Closed Caption Support

- Caption files uploaded by users are converted to `.vtt` if necessary.
- They are stored with no additional processing in `/closed-caption/`.

---

## 🧰 Codebase & Deployment Artifacts

**Lambda Source Code**
- `MediaLambdaHandler.py` — Main Lambda for processing uploads
- `SaveVideoFrame.py` — Lambda for thumbnail extraction
- `job.json` — Template for AWS MediaConvert job settings

**Custom Binaries**
- `pymediainfo` and `ffmpeglayer` should be compiled and packaged as Lambda layers compatible with your Python runtime (e.g., 3.7).
- A good starting guide:  
  https://binx.io/blog/2017/10/20/how-to-install-python-binaries-in-aws-lambda/

---

## ⚙️ Lambda Configuration Notes

### MediaLambdaHandler

- **Environment Variables** (set per deployment):
  - `APPLICATION_NAME`
  - `DESTINATION_BUCKET`
  - `MEDIACONVERT_ROLE_ARN`
- **Basic Settings**:
  - Runtime: Python 3.7+
  - Memory: 128 MB
  - Timeout: 2 minutes
  - S3 Trigger: Event type `ObjectCreated` with prefix `inputs/`

### SaveVideoFrame

- **Important**: Thumbnail generation is memory-intensive.
- **Settings**:
  - Runtime: Python 3.7+
  - Memory: 3008 MB
  - Timeout: 30 seconds
  - Trigger: Upload to `/original/` folder

---

## 📡 Monitoring & Notifications

- CloudWatch logs are enabled by default; all scripts use `logger.info()` for traceability.
- An EventBridge (CloudWatch Events) rule can be set up to notify an SNS topic when MediaConvert jobs complete.
  - Subscribers can include dev team members, automated systems, or webhooks.

---

## 🔒 Security & Access

> ⚠️ You are responsible for defining IAM roles, policies, and bucket configurations.

- **Watchfolder S3 Bucket**:
  - Should block public access.
  - Recommended: Lifecycle rule to delete old uploads after 24 hours.

- **Public Delivery Bucket**:
  - Should be read-accessible as needed (e.g., via CloudFront or direct links).
  - Configure CORS policy to allow cross-origin access as necessary.

---

## 📌 Deployment Tips

- Use Infrastructure-as-Code (e.g., CloudFormation, Terraform, CDK) to manage:
  - Lambda functions
  - S3 buckets and policies
  - MediaConvert roles and permissions
- Set up versioning on buckets if retaining media history is needed.
- Automate unit tests for metadata validation and file integrity.

---

## 🧪 Testing

For local testing:
- Use a tool like [localstack](https://github.com/localstack/localstack) to mock AWS services.
- Upload test media files to a local S3 bucket to simulate the full pipeline.

---

## 💬 Final Thoughts

This pipeline offers a flexible blueprint for media processing in AWS. It’s scalable, customizable, and designed for clarity. Just plug in your infrastructure, tweak the knobs, and let the automation do the heavy lifting.

---

## 🛠 To-Do / Customization Checklist

- [ ] Replace bucket names (`<watch-bucket>`, `<public-bucket>`)
- [ ] Replace placeholder ARNs and role names
- [ ] Configure lifecycle & CORS policies
- [ ] Compile and upload Lambda layers (`pymediainfo`, `ffmpeglayer`)
- [ ] Setup CloudWatch and SNS alerts for your team

