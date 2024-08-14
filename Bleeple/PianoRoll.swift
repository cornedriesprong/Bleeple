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
         for column in 0 ... count {
            let anchor = Double(column) * width
            path.move(to: CGPoint(x: anchor, y: 0))
            path.addLine(to: CGPoint(x: anchor, y: size.height))
         }
      }

      func drawVertical(count: Int, height: Double) {
         for row in 0 ... count {
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
   @State var hovering = false
   var length: Int
   var height: Int
   var gridSize: CGSize

   var body: some View {
      // While dragging, show where the note will go.
      if offset != CGSize.zero {
          Rectangle()
              .foregroundColor(color.opacity(0.2))
              .frame(width: gridSize.width * event.length,
                     height: gridSize.height)
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
                    .foregroundColor(color.opacity((hovering || offset != .zero || lengthOffset != 0) ? 1.0 : 0.8))
            }
            Rectangle()
                .foregroundColor(.black)
                .padding(4)
                .frame(width: 10)
        }
        .onHover { over in hovering = over }
        .padding(1) // so we can see consecutive notes
        .frame(width: max(gridSize.width, gridSize.width * event.length + lengthOffset),
               height: gridSize.height)
        .offset(eventOffset(event: startEvent ?? event, dragOffset: offset))
        .gesture(dragGesture)
        .animation(.easeInOut(duration: 0.2), value: hovering)
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
        .frame(width: gridSize.width * event.length,
               height: gridSize.height)
        .offset(eventOffset(event: event, dragOffset: offset))
   }

   func snap(event: Event, offset: CGSize, lengthOffset: Double = 0.0) -> Event {
      var e = event

      e.start += round(offset.width / gridSize.width)
      e.start = max(0, e.start)
      e.start = min(Double(length - 1), e.start)
      e.pitch -= Int(round(offset.height / gridSize.height))
      e.pitch = max(1, e.pitch)
      e.pitch = min(height, e.pitch)
      e.length += lengthOffset / gridSize.width
      e.length = max(1, e.length)
      e.length = min(Double(length), e.length)
      e.length = min(Double(length) - e.start, e.length)

      return e
   }

   func eventOffset(event: Event, dragOffset: CGSize = .zero) -> CGSize {
      CGSize(
         width: gridSize.width * event.start + dragOffset.width,
         height: gridSize.height * (8.0 - Double(event.pitch)) + dragOffset.height
      )
   }
}

struct PianoRoll: View {
   @Environment(\.color) private var color
   @Binding var events: [Event]

   let gridSize = CGSize(width: 44, height: 44)
   let length = 16
   let height = 8

   var body: some View {
      ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
         let dragGesture = DragGesture(minimumDistance: 0).onEnded { value in
            let location = value.location
            let step = Double(Int(location.x / gridSize.width))
            let pitch = height - Int(location.y / gridSize.height)
            let event = Event(pitch: pitch, start: step)
            events.append(event)
         }

         PianoRollGrid(gridSize: gridSize, width: length, height: height)
            .stroke(lineWidth: 0.5)
            .foregroundColor(color.opacity(0.3))
            .contentShape(Rectangle())
            .gesture(TapGesture().sequenced(before: dragGesture))

         ForEach($events) { $event in
            EventView(
               event: $event,
               length: length,
               height: height,
               gridSize: gridSize
            )
            .onTapGesture {
               events.removeAll(where: { $0 == event })
            }
         }
      }
   }
}
