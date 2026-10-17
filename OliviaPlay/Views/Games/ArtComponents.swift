import SwiftUI

struct ArtStudioFrame<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let onExit: () -> Void
    let onListen: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    Button(action: onExit) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24, weight: .bold))
                            .frame(width: 58, height: 58)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Voltar à casinha")
                    VStack(alignment: .leading, spacing: 4) {
                        Label(title, systemImage: icon)
                            .font(PlayTheme.font(geometry.size.width < 700 ? 21 : 26, .heavy))
                        Text(subtitle).font(PlayTheme.font(13, .medium))
                            .foregroundStyle(PlayTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Button(action: onListen) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 23, weight: .semibold))
                            .frame(width: 58, height: 58)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Ouvir como brincar")
                }
                .foregroundStyle(accent)
                content().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(geometry.size.width < 700 ? 16 : 24)
            .background(PlayTheme.paper.ignoresSafeArea())
            .foregroundStyle(PlayTheme.ink)
        }
    }
}

struct ArtActionButton: View {
    let title: String
    let icon: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(PlayTheme.font(13, .bold))
                .frame(maxWidth: .infinity, minHeight: 46)
                .padding(.horizontal, 8)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(PlayTheme.pink.opacity(0.18)))
        }
        .buttonStyle(BouncyButtonStyle())
        .foregroundStyle(PlayTheme.ink)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}

struct ArtPalette: View {
    @Binding var color: ArtColor
    @Binding var texture: ArtTexture

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cores").font(PlayTheme.font(15, .heavy))
                Spacer()
                Text(color.title).font(PlayTheme.font(12, .medium)).foregroundStyle(PlayTheme.muted)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 6)], spacing: 6) {
                ForEach(ArtColor.allCases) { swatch in
                    Button { color = swatch } label: {
                        Circle().fill(Color(hex: swatch.hex))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().strokeBorder(PlayTheme.ink.opacity(0.15), lineWidth: 1))
                            .overlay {
                                if color == swatch {
                                    Image(systemName: "checkmark").font(.system(size: 16, weight: .heavy))
                                        .foregroundStyle(swatch == .white || swatch == .yellow ? PlayTheme.ink : .white)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(Circle().strokeBorder(color == swatch ? PlayTheme.ink : .clear, lineWidth: 2))
                            .contentShape(Circle())
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel(swatch.title)
                    .accessibilityAddTraits(color == swatch ? [.isSelected] : [])
                    .accessibilityIdentifier("art-color-\(swatch.rawValue)")
                }
            }
            Text("Texturas").font(PlayTheme.font(15, .heavy)).padding(.top, 2)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 7)], spacing: 7) {
                ForEach(ArtTexture.allCases) { sample in
                    Button { texture = sample } label: {
                        VStack(spacing: 5) {
                            ArtFillShape(shape: RoundedRectangle(cornerRadius: 6), color: color, texture: sample)
                                .frame(width: 40, height: 23)
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(PlayTheme.ink.opacity(0.15)))
                            Text(sample.title).font(PlayTheme.font(11, .bold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(texture == sample ? PlayTheme.lavender : .white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(texture == sample ? PlayTheme.pink : PlayTheme.ink.opacity(0.10), lineWidth: texture == sample ? 2 : 1))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("Textura \(sample.title)")
                    .accessibilityAddTraits(texture == sample ? [.isSelected] : [])
                    .accessibilityIdentifier("art-texture-\(sample.rawValue)")
                }
            }
        }
        .foregroundStyle(PlayTheme.ink)
    }
}

/// Pattern and base share one clipping path, so paint never crosses a region's outline.
struct ArtFillShape<S: Shape>: View {
    let shape: S
    let color: ArtColor
    let texture: ArtTexture

    var body: some View {
        shape.fill(Color(hex: color.hex).opacity(texture == .smooth ? 1 : 0.28))
            .overlay {
                if texture != .smooth {
                    Canvas { context, size in
                        let ink = Color(hex: color.hex)
                        let contrast = color == .white ? Color(hex: 0xCCC5D0) : ink
                        switch texture {
                        case .smooth: break
                        case .dots:
                            for row in 0...Int(size.height / 16) {
                                for column in 0...Int(size.width / 16) {
                                    let x = CGFloat(column) * 16 + (row.isMultiple(of: 2) ? 3 : 11)
                                    let rect = CGRect(x: x, y: CGFloat(row) * 16 + 3, width: 5, height: 5)
                                    context.fill(Path(ellipseIn: rect), with: .color(contrast))
                                }
                            }
                        case .stripes:
                            var lines = Path()
                            for offset in stride(from: -size.height, through: size.width, by: 13) {
                                lines.move(to: CGPoint(x: offset, y: 0))
                                lines.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                            }
                            context.stroke(lines, with: .color(contrast), lineWidth: 4)
                        case .stars:
                            for row in 0...Int(size.height / 24) {
                                for column in 0...Int(size.width / 24) {
                                    let center = CGPoint(x: CGFloat(column) * 24 + (row.isMultiple(of: 2) ? 10 : 22), y: CGFloat(row) * 24 + 10)
                                    context.fill(artStar(center: center, radius: 6), with: .color(contrast))
                                }
                            }
                        case .crayon:
                            for row in 0...Int(size.height / 4) {
                                var line = Path()
                                let y = CGFloat(row) * 4
                                line.move(to: CGPoint(x: 0, y: y))
                                for x in stride(from: CGFloat(0), through: size.width + 6, by: 6) {
                                    line.addLine(to: CGPoint(x: x, y: y + sin(x * 1.7 + CGFloat(row)) * 1.8))
                                }
                                context.stroke(line, with: .color(contrast.opacity(row.isMultiple(of: 3) ? 0.8 : 0.5)), lineWidth: 2)
                            }
                        }
                    }
                    .clipShape(shape)
                    .allowsHitTesting(false)
                }
            }
    }

    private func artStar(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for index in 0..<10 {
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let length = index.isMultiple(of: 2) ? radius : radius * 0.45
                let point = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}
