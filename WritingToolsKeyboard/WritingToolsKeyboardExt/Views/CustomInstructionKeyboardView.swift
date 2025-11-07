//
//  CustomInstructionKeyboardView.swift
//  ProseKey AI
//
//  Created by Arya Mirsepasi on 04.08.25.
//

import UIKit

protocol CustomInstructionKeyboardDelegate: AnyObject {
  func keyboardInsert(_ text: String)
  func keyboardDeleteBackward()
  func keyboardReturn()
  func keyboardToggleSymbols()
  func keyboardToggleShift(mode: CustomInstructionKeyboardView.ShiftMode)
  func keyboardSwitchSymbolsPage(_ page: Int)
}

final class CustomInstructionKeyboardView: UIView {

    enum LayoutMode: Equatable { case letters, symbols(page: Int) }
  enum ShiftMode { case off, shifted, capsLock }

  weak var delegate: CustomInstructionKeyboardDelegate?

  private(set) var layoutMode: LayoutMode = .letters
  private(set) var shiftMode: ShiftMode = .off

  private let stack = UIStackView()
  private let feedback = UIImpactFeedbackGenerator(style: .light)

  // Data
  private let qwertyRows: [[String]] = [
    ["q","w","e","r","t","y","u","i","o","p"],
    ["a","s","d","f","g","h","j","k","l"],
    ["z","x","c","v","b","n","m"]
  ]

  private let symbolsPage1: [[String]] = [
    ["1","2","3","4","5","6","7","8","9","0"],
    ["-","/",";",":","(",")","$","&","@","\""],
    [".",",","?","!","'"]
  ]

