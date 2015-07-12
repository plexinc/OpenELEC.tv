/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2008-2009 Torch Mobile, Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef JPEGImageDecoder_h
#define JPEGImageDecoder_h

#include "platform/image-decoders/ImageDecoder.h"
#include "brcmjpeg.h"

namespace blink
{

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // JPEG header struct
#define JFIF_DATA_SIZE 4096 // additionnal data size for header parsing

    typedef unsigned char BYTE;

    typedef struct _JFIFHeader
    {
        BYTE SOI[2];          /* 00h  Start of Image Marker     */
        BYTE APP0[2];         /* 02h  Application Use Marker    */
        BYTE Length[2];       /* 04h  Length of APP0 Field      */
        BYTE Identifier[5];   /* 06h  "JFIF" (zero terminated) Id String */
        BYTE Version[2];      /* 07h  JFIF Format Revision      */
        BYTE Units;           /* 09h  Units used for Resolution */
        BYTE Xdensity[2];     /* 0Ah  Horizontal Resolution     */
        BYTE Ydensity[2];     /* 0Ch  Vertical Resolution       */
        BYTE XThumbnail;      /* 0Eh  Horizontal Pixel Count    */
        BYTE YThumbnail;      /* 0Fh  Vertical Pixel Count      */
        BYTE data[JFIF_DATA_SIZE];
    } JFIFHEAD;

    // Hardware decoder buffers
    #define MAX_WIDTH   2500
    #define MAX_HEIGHT  2500
    #define MAX_ENCODED (15*1024*1024)
    #define MAX_DECODED (MAX_WIDTH*MAX_HEIGHT*4)

    BYTE encodedInBuf[MAX_ENCODED];
    BYTE decodedBuf[MAX_DECODED];


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // This class decodes the JPEG image format.
    class PLATFORM_EXPORT JPEGImageDecoder : public ImageDecoder
    {
        WTF_MAKE_NONCOPYABLE(JPEGImageDecoder);
    public:
        JPEGImageDecoder(ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption, size_t maxDecodedBytes);
        virtual ~JPEGImageDecoder();

        // ImageDecoder
        virtual String filenameExtension() const override { return "jpg"; }
        virtual bool isSizeAvailable() override;
        virtual bool setSize(unsigned width, unsigned height) override;
        virtual ImageFrame* frameBufferAtIndex(size_t) override;
        virtual bool setFailed() override;

        bool readJpegSize(unsigned int &width, unsigned int &height);
        unsigned desiredScaleNumerator() const;


    private:
        // Decodes the image.  If |onlySize| is true, stops decoding after
        // calculating the image size.  If decoding fails but there is no more
        // data coming, sets the "decode failure" flag.
        void decode(bool onlySize);

        static BRCMJPEG_REQUEST_T m_dec_request;
        static BRCMJPEG_T *m_decoder;
    };

} // namespace blink

#endif
