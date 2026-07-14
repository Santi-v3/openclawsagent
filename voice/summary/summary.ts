export interface SummaryConfig {
  maxLength?: number;
  includeTimestamps?: boolean;
  language?: string;
}

export interface SummaryResult {
  title: string;
  keyPoints: string[];
  fullSummary: string;
  actionItems: string[];
  metadata: {
    generatedAt: number;
    sourceDuration: number;
    language: string;
  };
}

export function createEmptySummary(
  language: string = "de-DE"
): SummaryResult {
  return {
    title: "",
    keyPoints: [],
    fullSummary: "",
    actionItems: [],
    metadata: {
      generatedAt: Date.now(),
      sourceDuration: 0,
      language,
    },
  };
}
