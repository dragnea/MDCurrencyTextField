//
//  MDCurrencyTextFieldImpl.swift
//  MDCurrencyTextFieldImpl
//
//  Created by Mihai Dragnea on 23.12.2023.
//

import UIKit

internal class MDCurrencyTextFieldImpl: NSObject, UITextFieldDelegate {
    
    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumIntegerDigits = 1
        formatter.maximumIntegerDigits = 12
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    weak var forwardingDelegate: UITextFieldDelegate?
    
    var value: Decimal = 0
    
    func isValidChar(_ char: Character) -> Bool {
        return char.isNumber || String(char) == formatter.decimalSeparator
    }
    
    func decimalNumberAsString(input: String) -> String {
        return input.filter { isValidChar($0) }
    }
    
    func formattedString(from decimal: Decimal) -> String? {
        return formatter.string(from: decimal as NSNumber)
    }
    
    func decimalNumber(from string: String) -> Decimal? {
        return Decimal(string: string, locale: formatter.locale)
    }
    
    func editedString(textField: UITextField, string: String, range: NSRange) -> String? {
        let text = textField.text ?? ""
        guard let textRange = Range(range, in: text) else {
            return nil
        }
        return text.replacingCharacters(in: textRange, with: string)
    }
    
    /// only  the number representation (digits, decimal separator and grouping separator)
    func cleanNumber(for text: String) -> String {
        return text.filter { $0.isNumber || String($0) == formatter.decimalSeparator || String($0) == formatter.groupingSeparator }
    }
    
    func textPosition(textField: UITextField, desiredPosition: UITextPosition) -> UITextPosition? {
        guard let text = textField.text else {
            return desiredPosition
        }
        let cleanNumber = cleanNumber(for: text)
        guard text != cleanNumber, let numberRange = text.range(of: cleanNumber) else {
            return desiredPosition
        }
        let desiredCursorOffset = textField.offset(from: textField.beginningOfDocument, to: desiredPosition)
        let numberLeftOffset = text.distance(from: text.startIndex, to: numberRange.lowerBound)
        let numberRightOffset = text.distance(from: text.startIndex, to: numberRange.upperBound)
        if desiredCursorOffset <= numberLeftOffset {
            return textField.position(from: textField.beginningOfDocument, offset: numberLeftOffset + 1)
        } else if desiredCursorOffset > numberRightOffset {
            return textField.position(from: textField.beginningOfDocument, offset: numberRightOffset)
        } else {
            return desiredPosition
        }
    }
    
    func resetCursor(textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        let cleanNumber = cleanNumber(for: text)
        guard let numberRange = text.range(of: cleanNumber) else {
            return
        }
        let offset = text.distance(from: text.startIndex, to: numberRange.upperBound)
        guard let newCursorPosition = textField.position(from: textField.beginningOfDocument, offset: offset) else {
            return
        }
        textField.selectedTextRange = textField.textRange(from: newCursorPosition, to: newCursorPosition)
    }
    
    func numberComponents(for text: String) -> (integer: String, fraction: String) {
        let components = text.components(separatedBy: formatter.decimalSeparator)
        switch components.count {
        case 2:
            return (components[0], components[1])
        case 1:
            return (components[0], "")
        default:
            return ("", "")
        }
    }
    
    func formatterUpdated(textField: UITextField) {
        textField.placeholder = formattedString(from: 0)
    }
    
    func setValue(textField: UITextField, decimal: Decimal?, callDelegate: Bool = true) {
        if let decimal {
            value = decimal
            textField.text = formattedString(from: decimal)
            resetCursor(textField: textField)
        } else {
            value = 0
            textField.text = nil
        }
        if let textField = (textField as? MDCurrencyTextField), callDelegate {
            (forwardingDelegate as? MDCurrencyTextFieldDelegate)?.textField(textField, didChange: value)
        }
    }
    
    func handleChange(textField: UITextField, string: String, range: NSRange) -> Bool {
        guard string.isEmpty || Array(string)[0].isNumber || string == formatter.decimalSeparator else {
            return false
        }
        // current string + input change
        guard let editedText = editedString(textField: textField, string: string, range: range) else {
            return false
        }
        // text deleted completely. show placeholder, set zero value
        guard !editedText.isEmpty else {
            setValue(textField: textField, decimal: nil)
            return false
        }
        // allow one decimal
        guard editedText.filter({ String($0) == formatter.decimalSeparator }).count < 2 else {
            return false
        }
        
        // get the decimal value as string, without other characters like space or currency symbols
        let decimalNumberString = decimalNumberAsString(input: editedText)
        
        guard !decimalNumberString.isEmpty else {
            setValue(textField: textField, decimal: nil)
            return false
        }
        // allow only one 0 digit first
        if decimalNumberString == "0" || decimalNumberString == "00" {
            setValue(textField: textField, decimal: 0)
            return false
        }
        
        // validate and get the decimal value
        guard let decimal = decimalNumber(from: decimalNumberString) else {
            return false
        }
        
        // get interger and fractionar values separately
        let numberComponents = numberComponents(for: decimalNumberString)
        
        switch (numberComponents.integer.count, numberComponents.fraction.count) {
        case (1...formatter.maximumIntegerDigits, 0...formatter.maximumFractionDigits):
            if value == decimal {
                return true // allow the change
            }
            setValue(textField: textField, decimal: decimal)
            return false
        default:
            return false
        }
    }
    
    func handlePaste(textField: UITextField, string: String) -> Bool {
        let decimalNumberString = decimalNumberAsString(input: string)
        guard let number = decimalNumber(from: decimalNumberString) else {
            return false
        }
        textField.text = formattedString(from: number)
        return false
    }
    
    
    // MARK: - UITextFieldDelegate -
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        defer {
            textField.sendActions(for: .editingChanged)
        }
        
        if string.count > 1, string == UIPasteboard.general.string {
            return handlePaste(textField: textField, string: string)
        } else {
            return handleChange(textField: textField, string: string, range: range)
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return forwardingDelegate?.textFieldShouldClear?(textField) ?? true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return forwardingDelegate?.textFieldShouldReturn?(textField) ?? true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return forwardingDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        forwardingDelegate?.textFieldDidBeginEditing?(textField)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return forwardingDelegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        forwardingDelegate?.textFieldDidEndEditing?(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        forwardingDelegate?.textFieldDidEndEditing?(textField, reason: reason)
    }
    
    @available(iOS 13.0, *)
    func textFieldDidChangeSelection(_ textField: UITextField) {
        forwardingDelegate?.textFieldDidChangeSelection?(textField)
    }
    
    @available(iOS 16.0, *)
    func textField(_ textField: UITextField, willDismissEditMenuWith animator: UIEditMenuInteractionAnimating) {
        forwardingDelegate?.textField?(textField, willDismissEditMenuWith: animator)
    }
    
    @available(iOS 16.0, *)
    func textField(_ textField: UITextField, willPresentEditMenuWith animator: UIEditMenuInteractionAnimating) {
        forwardingDelegate?.textField?(textField, willPresentEditMenuWith: animator)
    }
    
    @available(iOS 16.0, *)
    func textField(_ textField: UITextField, editMenuForCharactersIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        return forwardingDelegate?.textField?(textField, editMenuForCharactersIn: range, suggestedActions: suggestedActions)
    }
    
}
