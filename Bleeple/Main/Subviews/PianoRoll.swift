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

struct EventView: View {
   @Environment(\.color) private var color
   @GestureState var offset = CGSize.zero
   @GestureState var startEvent: Event?
   @GestureState var lengthOffset = 0.0
   @Binding var event: Event
   @State var isHovering = false
   @State var isPlaying = false
   var length: Int
   var pitchCount: Int8
   var gridSize: CGSize

   var body: some View {
      // While dragging, show where the note will go.
      if offset != CGSize.zero {
         Rectangle()
            .foregroundColor(color.opacity(0.2))
            .frame(
               width: gridSize.width * event.duration,
               height: gridSize.height
            )
            .offset(eventOffset(event: event))
            .blendMode(.luminosity)
            .zIndex(-1)
      }

      // Set the minimum distance so a note drag will override
      // the drag of a containing ScrollView.
      let minimumDistance = 2.0

      // We don't want to actually update the data model until
      // the drag is completed, so the entire drag is recorded
      // as a single undo.
      let dragGesture = DragGesture(minimumDistance: minimumDistance)
         .updating($offset) { value, state, _ in
            state = value.translation
         }
         .updating($startEvent) { _, state, _ in
            if state == nil {
               state = event
            }
         }
         .onChanged { value in
            if let startEvent {
               event = snap(event: startEvent, offset: value.translation)
            }
         }

      let lengthDragGesture = DragGesture(minimumDistance: minimumDistance)
         .updating($lengthOffset) { value, state, _ in
            state = value.translation.width
         }
         .onEnded { value in
            event = snap(
               event: event,
               offset: CGSize.zero,
               lengthOffset: value.translation.width
            )
         }

      ZStack(alignment: .trailing) {
         ZStack(alignment: .leading) {
            Rectangle()
               .foregroundColor(
                  event.isPlaying
                     ? .primary
                     : color.opacity((isHovering || offset != .zero || lengthOffset != 0) ? 1.0 : 0.8))
         }

         Rectangle()
            .foregroundColor(.black)
            .padding(4)
            .frame(width: 10)
      }
      .onHover { over in isHovering = over }
      .border(event.isSelected ? Color.primary : Color.clear)
      .padding(1) // so we can see consecutive notes
      .frame(
         width: max(gridSize.width, gridSize.width * event.duration + lengthOffset),
         height: gridSize.height
      )
      .offset(eventOffset(event: startEvent ?? event, dragOffset: offset))
      .gesture(dragGesture)
      .animation(.easeInOut(duration: 0.2), value: isHovering)
      .animation(.easeOut(duration: 0.2), value: event.isPlaying)
      .animation(.easeOut(duration: 0.2), value: startEvent)
      //        .preference(key: NoteOffsetsKey.self,
      //                    value: [NoteOffsetInfo(offset: noteOffset(note: startNote ?? note, dragOffset: offset),
      //                                           noteId: note.id)])

      // Length tab at the end of the note.
      HStack {
         Spacer()
         Rectangle()
            .foregroundColor(.white.opacity(0.001))
            .frame(width: gridSize.width * 0.5, height: gridSize.height)
            .gesture(lengthDragGesture)
      }
      .frame(
         width: gridSize.width * event.duration,
         height: gridSize.height
      )
      .offset(eventOffset(event: event, dragOffset: offset))
   }

   func snap(event: Event, offset: CGSize, lengthOffset: Double = 0.0) -> Event {
      var e = event

      e.start += round(offset.width / gridSize.width)
      e.start = max(0, e.start)
      e.start = min(Double(length - 1), e.start)
      e.pitch -= Int8(round(offset.height / gridSize.height))
      e.pitch = max(1, e.pitch)
      e.pitch = min(pitchCount, e.pitch)
      e.duration += lengthOffset / gridSize.width
      e.duration = max(1, e.duration)
      e.duration = min(Double(length), e.duration)
      e.duration = min(Double(length) - e.start, e.duration)

      return e
   }

   func eventOffset(event: Event, dragOffset: CGSize = .zero) -> CGSize {
      CGSize(
         width: gridSize.width * event.start + dragOffset.width,
         height: gridSize.height * (Double(pitchCount) - Double(event.pitch)) + dragOffset.height
      )
   }
}

struct PianoRoll: View {
   @Environment(\.color) private var color
   @Environment(\.isShiftPressed) private var isShiftPressed
   @Binding var viewModel: MainView.ViewModel
   
   @State private var dragStartPoint: CGPoint = .zero
   @State private var dragCurrentPoint: CGPoint = .zero
   @State private var isDragging: Bool = false

   let gridSize = CGSize(width: 33, height: 33)
   let length = 32
   let pitchCount = Constants.pitchCount

   private var width: CGFloat {
      CGFloat(length) * gridSize.width
   }

   private var height: CGFloat {
      CGFloat(pitchCount) * gridSize.height
   }

   var body: some View {
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
                  let event = Event(pitch: Int8(pitch), start: step)
                  viewModel.addEvent(event)
               }
            }

         let tapGesture = TapGesture()
            .onEnded {
               viewModel.deselectAll()
            }

         PianoRollGrid(
            gridSize: gridSize,
            width: length,
            height: Int(pitchCount)
         )
         .stroke(lineWidth: 0.5)
         .foregroundColor(Color.gray.opacity(0.3))
         .contentShape(Rectangle())
         .gesture(dragGesture)
         .simultaneousGesture(tapGesture)

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
                     if !isShiftPressed {
                        viewModel.deselectAll()
                     }
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
               // TODO: this seems to crash when removing an event mid-playback
               if newPlayingIndices != viewModel.playingIndices {
                  for playingIndex in viewModel.playingIndices {
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
