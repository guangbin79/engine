// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreImage/CoreImage.h>

#include "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"

NSString * CVPixelFormatName(OSType type) {
switch (type) {
    case kCVPixelFormatType_1Monochrome:                   return @"kCVPixelFormatType_1Monochrome";
    case kCVPixelFormatType_2Indexed:                      return @"kCVPixelFormatType_2Indexed";
    case kCVPixelFormatType_4Indexed:                      return @"kCVPixelFormatType_4Indexed";
    case kCVPixelFormatType_8Indexed:                      return @"kCVPixelFormatType_8Indexed";
    case kCVPixelFormatType_1IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_1IndexedGray_WhiteIsZero";
    case kCVPixelFormatType_2IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_2IndexedGray_WhiteIsZero";
    case kCVPixelFormatType_4IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_4IndexedGray_WhiteIsZero";
    case kCVPixelFormatType_8IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_8IndexedGray_WhiteIsZero";
    case kCVPixelFormatType_16BE555:                       return @"kCVPixelFormatType_16BE555";
    case kCVPixelFormatType_16LE555:                       return @"kCVPixelFormatType_16LE555";
    case kCVPixelFormatType_16LE5551:                      return @"kCVPixelFormatType_16LE5551";
    case kCVPixelFormatType_16BE565:                       return @"kCVPixelFormatType_16BE565";
    case kCVPixelFormatType_16LE565:                       return @"kCVPixelFormatType_16LE565";
    case kCVPixelFormatType_24RGB:                         return @"kCVPixelFormatType_24RGB";
    case kCVPixelFormatType_24BGR:                         return @"kCVPixelFormatType_24BGR";
    case kCVPixelFormatType_32ARGB:                        return @"kCVPixelFormatType_32ARGB";
    case kCVPixelFormatType_32BGRA:                        return @"kCVPixelFormatType_32BGRA";
    case kCVPixelFormatType_32ABGR:                        return @"kCVPixelFormatType_32ABGR";
    case kCVPixelFormatType_32RGBA:                        return @"kCVPixelFormatType_32RGBA";
    case kCVPixelFormatType_64ARGB:                        return @"kCVPixelFormatType_64ARGB";
    case kCVPixelFormatType_48RGB:                         return @"kCVPixelFormatType_48RGB";
    case kCVPixelFormatType_32AlphaGray:                   return @"kCVPixelFormatType_32AlphaGray";
    case kCVPixelFormatType_16Gray:                        return @"kCVPixelFormatType_16Gray";
    case kCVPixelFormatType_30RGB:                         return @"kCVPixelFormatType_30RGB";
    case kCVPixelFormatType_422YpCbCr8:                    return @"kCVPixelFormatType_422YpCbCr8";
    case kCVPixelFormatType_4444YpCbCrA8:                  return @"kCVPixelFormatType_4444YpCbCrA8";
    case kCVPixelFormatType_4444YpCbCrA8R:                 return @"kCVPixelFormatType_4444YpCbCrA8R";
    case kCVPixelFormatType_4444AYpCbCr8:                  return @"kCVPixelFormatType_4444AYpCbCr8";
    case kCVPixelFormatType_4444AYpCbCr16:                 return @"kCVPixelFormatType_4444AYpCbCr16";
    case kCVPixelFormatType_444YpCbCr8:                    return @"kCVPixelFormatType_444YpCbCr8";
    case kCVPixelFormatType_422YpCbCr16:                   return @"kCVPixelFormatType_422YpCbCr16";
    case kCVPixelFormatType_422YpCbCr10:                   return @"kCVPixelFormatType_422YpCbCr10";
    case kCVPixelFormatType_444YpCbCr10:                   return @"kCVPixelFormatType_444YpCbCr10";
    case kCVPixelFormatType_420YpCbCr8Planar:              return @"kCVPixelFormatType_420YpCbCr8Planar";
    case kCVPixelFormatType_420YpCbCr8PlanarFullRange:     return @"kCVPixelFormatType_420YpCbCr8PlanarFullRange";
    case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:        return @"kCVPixelFormatType_422YpCbCr_4A_8BiPlanar";
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  return @"kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange";
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:   return @"kCVPixelFormatType_420YpCbCr8BiPlanarFullRange";
    case kCVPixelFormatType_422YpCbCr8_yuvs:               return @"kCVPixelFormatType_422YpCbCr8_yuvs";
    case kCVPixelFormatType_422YpCbCr8FullRange:           return @"kCVPixelFormatType_422YpCbCr8FullRange";
    case kCVPixelFormatType_OneComponent8:                 return @"kCVPixelFormatType_OneComponent8";
    case kCVPixelFormatType_TwoComponent8:                 return @"kCVPixelFormatType_TwoComponent8";
    case kCVPixelFormatType_30RGBLEPackedWideGamut:        return @"kCVPixelFormatType_30RGBLEPackedWideGamut";
    case kCVPixelFormatType_OneComponent16Half:            return @"kCVPixelFormatType_OneComponent16Half";
    case kCVPixelFormatType_OneComponent32Float:           return @"kCVPixelFormatType_OneComponent32Float";
    case kCVPixelFormatType_TwoComponent16Half:            return @"kCVPixelFormatType_TwoComponent16Half";
    case kCVPixelFormatType_TwoComponent32Float:           return @"kCVPixelFormatType_TwoComponent32Float";
    case kCVPixelFormatType_64RGBAHalf:                    return @"kCVPixelFormatType_64RGBAHalf";
    case kCVPixelFormatType_128RGBAFloat:                  return @"kCVPixelFormatType_128RGBAFloat";
    case kCVPixelFormatType_14Bayer_GRBG:                  return @"kCVPixelFormatType_14Bayer_GRBG";
    case kCVPixelFormatType_14Bayer_RGGB:                  return @"kCVPixelFormatType_14Bayer_RGGB";
    case kCVPixelFormatType_14Bayer_BGGR:                  return @"kCVPixelFormatType_14Bayer_BGGR";
    case kCVPixelFormatType_14Bayer_GBRG:                  return @"kCVPixelFormatType_14Bayer_GBRG";
    }
    return @"UNKNOWN";
}