  private let symbolsPage2: [[String]] = [
    ["[","]","{","}","#","%","^","*","+","="],
    ["_","\\","|","~","<",">","€","£","¥","•"],
    [".",",","?","!","'"]
  ]

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    backgroundColor = .clear
    stack.axis = .vertical
    stack.distribution = .fillEqually
    stack.alignment = .fill
    stack.spacing = 6
    addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
    ])

    reloadLayout()
  }

  // MARK: - Building rows

  private func clearRows() {
    stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
  }

  private func makeKey(title: String,
                       buttonBackground: UIColor = UIColor.systemGray5,
                       width: CGFloat? = nil,
                       action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: title.count == 1 ? 18 : 14, weight: .medium)
    button.setTitleColor(.label, for: .normal)
    button.backgroundColor = buttonBackground
    button.layer.cornerRadius = 6
    button.layer.borderWidth = 0.5
    button.layer.borderColor = UIColor.systemGray4.cgColor
    button.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      if UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?.bool(forKey: "enable_haptics") ?? true {
        self.feedback.impactOccurred()
      }
      action()
    }, for: .touchUpInside)

    if let width = width {
      button.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    return button
  }

    private func addRow(_ views: [UIView], horizontalInset: CGFloat = 0, rowHeight: CGFloat = 36) {
      let row = UIStackView(arrangedSubviews: views)
      row.axis = .horizontal
      row.distribution = .fillEqually
      row.alignment = .fill
      row.spacing = 4

      let container = UIView()
      container.addSubview(row)
      row.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontalInset),
        row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -horizontalInset),
        row.topAnchor.constraint(equalTo: container.topAnchor),
        row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        container.heightAnchor.constraint(equalToConstant: rowHeight) 
      ])
      stack.addArrangedSubview(container)
    }

  // MARK: - Layouts

  func reloadLayout() {
    clearRows()

    switch layoutMode {
    case .letters:
      buildLetterRows()
    case .symbols(let page):
      buildSymbolRows(page: page)
    }

    buildBottomBar()
  }

  private func displayText(_ letter: String) -> String {
    switch shiftMode {
    case .off: return letter
    case .shifted, .capsLock: return letter.uppercased()
    }
  }

  private func buildLetterRows() {
    // row 1
      addRow(qwertyRows[0].map { key in
        makeKey(title: displayText(key)) { [weak self] in self?.insert(display: key) }
      }, horizontalInset: 6, rowHeight: 30)

    // row 2
      addRow(qwertyRows[1].map { key in
        makeKey(title: displayText(key)) { [weak self] in self?.insert(display: key) }
      }, horizontalInset: 14, rowHeight: 30)

    // row 3: shift + letters + delete
    var third: [UIView] = []
      let shiftKey = makeKey(title: "⇧",
                             buttonBackground: (shiftMode == .off ? UIColor.systemGray4
                                         : UIColor.systemBlue.withAlphaComponent(0.3)),
                             width: 40) { [weak self] in self?.handleShiftTap() }
      
    third.append(shiftKey)

    third.append(contentsOf: qwertyRows[2].map { key in
      makeKey(title: displayText(key)) { [weak self] in self?.insert(display: key) }
    })

      let deleteKey = makeKey(title: "⌫", buttonBackground: .systemGray4, width: 40) { [weak self] in
        self?.delegate?.keyboardDeleteBackward()
      }
    third.append(deleteKey)

      addRow(third, horizontalInset: 6, rowHeight: 30)
  }

  private func buildSymbolRows(page: Int) {
    let set = (page == 1) ? symbolsPage1 : symbolsPage2

      addRow(set[0].map { s in makeKey(title: s) { [weak self] in self?.delegate?.keyboardInsert(s) } },
             horizontalInset: 6, rowHeight: 30)

      addRow(set[1].map { s in makeKey(title: s) { [weak self] in self?.delegate?.keyboardInsert(s) } },
             horizontalInset: 14, rowHeight: 30)

    var third: [UIView] = []
      let switchPage = makeKey(title: "#+", buttonBackground: .systemGray4, width: 40) { [weak self] in
      guard let self else { return }
      let next = (page == 1) ? 2 : 1
      self.layoutMode = .symbols(page: next)
      self.delegate?.keyboardSwitchSymbolsPage(next)
      self.reloadLayout()
    }
    third.append(switchPage)

    third.append(contentsOf: set[2].map { s in
      makeKey(title: s) { [weak self] in self?.delegate?.keyboardInsert(s) }
    })

    let deleteKey = makeKey(title: "⌫", buttonBackground: UIColor.systemGray4, width: 44) { [weak self] in
      self?.delegate?.keyboardDeleteBackward()
    }
    third.append(deleteKey)

      addRow(third, horizontalInset: 6, rowHeight: 30)
  }
    
    

  private func buildBottomBar() {
    let row = UIStackView()
    row.axis = .horizontal
    row.distribution = .fill
    row.alignment = .fill
    row.spacing = 4
      
      let toggleSymbols = makeKey(title: (layoutMode == .letters) ? "123" : "ABC",
                                  buttonBackground: .systemGray4, width: 56) { [weak self] in
        guard let self else { return }
        switch self.layoutMode {
        case .letters:
          self.layoutMode = .symbols(page: 1)
        case .symbols:
          self.layoutMode = .letters
        }
        self.delegate?.keyboardToggleSymbols()
        self.reloadLayout()
      }

      let space = makeKey(title: "space") { [weak self] in self?.delegate?.keyboardInsert(" ") }
      space.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)

      let ret = makeKey(title: "return", buttonBackground: .systemGray4, width: 66) { [weak self] in
        self?.delegate?.keyboardReturn()
      }

    row.addArrangedSubview(toggleSymbols)
    row.addArrangedSubview(space)
    row.addArrangedSubview(ret)

      addRow([row], horizontalInset: 0, rowHeight: 36)  }

  private func insert(display key: String) {
    let text = (shiftMode == .off) ? key : key.uppercased()
    delegate?.keyboardInsert(text)

    // Reset single shift after one character
    if shiftMode == .shifted {
      shiftMode = .off
      reloadLayout()
    }
  }

  private func handleShiftTap() {
    // tap behavior: off -> shifted -> capsLock -> off
    switch shiftMode {
    case .off: shiftMode = .shifted
    case .shifted: shiftMode = .capsLock
    case .capsLock: shiftMode = .off
    }
    delegate?.keyboardToggleShift(mode: shiftMode)
    reloadLayout()
  }
}
