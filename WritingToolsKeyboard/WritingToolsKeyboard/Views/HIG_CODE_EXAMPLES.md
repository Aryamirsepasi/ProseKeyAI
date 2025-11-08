# Code Examples: HIG-Compliant SwiftUI Patterns

This document highlights the key SwiftUI patterns used to improve your app according to Apple's Human Interface Guidelines.

---

## 1. Navigation Bar with Toolbar Menu

### ✅ Modern Approach
```swift
NavigationStack {
    ScrollView {
        // Content
    }
    .navigationTitle("ProseKey AI")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: { /* ... */ }) {
                    Label("Show Welcome Guide", systemImage: "book.circle")
                }
                Button(action: { /* ... */ }) {
                    Label("Reload Configuration", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
        }
    }
}
```

**Why this is better:**
- Uses system navigation bar (consistent with iOS)
- Large title for top-level screens
- Menu for secondary actions
- Proper SF Symbol usage in labels

---

## 2. Status Card with Hierarchical Symbols

### ✅ Modern Approach
```swift
HStack(alignment: .center, spacing: 12) {
    // Status indicator
    ZStack {
        Circle()
            .fill(isEnabled ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
            .frame(width: 44, height: 44)
        
        Image(systemName: isEnabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(isEnabled ? .green : .orange)
            .symbolRenderingMode(.hierarchical)  // ← Key modifier
    }
    
    VStack(alignment: .leading, spacing: 2) {
        Text(isEnabled ? "Keyboard Active" : "Setup Required")
            .font(.headline)
        Text(isEnabled ? "Ready to use in any app" : "Enable keyboard to continue")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    Spacer()
}
```

**Key features:**
- `.symbolRenderingMode(.hierarchical)` for depth
- Semantic colors (`.green`, `.orange`)
- Proper spacing (12pt between elements)
- Typography scale (`.headline`, `.subheadline`)

---

## 3. Modern Card Styling

### ✅ Modern Approach
```swift
VStack {
    // Content
}
.padding()
.background(Color(.systemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
)
```

**Why this is better:**
- `.systemGroupedBackground` (semantic color)
- `.continuous` corner style (smoother than `.circular`)
- Subtle border with secondary color
- 12pt corner radius (iOS standard)

---

## 4. Section Headers

### ❌ Old Approach
```swift
Text("Select AI Provider")
    .font(.headline)
    .padding(.horizontal)
```

### ✅ Modern Approach
```swift
Text("AI Provider")
    .font(.title3)
    .fontWeight(.semibold)
    .padding(.horizontal)
    .padding(.top, 8)
```

**Improvements:**
- `.title3` (20pt) instead of `.headline` (17pt)
- `.semibold` weight for better hierarchy
- Consistent padding

---

## 5. List Row with Icon Badge

### ✅ Modern Approach
```swift
HStack(spacing: 12) {
    // Icon badge
    ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.blue.opacity(0.12))
            .frame(width: 32, height: 32)
        
        Image(systemName: "list.bullet.rectangle")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            .symbolRenderingMode(.hierarchical)
    }
    
    Text("Manage AI Commands")
        .font(.body)
    
    Spacer()
    
    Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary.opacity(0.5))
}
.padding()
.contentShape(Rectangle())
```

**Key features:**
- Icon badge with subtle background
- 12pt opacity for backgrounds
- Small, subtle chevron
- `.contentShape(Rectangle())` for full-width tap

---

## 6. Inline Dividers

### ✅ Modern Approach
```swift
VStack(spacing: 0) {
    FirstRow()
    
    Divider()
        .padding(.leading, 56)  // ← Aligns with text, not icon
    
    SecondRow()
}
```

**Why this is better:**
- Divider doesn't extend under icon
- Creates visual continuity
- More sophisticated look

---

## 7. Info Banner

### ❌ Old Approach
```swift
Text("⚠️ If you just enabled Full Access...")
    .font(.footnote)
    .foregroundColor(.orange)
```

### ✅ Modern Approach
```swift
HStack(alignment: .top, spacing: 8) {
    Image(systemName: "info.circle.fill")
        .font(.system(size: 14))
        .foregroundColor(.blue)
        .padding(.top, 2)
    
    Text("After enabling Full Access, restart the app for changes to take effect.")
        .font(.footnote)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
}
.padding(12)
.background(Color.blue.opacity(0.1))
.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
```

**Improvements:**
- SF Symbol instead of emoji
- Blue info color instead of orange warning
- Proper text wrapping
- Subtle background

---

## 8. Button Styles

### ✅ Primary Action
```swift
Button(action: { /* ... */ }) {
    Text("Save Changes")
        .fontWeight(.medium)
        .frame(maxWidth: .infinity)
        .padding()
        .background(isFormValid ? Color.accentColor : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(10)
}
.disabled(!isFormValid)
```

### ✅ Secondary Action (Capsule)
```swift
Button(action: { /* ... */ }) {
    Text("Setup")
        .fontWeight(.semibold)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .clipShape(Capsule())
}
```

---

## 9. Navigation Links (Plain Style)

