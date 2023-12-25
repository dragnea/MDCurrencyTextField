//
//  CurrencyTextField.swift
//  CurrencyTextField
//
//  Created by Mihai Dragnea on 23.12.2023.
//

import UIKit

public protocol CurrencyTextFieldDelegate: UITextFieldDelegate {
    func textField(_ textFied: CurrencyTextField, didChange value: Decimal)
}

public class CurrencyTextField: UITextField {
    
    public var maximumIntegerDigits: Int {
        get {
            return textFieldImpl.formatter.maximumIntegerDigits
        }
        set {
            textFieldImpl.formatter.maximumIntegerDigits = newValue
        }
    }
    
    public var maximumFractionDigits: Int {
        get {
            return textFieldImpl.formatter.maximumFractionDigits
        }
        set {
            textFieldImpl.formatter.maximumFractionDigits = newValue
        }
    }
    
    public var currencySymbol: String {
        get {
            return textFieldImpl.formatter.currencySymbol
        }
        set {
            textFieldImpl.formatter.currencySymbol = newValue
            textFieldImpl.formatterUpdated(textField: self)
        }
    }
    
    public var locale: Locale {
        get {
            return textFieldImpl.formatter.locale
        }
        set {
            textFieldImpl.formatter.locale = newValue
            textFieldImpl.formatterUpdated(textField: self)
        }
    }
    
    public override weak var delegate: UITextFieldDelegate? {
        get {
            return textFieldImpl.forwardingDelegate
        }
        set {
            textFieldImpl.forwardingDelegate = newValue
        }
    }
    
    public override var keyboardType: UIKeyboardType {
        get {
            return super.keyboardType
        }
        set {
            super.keyboardType = .decimalPad
        }
    }
    
    private let textFieldImpl = TextFieldDelegateImpl()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        keyboardType = .decimalPad
        adjustsFontSizeToFitWidth = true
        super.delegate = textFieldImpl
    }
    
    /**
     - Parameters:
        - value: The value is formatted to text and displayed in the textField.
     - Precondition: A nil **value** will clear the textField. The placeholder will be displayed
    */
    public func setValue(_ value: Decimal?) {
        textFieldImpl.setValue(textField: self, decimal: value, callDelegate: false)
    }
    
    /**
     Whenever is needed to display the string value with the same format as the text field
        - Parameters:
            - value: Decimal value to be formatted
        - Returns: String value with the same format as the text field
     */
    public func formatted(value: Decimal) -> String? {
        return textFieldImpl.formattedString(from: value)
    }
    
    public override func closestPosition(to point: CGPoint) -> UITextPosition? {
        guard let desiredPosition = super.closestPosition(to: point) else {
            return nil
        }
        return textFieldImpl.textPosition(textField: self, desiredPosition: desiredPosition)
    }
    
}