namespace flutter {

IOSExternalTextureGL::IOSExternalTextureGL(int64_t textureId,
                                           NSObject<FlutterTexture>* externalTexture)
    : Texture(textureId), external_texture_(externalTexture) {
  FML_DCHECK(external_texture_);
}

IOSExternalTextureGL::~IOSExternalTextureGL() = default;

CGImageRef imageFromCVPixelBufferRef(CVPixelBufferRef pixelBuffer, int width, int height) {
    if (CVPixelBufferGetHeight(pixelBuffer) == 0 || CVPixelBufferGetWidth(pixelBuffer) == 0) {
      return nil;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, ciImage, nil];
    [filter setDefaults];
    CGFloat wscale = (CGFloat)width / CVPixelBufferGetWidth(pixelBuffer);
    CGFloat hscale = (CGFloat)height / CVPixelBufferGetHeight(pixelBuffer);
    CGAffineTransform transform = CGAffineTransformMakeScale(wscale, hscale);
    [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    CIImage *outputImage = [filter outputImage];

    CIContext *temporaryContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    CGImageRef image = [temporaryContext createCGImage:outputImage fromRect:[outputImage extent]];
    //CGImageRelease(videoImage);
    return image;
}

void IOSExternalTextureGL::Paint(SkCanvas& canvas,
                                 const SkRect& bounds,
                                 bool freeze,
                                 GrContext* context) {
  CVPixelBufferRef pixelBuffer = [external_texture_ copyPixelBuffer];
  CGImageRef cgimage = imageFromCVPixelBufferRef(pixelBuffer, bounds.width(), bounds.height());

  if (cgimage == nil) {
    return;
  }

  CFDataRef cfdata = CGDataProviderCopyData(CGImageGetDataProvider(cgimage));
  const unsigned char * pixels = CFDataGetBytePtr(cfdata);
  CFIndex length = CFDataGetLength(cfdata);
  SkImageInfo info = SkImageInfo::Make(CGImageGetWidth(cgimage), CGImageGetHeight(cgimage), kBGRA_8888_SkColorType, kPremul_SkAlphaType);
  sk_sp<SkData> data = SkData::MakeWithoutCopy(pixels, length);
  sk_sp<SkImage> image = SkImage::MakeRasterData(info, data, CGImageGetBytesPerRow(cgimage));

  FML_DCHECK(image) << "Failed to create SkImage from Texture.";
  if (image) {
    canvas.drawImage(image, bounds.x(), bounds.y());
  }
}


void IOSExternalTextureGL::OnGrContextCreated() {}

void IOSExternalTextureGL::OnGrContextDestroyed() {
  texture_ref_.Reset(nullptr);
  cache_ref_.Reset(nullptr);
}

void IOSExternalTextureGL::MarkNewFrameAvailable() {}

}  // namespace flutter
