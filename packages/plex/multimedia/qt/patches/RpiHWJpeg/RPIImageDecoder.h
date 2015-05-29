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

#ifndef RPIImageDecoder_h
#define RPIImageDecoder_h

#include "ImageDecoder.h"
#include "brcmimage.h"
#include "interface/mmal/mmal.h"

namespace blink
{
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // This class decodes the JPEG image format.
    class PLATFORM_EXPORT RPIImageDecoder : public ImageDecoder
    {
        WTF_MAKE_NONCOPYABLE(RPIImageDecoder);
    public:
        RPIImageDecoder(ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption, size_t maxDecodedBytes);
        virtual ~RPIImageDecoder();

        // ImageDecoder
        virtual String filenameExtension() const override { return "jpg"; }
        virtual char* platformDecode() { return (char*)"JPEG"; }
        IntSize decodedSize() const override { return m_decodedSize; }
        virtual bool setSize(unsigned width, unsigned height) override;

        virtual bool readSize(unsigned int &width, unsigned int &height) { return false; }
        unsigned desiredScaleNumerator() const;
        virtual unsigned int getMMALImageType() { return MMAL_ENCODING_JPEG; }

        virtual BRCMIMAGE_T* getDecoder() { return NULL; }
        virtual BRCMIMAGE_REQUEST_T *getDecoderRequest() { return NULL; }

        void log(const char * format, ...);
    protected:
        bool m_hasAlpha;

    private:
        void setDecodedSize(unsigned width, unsigned height);

        void decodeSize() override { decode(true); }
        void decode(size_t) override { decode(false); }

        // Decodes the image.  If |onlySize| is true, stops decoding after
        // calculating the image size.  If decoding fails but there is no more
        // data coming, sets the "decode failure" flag.
        void decode(bool onlySize);

        IntSize m_decodedSize;
    };

} // namespace blink

#endif
