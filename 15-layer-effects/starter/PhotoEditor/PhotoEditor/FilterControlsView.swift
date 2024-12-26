/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import Metal
import MetalKit
import Combine
import SwiftUI

protocol FilterParamaters: View, Identifiable {
    associatedtype T
    var id: String { get }
    var name: String { get set }
    var value: T { get set }
}

protocol BindingFilterParamaters: FilterParamaters {
    var binding: CustomBinding<T> { get set }
}

protocol CompletionHandlerFilterParamaters: FilterParamaters {
    var updater: (T) -> Void { get set }
}

extension FilterParamaters {
    var type: PickerType? {
        return PickerType(rawValue: String(describing: self))
    }
}

class CustomBinding<T> {
    var get: (() -> (T))
    var set: ((T) -> Void)
    
    init(get: @escaping () -> T, set: @escaping (T) -> Void) {
        self.get = get
        self.set = set
    }
}

struct SliderParameters: BindingFilterParamaters {
    var binding: CustomBinding<Float>
    var id: String { name }
    var name: String
    let step: Float.Stride
    let range: ClosedRange<Float>
    @State var value: Float
    
    var body: some View {
        VStack {
            Text(name + ": " + String(describing: (value * 10).int.float / 10))
            Slider(value: .init(get: { binding.get() }, set: { value = $0; binding.set($0) }), in: range)
        }
    }
}

struct PickerParameters: BindingFilterParamaters {
    var binding: CustomBinding<String>
    var id: String { name }
    var name: String
    @State var value: String
    var values: [String]
    var body: some View {
        VStack {
            Picker(name, selection: .init(get: {
                return value
            }, set: {
                value = $0
                binding.set($0)
            })) {
                ForEach(values, id: \.self) {
                    Text($0)
                }
            }
        }
    }
}

struct ColorPickerParameters: BindingFilterParamaters {
    var binding: CustomBinding<Color>
    var id: String { name }
    var name: String
    @State var value: Color
    var body: some View {
        HStack {
            Text(name)
            ColorPicker(name, selection: Binding(get: {
                return binding.get()
            }, set: {
                value = $0
                binding.set($0)
            }))
        }
    }
}

struct ImagePickerParameters: CompletionHandlerFilterParamaters {
    var id: String { name }
    var name: String
    var value: String
    var updater: (String) -> Void
    var body: some View {
        return
            MediaPicker(title: "Choose \(name)") { url in
                updater(url.absoluteString)
            }
    }
}

enum PickerType: String {
    case imagePicker
    case colorPicker
    case picker
    case slider

    init?(rawValue: String) {
        switch rawValue {
        case String(describing: ImagePickerParameters.self):
            self = .imagePicker
        case String(describing: ColorPickerParameters.self):
            self = .colorPicker
        case String(describing: PickerParameters.self):
            self = .picker
        case String(describing: SliderParameters.self):
            self = .slider
        default:
            return nil
        }
    }
}

struct FilterControlsView: View {
    let name: String
    var parameters: [any FilterParamaters]
    var hasToggle: Bool = false
    @State private var isEnabled: Bool
    var isEnabledCallback: (Bool) -> () = { _ in }
    var cancellables: Set<AnyCancellable> = []

    init(name: String, parameters: [any FilterParamaters]) {
        self.name = name
        self.parameters = parameters
        self.isEnabled = true
    }
    
    mutating func makeTogglable(enabled: Bool, callback: @escaping (Bool) -> ()) {
        self.hasToggle = true
        self._isEnabled = State(initialValue: enabled)
        self.isEnabledCallback = callback
    }

    var body: some View {
        return
            VStack {
                if hasToggle {
                    HStack {
                        #if os(iOS)
                            Toggle(isOn: $isEnabled) {
                                Text("Enable \(name)")
                            }.toggleStyle(.switch).onChange(of: isEnabled) {
                                withAnimation {
                                    self.isEnabledCallback(isEnabled)
                                }
                            }
                        #else
                            Toggle(isOn: $isEnabled) {
                                Text("Enable \(name)")
                            }.toggleStyle(.checkbox).onChange(of: isEnabled) {
                                withAnimation(.easeInOut) {
                                    self.isEnabledCallback(isEnabled)
                                }
                            }
                        #endif

                    }.frame(maxWidth: .infinity, minHeight: 44.0)
                        .shadow(radius: 4.0)
                        .background {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(AnyShapeStyle(isEnabled ? Color.accentColor.gradient.opacity(0.2) : Color.gray.gradient.opacity(0.2)))
                        }
                }
                if isEnabled {
                    VStack {
                        ForEach(self.parameters.compactMap({ $0 as? SliderParameters }), id: \.id) {
                            $0
                        }
                        ForEach(self.parameters.compactMap({ $0 as? PickerParameters }), id: \.id) {
                            $0
                        }
                        ForEach(self.parameters.compactMap({ $0 as? ColorPickerParameters }), id: \.id) {
                            $0
                        }
                        ForEach(self.parameters.compactMap({ $0 as? ImagePickerParameters }), id: \.id) {
                            $0
                        }
                    }.padding(8.0)
                }

            }.background {
                if hasToggle {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(AnyShapeStyle(isEnabled ? Color.gray.gradient.opacity(0.1) : Color.clear.gradient.opacity(0)))
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(isEnabled ? Color.green.gradient.opacity(0.3) : Color.gray.gradient.opacity(0.2))
                }
            }.frame(maxWidth: .infinity)
        
    }
}
