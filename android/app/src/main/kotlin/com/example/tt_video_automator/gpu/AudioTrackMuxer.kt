package com.example.tt_video_automator.gpu

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.nio.ByteBuffer

/**
 * Handles audio demuxing, trimming, and stream writing directly into MediaMuxer.
 */
class AudioTrackMuxer {
    private var audioExtractor: MediaExtractor? = null
    var audioTrackIndex: Int = -1
        private set
    var audioFormat: MediaFormat? = null
        private set

    fun extractAndSetup(
        inputPath: String,
        muxer: MediaMuxer,
        startTimeUs: Long = 0L,
        endTimeUs: Long = Long.MAX_VALUE
    ): Int {
        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)
        audioExtractor = extractor

        var trackIndex = -1
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
            if (mime.startsWith("audio/")) {
                extractor.selectTrack(i)
                audioFormat = format
                trackIndex = muxer.addTrack(format)
                audioTrackIndex = trackIndex
                break
            }
        }

        if (startTimeUs > 0) {
            extractor.seekTo(startTimeUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
        }

        return audioTrackIndex
    }

    /**
     * Copies audio samples from input extractor into the target muxer track.
     */
    fun muxAudioSamples(
        muxer: MediaMuxer,
        trackIndex: Int,
        startTimeUs: Long = 0L,
        endTimeUs: Long = Long.MAX_VALUE,
        speedFactor: Float = 1.0f
    ) {
        val extractor = audioExtractor ?: return
        if (trackIndex < 0) return

        val bufferSize = 128 * 1024
        val buffer = ByteBuffer.allocateDirect(bufferSize)
        val bufferInfo = MediaCodec.BufferInfo()

        var firstSampleTimeUs = -1L

        while (true) {
            val sampleSize = extractor.readSampleData(buffer, 0)
            if (sampleSize < 0) break

            val sampleTimeUs = extractor.sampleTime
            if (sampleTimeUs > endTimeUs) break

            if (sampleTimeUs >= startTimeUs) {
                if (firstSampleTimeUs < 0) {
                    firstSampleTimeUs = sampleTimeUs
                }

                val relativeTimeUs = ((sampleTimeUs - firstSampleTimeUs) / speedFactor).toLong()
                bufferInfo.offset = 0
                bufferInfo.size = sampleSize
                bufferInfo.presentationTimeUs = relativeTimeUs
                bufferInfo.flags = extractor.sampleFlags

                muxer.writeSampleData(trackIndex, buffer, bufferInfo)
            }

            if (!extractor.advance()) break
        }
    }

    fun release() {
        audioExtractor?.release()
        audioExtractor = null
    }

    companion object {
        private const val TAG = "AudioTrackMuxer"
    }
}
