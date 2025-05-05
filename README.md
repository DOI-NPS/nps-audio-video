# nps-audio-video
VideoJS and Plupload script examples for the player and upload process. MediaConvert script and AWS Lambda code for the main processing script. Documentation.

# Audio/Video AWS Processing Pipeline

This document provides a detailed overview of the Audio/Video processing pipeline implemented using AWS services. It is designed to help engineers and developers understand, replicate, and troubleshoot the setup.

---

📌 Overview

Audio and video files uploaded via a front-end system are processed through a structured AWS pipeline. The pipeline handles metadata extraction, media transcoding, thumbnail generation, and final delivery via S3.

---

🛠 Upload Process

- Uploader: plupload sends media files to:
  S3://nps-audiovideo-watchfolder/inputs
- Trigger: Lambda function VDOLambdaConvert is automatically triggered on upload.

---

🧩 Chunk File Detection

- CHUNK files have a .CHUNK# extension.
- The Lambda waits until all chunks are merged into a single complete file.

---

🧠 Media Type & Metadata Extraction

- Uses pymediainfo to determine:
  - File type: audio or video
  - Metadata: duration, resolution, etc.

---

🎧 Audio File Handling

- MP3 files are moved directly to:
  S3://nps-audiovideo/audiovideo

---

🎥 Video File Handling

1. Video metadata is analyzed.
2. job.json for AWS MediaConvert is modified accordingly.
3. AWS MediaConvert is triggered.
4. Outputs:
   - Converted files → S3://nps-audiovideo/audiovideo
   - Original video → S3://nps-audiovideo/original
   - Metadata JSON → S3://nps-audiovideo/json
   - Naming: filename1080p.mp4, filename720p.mp4, etc.

---

🖼 Thumbnail Generation

- Lambda SaveVideoFrame is triggered by upload to original/
- Uses ffmpeglayer to extract a frame at 7 seconds
- Output is saved to:
  S3://nps-audiovideo/thumbnail

---

📣 SNS Notification

- On MediaConvert job completion:
  - CloudWatch Event Rule VODNotifyEventRule triggers SNS VODNotification
  - Notifies: system administrator & nps_web@nps.gov

---

📝 Closed Caption Support

- Files converted to VTT (if necessary)
- Stored in:
  S3://nps-audiovideo/closed-caption

---

🔧 Lambda Configuration

VDOLambdaConvert
- Environment Variables:
  - Application=VOD
  - DestinationBucket=nps-audiovideo
  - MediaConvertRole=arn:aws:iam::693476370600:role/nps_mediaconvert_role
- Runtime: Python 3.7
- Memory: 128MB
- Timeout: 2 minutes
- Triggers: S3 ObjectCreated on inputs/

SaveVideoFrame
- Runtime: Python 3.7
- Memory: 3008MB
- Timeout: 30 seconds
- Trigger: Upload to original/

---

📁 S3 Bucket Layout

| Bucket/Folders                | Purpose                         |
| ----------------------------- | ------------------------------- |
| nps-audiovideo-watchfolder/   | Upload watch folder             |
| audiovideo/                   | Final processed media           |
| original/                     | Original uploaded video files   |
| thumbnail/                    | Thumbnails extracted from video |
| json/                         | Metadata JSON files             |
| closed-caption/               | Closed-caption VTT files        |

---

🔍 Logs & Monitoring

- CloudWatch logs available for all Lambdas.
- Scripts use logger.info for detailed traceability.

---

🔐 Security Notes

- Upload bucket blocks public access
- Destination bucket has CORS policy and public access for media delivery
- Bucket policies and CORS configurations available in the aws-lambda Structured Data folder

---

🧪 Development & Assets

- Code, configs, and binaries are in /customcf/structured_data/aws-lambda/
- Includes:
  - VDOLambdaConvert-convert.py
  - VDOLambdaConvert-job.json
  - SaveVideoFrame-lambda_function.py
  - Precompiled binaries: pymediainfo, ffmpeglayer

---

🧠 Tips & Troubleshooting

| Scenario                  | Action                                      |
| ------------------------- | ------------------------------------------- |
| Upload fails              | Check S3 bucket permissions and lifecycle   |
| Metadata extraction fails | Confirm pymediainfo binary compatibility    |
| MediaConvert job fails    | Verify IAM role and modified job.json       |
| No thumbnail created      | Ensure trigger is set on original/ folder   |

---

🔗 Reference

- Installing Python binaries in Lambda: https://binx.io/blog/2017/10/20/how-to-install-python-binaries-in-aws-lambda/

---

📬 Contacts

- TBD

