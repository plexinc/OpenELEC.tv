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
#include "platform/image-decoders/png/PNGImageDecoder.h"
#include "platform/PlatformInstrumentation.h"

#if CPU(BIG_ENDIAN) || CPU(MIDDLE_ENDIAN)
#error Blink assumes a little-endian target.
#endif

namespace blink
{
    BRCMIMAGE_T* PNGImageDecoder::m_decoder=NULL;
    BRCMIMAGE_REQUEST_T PNGImageDecoder::m_dec_request;

    BYTE pngSignature[] = {137, 80, 78, 71, 13, 10, 26 ,10};

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    PNGImageDecoder::PNGImageDecoder(ImageSource::AlphaOption alphaOption,
                                       ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption,
                                       size_t maxDecodedBytes)
        : RPIImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes)
    {
        if (!m_decoder)
        {
            BRCMIMAGE_STATUS_T status = brcmimage_create(BRCMIMAGE_TYPE_DECODER, MMAL_ENCODING_PNG, &m_decoder);
            if (status != BRCMIMAGE_SUCCESS)
            {
                log("could not create HW PNG decoder");
                brcmimage_release(m_decoder);
                m_decoder = NULL;
            }
            else
            {
                log("HW PNG decoder created (%x)", m_decoder);
            }

        }

        m_hasAlpha = true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    PNGImageDecoder::~PNGImageDecoder()
    {
    }


    ///////////////////////////////////////////////////////////////////////////////////////////////////
    bool PNGImageDecoder::readSize(unsigned int &width, unsigned int &height)
    {
        BYTE* dataptr = (BYTE*)m_data->data();

        // check PNG signature
        if (strncmp((const char*)dataptr, (const char*)pngSignature, 8))
        {
            log("PNG signature check failed. (%d %d %d %d %d %d %d %d)",
                    dataptr[0], dataptr[1], dataptr[2], dataptr[3],
                    dataptr[4], dataptr[5], dataptr[6], dataptr[7]);
            return false;
        }

        memcpy(&m_ihdr, dataptr + 8, sizeof(m_ihdr));

        // check if we have IHDR chunk
        if (strncmp((const char*)m_ihdr.type, "IHDR", 4))
        {
            log("IHDR chunk check failed. (%c %c %c %c)", m_ihdr.type[0], m_ihdr.type[1], m_ihdr.type[2], m_ihdr.type[3]);
            return false;
        }

        width = m_ihdr.width[3] + (m_ihdr.width[2] << 8) + (m_ihdr.width[1] << 16) + (m_ihdr.width[0] << 24);
        height = m_ihdr.height[3] + (m_ihdr.height[2] << 8) + (m_ihdr.height[1] << 16) + (m_ihdr.height[0] << 24);

        log("Got a %d x %d PNG image", width, height);
        return true;
    }
}
