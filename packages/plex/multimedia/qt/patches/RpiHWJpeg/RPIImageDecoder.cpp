/*
 * Copyright (C) 2006 Apple Computer, Inc.
 *
 * Portions are Copyright (C) 2001-6 mozilla.org
 *
 * Other contributors:
 *   Stuart Parmenter <stuart@mozilla.com>
 *
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#include "config.h"
#include "RPIImageDecoder.h"
#include "platform/PlatformInstrumentation.h"

#if CPU(BIG_ENDIAN) || CPU(MIDDLE_ENDIAN)
#error Blink assumes a little-endian target.
#endif

namespace
{
    // JPEG only supports a denominator of 8.
    const unsigned scaleDenominator = 8;

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    FILE *logFile=NULL;

    // decoding mutex : RPI HW decoder can only safely process one decode at a time
    pthread_mutex_t decode_mutex = PTHREAD_MUTEX_INITIALIZER;

} // namespace

namespace blink
{
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    RPIImageDecoder::RPIImageDecoder(ImageSource::AlphaOption alphaOption,
                                       ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption,
                                       size_t maxDecodedBytes)
        : ImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes), m_hasAlpha(false)
    {

    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    RPIImageDecoder::~RPIImageDecoder()
    {
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    bool RPIImageDecoder::setSize(unsigned width, unsigned height)
    {
        if (!ImageDecoder::setSize(width, height))
            return false;

        if (!desiredScaleNumerator())
            return setFailed();

        setDecodedSize(width, height);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    void RPIImageDecoder::setDecodedSize(unsigned width, unsigned height)
    {
        m_decodedSize = IntSize(width, height);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    unsigned RPIImageDecoder::desiredScaleNumerator() const
    {
        size_t originalBytes = size().width() * size().height() * 4;
        if (originalBytes <= m_maxDecodedBytes) {
            return scaleDenominator;
        }

        // Downsample according to the maximum decoded size.
        unsigned scaleNumerator = static_cast<unsigned>(floor(sqrt(
                                                                  // MSVC needs explicit parameter type for sqrt().
                                                                  static_cast<float>(m_maxDecodedBytes * scaleDenominator * scaleDenominator / originalBytes))));

        return scaleNumerator;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    void RPIImageDecoder::decode(bool onlySize)
    {
        unsigned int width, height;

        if (failed())
            return;

        // make sure we have all the data before doing anything
        if (!isAllDataReceived())
            return;

        if (onlySize)
        {
            if (readSize(width, height));
            {
                setSize(width, height);
            }
            return;
        }
        else
        {
            readSize(width, height);

            clock_t start = clock();

            ImageFrame& buffer = m_frameBufferCache[0];

            if (m_frameBufferCache.isEmpty())
            {
                log("decode : frameBuffercache is empty");
                setFailed();
                return;
            }

            if (buffer.status() == ImageFrame::FrameEmpty)
            {
                if (!buffer.setSize(width, height))
                {
                    log("decode : could not define buffer size");
                    setFailed();
                    return;
                }

                // The buffer is transparent outside the decoded area while the image is
                // loading. The completed image will be marked fully opaque in jpegComplete().
                buffer.setHasAlpha(false);
            }

            // lock the mutex so that we only process once at a time
            pthread_mutex_lock(&decode_mutex);

            // setup decoder request information
            BRCMIMAGE_REQUEST_T* dec_request = getDecoderRequest();
            BRCMIMAGE_T *decoder = getDecoder();

            memset(dec_request, 0, sizeof(BRCMIMAGE_REQUEST_T));
            dec_request->input = (unsigned char*)m_data->data();
            dec_request->input_size = m_data->size();
            dec_request->output = (unsigned char*)buffer.getAddr(0, 0);
            dec_request->output_alloc_size = width * height * 4;
            dec_request->output_handle = 0;
            dec_request->pixel_format = PIXEL_FORMAT_RGBA;
            dec_request->buffer_width = 0;
            dec_request->buffer_height = 0;

            brcmimage_acquire(decoder);
            BRCMIMAGE_STATUS_T status = brcmimage_process(decoder, dec_request);

            if (status == BRCMIMAGE_SUCCESS)
            {
                clock_t copy = clock();

                unsigned char *ptr = (unsigned char *)buffer.getAddr(0, 0);
                for (unsigned int i = 0; i < dec_request->height * dec_request->width; i++)
                {
                    // we swap RGBA -> BGRA
                    unsigned char tmp = *ptr;
                    *ptr = ptr[2];
                    ptr[2] = tmp;
                    ptr += 4;
                }

                brcmimage_release(decoder);

                buffer.setPixelsChanged(true);
                buffer.setStatus(ImageFrame::FrameComplete);
                buffer.setHasAlpha(m_hasAlpha);

                clock_t end = clock();
                unsigned long millis = (end - start) * 1000 / CLOCKS_PER_SEC;
                unsigned long copymillis = (end - copy) * 1000 / CLOCKS_PER_SEC;

                log("decode : image (%d x %d)(Alpha=%d) decoded in %d ms (copy in %d ms), source size = %d bytes", width, height, m_hasAlpha, millis, copymillis, m_data->size());

            }
            else
            {
                log("decode : Decoding failed with status %d", status);
            }

            pthread_mutex_unlock(&decode_mutex);
        }


    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    void RPIImageDecoder::log(const char * format, ...)
    {
        if (!logFile)
        {
            logFile = fopen("/storage/webengine.log", "w");
        }

        va_list args;
        va_start (args, format);
        fprintf(logFile, "RPIImageDecoder(%s):", filenameExtension().ascii().data());
        vfprintf (logFile, format, args);
        fprintf(logFile, "\r\n");
        va_end (args);
        fflush(logFile);
    }
}
