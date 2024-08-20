//
//  EventView.swift
//  Bleeple
//
//  Created by Corné on 8/20/24.
//

import SwiftUI

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
      .border(event.isSelected ? Color.primary : Color.clear, width: 2)
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