### ✅ Modern Approach
```swift
NavigationLink(destination: DetailView()) {
    HStack {
        // Content
    }
    .contentShape(Rectangle())
}
.buttonStyle(.plain)  // ← Prevents blue tint and highlighting
```

**Why this is better:**
- No unwanted highlighting
- Custom appearance preserved
- Better tap feedback control

---

## 10. Link Rows

### ✅ Modern Approach
```swift
Link(destination: url) {
    HStack(spacing: 12) {
        // Icon badge
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(iconColor.opacity(0.12))
                .frame(width: 40, height: 40)
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .symbolRenderingMode(.hierarchical)
        }
        
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        
        Spacer()
        
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary.opacity(0.5))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
}
.buttonStyle(.plain)
```

**Key features:**
- Chevron instead of external link icon
- Proper text colors (`.primary`, `.secondary`)
- Hierarchical symbol rendering
- Full-width tap target

---

## 11. Step Views

### ✅ Modern Approach
```swift
HStack(alignment: .top, spacing: 12) {
    ZStack {
        Circle()
            .fill(isCompleted ? Color.green : Color.accentColor.opacity(0.15))
            .frame(width: 28, height: 28)

        if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        } else {
            Text("\(number)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.accentColor)
        }
    }

    Text(text)
        .font(.subheadline)
        .foregroundColor(isCompleted ? .secondary : .primary)
        .strikethrough(isCompleted, color: .secondary)
        .fixedSize(horizontal: false, vertical: true)
    
    Spacer(minLength: 0)
}
```

**Key features:**
- Proper alignment (`.top` for multi-line text)
- Strikethrough for completed states
- `.fixedSize(horizontal: false, vertical: true)` for text wrapping
- `Spacer(minLength: 0)` to prevent spacing issues

---

## 12. Semantic Colors

### ✅ Always Use Semantic Colors
```swift
// ✅ Good
.foregroundColor(.primary)
.foregroundColor(.secondary)
.background(Color(.systemGroupedBackground))
.foregroundColor(.accentColor)

// ❌ Avoid
.foregroundColor(.black)  // Doesn't adapt to dark mode
.background(Color.white)   // Doesn't adapt to dark mode
```

---

## 13. Typography Scale

### ✅ Complete Scale
```swift
Text("Large Title").font(.largeTitle)        // 34pt
Text("Title").font(.title)                   // 28pt
Text("Title 2").font(.title2)                // 22pt
Text("Title 3").font(.title3)                // 20pt ← Use for section headers
Text("Headline").font(.headline)             // 17pt, semibold
Text("Body").font(.body)                     // 17pt ← Use for main content
Text("Callout").font(.callout)               // 16pt
Text("Subheadline").font(.subheadline)       // 15pt ← Use for supporting text
Text("Footnote").font(.footnote)             // 13pt
Text("Caption").font(.caption)               // 12pt ← Use for tertiary text
Text("Caption 2").font(.caption2)            // 11pt
```

---

## 14. Spacing Guidelines

### ✅ Consistent Spacing
```swift
VStack(spacing: 4)    // Very tight (icon + label)
VStack(spacing: 8)    // Default (related items)
VStack(spacing: 12)   // Medium (section items)
VStack(spacing: 16)   // Wide (major groups)
VStack(spacing: 20)   // Very wide (major sections)

.padding(8)           // Tight padding
.padding(12)          // Default padding
.padding(16)          // Standard padding
.padding(20)          // Wide padding
```

---

## 15. SF Symbols Best Practices

### ✅ Modern SF Symbols Usage
```swift
Image(systemName: "checkmark.circle.fill")
    .font(.system(size: 24, weight: .medium))
    .foregroundColor(.green)
    .symbolRenderingMode(.hierarchical)     // Depth and dimension
    .imageScale(.large)                     // Consistent sizing

// Rendering modes:
.symbolRenderingMode(.monochrome)     // Single color
.symbolRenderingMode(.hierarchical)   // Depth (recommended for most)
.symbolRenderingMode(.palette)        // Multiple colors
.symbolRenderingMode(.multicolor)     // Full color
```

---

## Quick Reference: Common Patterns

### Card Container
```swift
.padding()
.background(Color(.systemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
)
```

### Icon Badge
```swift
ZStack {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(color.opacity(0.12))
        .frame(width: 40, height: 40)
    Image(systemName: icon)
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(color)
        .symbolRenderingMode(.hierarchical)
}
```

### List Row
```swift
HStack(spacing: 12) {
    // Icon badge
    // Content
    Spacer()
    Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary.opacity(0.5))
}
.padding()
.contentShape(Rectangle())
```

---

## Testing Your HIG Compliance

### Checklist
- [ ] Test in light and dark mode
- [ ] Test with different Dynamic Type sizes
- [ ] Test with VoiceOver enabled
- [ ] Test on smallest device (iPhone SE)
- [ ] Test on largest device (Pro Max)
- [ ] Verify all tap targets are at least 44pt
- [ ] Check color contrast ratios
- [ ] Verify semantic color usage

---

## Resources

- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols Browser](https://developer.apple.com/sf-symbols/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

