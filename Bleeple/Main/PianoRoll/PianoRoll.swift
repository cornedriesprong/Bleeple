//
//  PianoRoll.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

public struct NoteOffsetsKey: PreferenceKey {
   public static var defaultValue: [NoteOffsetInfo] = []

   public static func reduce(value: inout [NoteOffsetInfo], nextValue: () -> [NoteOffsetInfo]) {
      value.append(contentsOf: nextValue())
   }
}

public struct NoteOffsetInfo: Equatable {
   public var offset: CGSize
   public var eventId: String
}

struct PianoRollGrid: Shape {
   let gridSize: CGSize
   let width: Int
   let height: Int

   func path(in rect: CGRect) -> Path {
      let size = rect.size
      var path = Path()

      func drawHorizontal(count: Int, width: Double) {
         for column in 0...count {
            let anchor = Double(column) * width
            path.move(to: CGPoint(x: anchor, y: 0))
            path.addLine(to: CGPoint(x: anchor, y: size.height))
         }
      }

      func drawVertical(count: Int, height: Double) {
         for row in 0...count {
            let anchor = Double(row) * height
            path.move(to: CGPoint(x: 0, y: anchor))
            path.addLine(to: CGPoint(x: size.width, y: anchor))
         }
      }

      drawHorizontal(count: width, width: gridSize.width)
      drawVertical(count: height, height: gridSize.height)

      return path
   }
}

struct PianoRoll: View {
   @Environment(\.color) private var color
   @Binding var viewModel: MainView.ViewModel

   @State private var gridSize = CGSize(width: 33, height: 33)
   @State private var dragStartPoint: CGPoint = .zero
   @State private var dragCurrentPoint: CGPoint = .zero
   @State private var isDragging: Bool = false
   @State private var isZooming: Bool = false
   @State private var zoomStartSize: CGSize?

   let length = 32
   let pitchCount = Constants.pitchCount

   private var width: CGFloat {
      CGFloat(length) * gridSize.width
   }

   private var height: CGFloat {
      CGFloat(pitchCount) * gridSize.height
   }

   var body: some View {
      // TODO: move scrollview here so we can control it for magnification
      ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
         let dragGesture = DragGesture(minimumDistance: 0)
            .onChanged { value in
               if !isDragging {
                  dragStartPoint = value.startLocation
                  isDragging = true
               }
               dragCurrentPoint = value.location

               // check if notes are selected
               let selectionRect = CGRect(
                  x: min(dragStartPoint.x, dragCurrentPoint.x),
                  y: min(dragStartPoint.y, dragCurrentPoint.y),
                  width: abs(dragCurrentPoint.x - dragStartPoint.x),
                  height: abs(dragCurrentPoint.y - dragStartPoint.y)
               )

               for (index, event) in viewModel.events.enumerated() {
                  let eventRect = CGRect(
                     x: CGFloat(event.start) * gridSize.width,
                     y: CGFloat(pitchCount - event.pitch) * gridSize.height,
                     width: gridSize.width * event.duration,
                     height: gridSize.height
                  )

                  if selectionRect.intersects(eventRect) {
                     viewModel.events[index].isSelected = true
                  } else {
                     viewModel.events[index].isSelected = false
                  }
               }
            }
            .onEnded { value in
               isDragging = false
               let dragDistance = CGPoint(
                  x: dragCurrentPoint.x - dragStartPoint.x,
                  y: dragCurrentPoint.y - dragStartPoint.y
               )
               let distance = sqrt(dragDistance.x * dragDistance.x + dragDistance.y * dragDistance.y)

               if distance < 10 {
                  let location = value.location
                  let step = Double(Int(location.x / gridSize.width))
                  let pitch = pitchCount - Int8(location.y / gridSize.height)
                  let event = Event(
                     pitch: Int8(pitch),
                     start: step,
                     track: Int8(viewModel.selectedTrack)
                  )
                  viewModel.addEvent(event)
               }
            }

         let tapGesture = TapGesture()
            .onEnded {
               viewModel.deselectAll()
            }

         let magnifyGesture = MagnifyGesture()
            .onChanged { value in
               if let zoomStartSize {
                  gridSize = CGSize(
                     width: zoomStartSize.width * value.magnification,
                     height: zoomStartSize.height * value.magnification
                  )
               } else {
                  zoomStartSize = gridSize
               }
            }
            .onEnded { _ in
               zoomStartSize = nil
            }

         PianoRollGrid(
            gridSize: gridSize,
            width: length,
            height: Int(pitchCount)
         )
         .stroke(lineWidth: 0.5)
         .foregroundColor(Color.gray.opacity(0.3))
         .contentShape(Rectangle())
         .gesture(TapGesture().simultaneously(with: dragGesture))
         .simultaneousGesture(magnifyGesture)

         ForEach($viewModel.events) { $event in
            EventView(
               event: $event,
               length: length,
               pitchCount: pitchCount,
               gridSize: gridSize
            )
            .onTapGesture(count: 2) {
               viewModel.removeEvent(event)
            }
            .simultaneousGesture(
               TapGesture()
                  .onEnded {
                     event.isSelected.toggle()
                  }
            )
         }

         // selection rectangle
         if isDragging {
            Rectangle()
               .fill(color.opacity(0.1))
               .stroke(color, lineWidth: 0.5)
               .frame(
                  width: abs(dragCurrentPoint.x - dragStartPoint.x),
                  height: abs(dragCurrentPoint.y - dragStartPoint.y)
               )
               .position(
                  x: min(dragStartPoint.x, dragCurrentPoint.x) + abs(dragCurrentPoint.x - dragStartPoint.x) / 2,
                  y: min(dragStartPoint.y, dragCurrentPoint.y) + abs(dragCurrentPoint.y - dragStartPoint.y) / 2
               )
         }

         TimelineView(.animation) { _ in
            Canvas { context, size in
               var path = Path()
               let anchor = CGFloat(viewModel.playbackPosition) * gridSize.width * 4
               path.move(to: CGPoint(x: anchor, y: 0))
               path.addLine(to: CGPoint(x: anchor, y: size.height))
               context.stroke(path, with: .color(.primary), lineWidth: 1)

               // Update the playing state of events
               let newPlayingIndices = viewModel.events.indices.filter { index in
                  let event = viewModel.events[index]
                  let eventStart = CGFloat(event.start) * gridSize.width
                  let eventEnd = CGFloat(event.start + event.duration) * gridSize.width
                  return anchor >= eventStart && anchor <= eventEnd
               }

               // Only update if there are changes
               if newPlayingIndices != viewModel.playingIndices {
                  for playingIndex in viewModel.playingIndices {
                     guard viewModel.events.count > playingIndex else { continue }
                     viewModel.events[playingIndex].isPlaying = false
                  }
                  for newPlayingIndex in newPlayingIndices {
                     viewModel.events[newPlayingIndex].isPlaying = true
                  }
                  viewModel.playingIndices = newPlayingIndices
               }
            }
         }
         .allowsHitTesting(false)
      }
      .frame(width: width, height: height)
   }
}
