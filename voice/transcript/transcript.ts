export interface TranscriptSegment {
  text: string;
  isFinal: boolean;
  timestamp: number;
  speaker?: string;
}

export interface TranscriptResult {
  segments: TranscriptSegment[];
  fullText: string;
  language: string;
  duration: number;
}

export function createTranscriptResult(
  segments: TranscriptSegment[],
  language: string = "de-DE"
): TranscriptResult {
  const fullText = segments
    .filter((s) => s.isFinal)
    .map((s) => s.text)
    .join(" ");

  const duration =
    segments.length > 0
      ? segments[segments.length - 1].timestamp - segments[0].timestamp
      : 0;

  return {
    segments,
    fullText,
    language,
    duration,
  };
}
