# 🎵 FFmpeg Minimal - AWS Lambda Ready 🚀

[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-6.0-green?style=flat&logo=ffmpeg&logoColor=white)](https://ffmpeg.org/)
[![AWS Lambda](https://img.shields.io/badge/AWS-Lambda%20Layer-FF9900?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/lambda/)

A **minimal, optimized FFmpeg build** for AWS Lambda. Creates a 5.6MB layer with essential audio codecs including modern Opus support.

## ✨ What You Get

- 🎯 **Ultra-minimal**: Only 5.6MB Lambda layer
- 🎵 **Modern codecs**: AAC, MP3, FLAC, Vorbis, **Opus**
- ⚡ **Lambda-optimized**: Pre-configured for serverless deployment
- 🏗️ **Simple build**: One Dockerfile, one command
- 📦 **Production-ready**: Stripped binaries, no debug bloat

## 🎵 Supported Audio Formats

**Input:** MP3, AAC, FLAC, Vorbis, Opus, WAV, OGG  
**Output:** Opus, WAV, OGG

**Why Opus?** Modern, high-quality, patent-free codec with superior compression 🎭

## 🚀 Quick Start

```bash
# Clone and build
git clone <your-repo-url>
cd ffmpeg-minimal
docker build -t ffmpeg-minimal .

# Extract the layer
docker run --rm -v $(pwd):/output ffmpeg-minimal cp /build/ffmpeg-layer.zip /output/
```

**Result:** `ffmpeg-layer.zip` (5.6MB) ready for Lambda deployment!

## 📦 Deploy to AWS Lambda

### 1. Upload Layer
```bash
aws lambda publish-layer-version \
    --layer-name ffmpeg-minimal \
    --zip-file fileb://ffmpeg-layer.zip \
    --compatible-runtimes python3.9 nodejs18.x \
    --description "Minimal FFmpeg with Opus support"
```

### 2. Use in Your Function

**Python Example:**
```python
import subprocess
import os

def lambda_handler(event, context):
    # Set environment
    os.environ['PATH'] = '/opt/bin:' + os.environ.get('PATH', '')
    os.environ['LD_LIBRARY_PATH'] = '/opt/lib'
    
    # Convert MP3 to Opus
    result = subprocess.run([
        '/opt/bin/ffmpeg',
        '-i', 'input.mp3',
        '-c:a', 'libopus',
        '-b:a', '128k',
        'output.opus'
    ], capture_output=True)
    
    return {'statusCode': 200, 'body': 'Converted!'}
```

**Node.js Example:**
```javascript
const { exec } = require('child_process');

exports.handler = async (event) => {
    process.env.PATH = '/opt/bin:' + process.env.PATH;
    process.env.LD_LIBRARY_PATH = '/opt/lib';
    
    return new Promise((resolve) => {
        exec('/opt/bin/ffmpeg -i input.mp3 -c:a libopus output.opus', (error, stdout) => {
            resolve({ statusCode: 200, body: 'Converted!' });
        });
    });
};
```

## 🔧 What's Inside the Build

The Dockerfile creates a minimal FFmpeg with:

```bash
# Essential audio codecs only
--enable-decoder=aac,mp3,vorbis,flac,pcm_s16le,libopus
--enable-encoder=libopus,pcm_s16le

# Minimal protocols and formats
--enable-protocol=https,file,pipe
--enable-demuxer=mov,mp4,matroska,wav,ogg
--enable-muxer=ogg,wav

# Everything else disabled for size
--disable-everything
--disable-debug
--disable-doc
```

## 🎯 Perfect For

- 🎧 **Podcast processing**
- 🗣️ **Audio transcription prep**
- 🔄 **Format conversion**
- 📱 **Mobile app backends**
- 🎵 **Music streaming services**
- 📞 **Voice call processing**

## 🔍 What's Happening Behind the Scenes

Ever wondered how pydub and other audio libraries magically find FFmpeg in Lambda? Here's the magic:

### Lambda Layer Runtime
```bash
# When your Lambda starts, AWS automatically:
# 1. Mounts your layer at /opt/
# 2. Updates system paths:

PATH="/opt/bin:/usr/local/bin:/usr/bin:/bin"
LD_LIBRARY_PATH="/opt/lib:/lib64:/usr/lib64"

# Now any process can find your FFmpeg:
which ffmpeg  # → /opt/bin/ffmpeg ✅
```

### How Libraries Use It
```python
# Pydub doesn't bundle FFmpeg - it searches the system:
from pydub import AudioSegment

# Behind the scenes:
# 1. pydub calls: shutil.which("ffmpeg")
# 2. Finds: /opt/bin/ffmpeg (from your layer!)
# 3. Executes: subprocess.run(["ffmpeg", "-i", "input.mp3", "output.opus"])
# 4. Uses your custom Opus-enabled build!

audio = AudioSegment.from_file("input.mp3")
audio.export("output.opus", format="opus")  # Works seamlessly! 🎵
```

### The Layer Structure
```
Your Lambda Function
├── /var/task/          # Your code
├── /tmp/               # Temporary files
└── /opt/               # ← Your layer mounts here
    ├── bin/
    │   ├── ffmpeg      # Available in PATH
    │   └── ffprobe     # Available in PATH
    └── lib/
        ├── libopus.so  # Loaded automatically
        └── libav*.so   # FFmpeg libraries
```

**Result:** Libraries like pydub, moviepy, and direct subprocess calls all work without any extra configuration! 🚀

## 🛠️ Local Testing

```bash
# Test your build
docker run -it ffmpeg-minimal bash
/opt/bin/ffmpeg -version
/opt/bin/ffprobe -version

# Test conversion
/opt/bin/ffmpeg -f lavfi -i "sine=frequency=1000:duration=5" test.opus
```

## 🚨 Troubleshooting

**❌ "ffmpeg: command not found"**
```bash
export PATH="/opt/bin:$PATH"
export LD_LIBRARY_PATH="/opt/lib"
```

**❌ "Lambda layer too large"**  
This build is already optimized at 5.6MB - well under Lambda's 50MB limit!

**❌ "Opus encoder not found"**  
Make sure you're using the main `Dockerfile` (Opus is included by default).

## 📁 Project Structure

```
ffmpeg-minimal/
├── Dockerfile          # Main build configuration
├── README.md          # This file
├── .gitignore         # Ignore build artifacts
└── currently_used/    # Your production layer (for reference)
```

**Note:** Directories like `ffmpeg-layer/` and `opus-1.3.1/` are build artifacts - they're created during Docker build and ignored by git.

## 🤝 Contributing

This is a focused, single-purpose build. For modifications:

1. Fork the repo
2. Modify the Dockerfile codec options
3. Test with `docker build`
4. Submit PR with clear use case

## 📝 License

Built with FFmpeg (LGPL) and Opus (BSD). Ensure compliance for commercial use.

---

**🎵 Ready to process audio at scale!** Perfect for serverless architectures needing efficient, modern audio processing.

*Made with ❤️ for the serverless community*