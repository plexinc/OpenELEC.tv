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

#ifndef GIFImageDecoder_h
#define GIFImageDecoder_h

#include "platform/image-decoders/RPIImageDecoder.h"
#include "platform/image-decoders/brcmimage.h"
#include "interface/mmal/mmal.h"

namespace blink
{
    typedef unsigned char BYTE;

    // PNG IHDR CHUNK
    typedef struct _GIF_HEADER
    {
        BYTE gif[3];
        BYTE version[3];
        BYTE width[2];
        BYTE height[2];
        BYTE colortable;
        BYTE bgcolorindex;
    } GIF_HEADER;


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // This class decodes the JPEG image format.
    class PLATFORM_EXPORT GIFImageDecoder : public RPIImageDecoder
    {
        WTF_MAKE_NONCOPYABLE(GIFImageDecoder);
    public:
        GIFImageDecoder(ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption, size_t maxDecodedBytes);
        virtual ~GIFImageDecoder();

        // ImageDecoder
        virtual String filenameExtension() const override { return "gif"; }
        virtual char* platformDecode() { return (char*)"GIF"; }
        virtual bool readSize(unsigned int &width, unsigned int &height);
        virtual unsigned int getMMALImageType() { return MMAL_ENCODING_GIF; }

        virtual BRCMIMAGE_T* getDecoder() { return m_decoder; }
        virtual BRCMIMAGE_REQUEST_T *getDecoderRequest() { return &m_dec_request; }

    private:

        GIF_HEADER m_header;

        static BRCMIMAGE_REQUEST_T m_dec_request;
        static BRCMIMAGE_T *m_decoder;
    };

} // namespace blink

#endif
