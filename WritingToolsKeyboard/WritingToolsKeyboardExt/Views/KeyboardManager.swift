// Disabled Suggestions for now, will work on it again, when everything else is finished. 

/*
 import UIKit
 
 
 class KeyboardManager {
 private let textChecker = UITextChecker()
 
 private let defaults = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
 
 private var suggestions: [String] = []
 
 private var enableSuggestions: Bool {
 return defaults?.bool(forKey: "enable_suggestions") ?? true
 }
 
 private var enableAutocorrect: Bool {
 return defaults?.bool(forKey: "enable_autocorrect") ?? true
 }
 
 // Cache the last text used for suggestions to avoid recomputing
 private var lastSuggestionText: String = ""
 private var lastSuggestionsResult: [String] = []
 
 init() {}
 
 func getSuggestions(for text: String) -> [String] {
 guard enableSuggestions else { return [] }
 
 // If the user hasn't changed the text from last time, return cached suggestions
 if text == lastSuggestionText {
 return lastSuggestionsResult
 }
 
 // Get word being typed
 let words = text.components(separatedBy: .whitespaces)
 guard let currentWord = words.last?.lowercased(), !currentWord.isEmpty else {
 return []
 }
 
 var newSuggestions: [String] = []
 let range = NSRange(location: 0, length: currentWord.utf16.count)
 
 let completions = textChecker.completions(forPartialWordRange: range,
 in: currentWord,
 language: "en_US") ?? []
 newSuggestions += completions.prefix(3)
 
 // Add common words if needed
 if newSuggestions.count < 3 {
 let commonWords = [
 "the", "be", "to", "of", "and", "a", "in",
 "that", "have", "I", "you", "it", "for",
 "not", "on", "with", "he", "as", "this", "we"
 ]
 let filtered = commonWords.filter { $0.hasPrefix(currentWord) }
 .prefix(3 - newSuggestions.count)
 newSuggestions += filtered
 }
 
 let finalSuggestions = Array(Set(newSuggestions)).prefix(3).map { $0 }
 // Cache result
 lastSuggestionText = text
 lastSuggestionsResult = Array(finalSuggestions)
 
 return lastSuggestionsResult
 }
 
 func getAutocorrectSuggestion(for text: String) -> String? {
 guard enableAutocorrect else { return nil }
 
 // If the user hasn't changed text from last time, skip re-checking
 if text == lastSuggestionText {
 return nil
 }
 
 let words = text.components(separatedBy: .whitespaces)
 guard let lastWord = words.last?.lowercased(), !lastWord.isEmpty else { return nil }
 
 let range = NSRange(location: 0, length: lastWord.utf16.count)
 let misspelledRange = textChecker.rangeOfMisspelledWord(
 in: lastWord,
 range: range,
 startingAt: 0,
 wrap: false,
 language: "en_US"
 )
 
 if misspelledRange.location != NSNotFound {
 let guesses = textChecker.guesses(forWordRange: misspelledRange,
 in: lastWord,
 language: "en_US") ?? []
 return guesses.first
 }
 
 return nil
 }
 }
 */
