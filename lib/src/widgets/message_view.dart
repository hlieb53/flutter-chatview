/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'package:chatview/src/controller/chat_controller.dart';
import 'package:flutter/material.dart';

import 'package:chatview/src/extensions/extensions.dart';
import 'package:chatview/src/models/models.dart';

import '../utils/constants.dart';
import '../values/typedefs.dart';
import 'image_message_view.dart';
import 'text_message_view.dart';
import 'reaction_widget.dart';

class MessageView extends StatefulWidget {
  const MessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    required this.onLongPress,
    required this.chatController,
    this.chatBubbleMaxWidth,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.longPressAnimationDuration,
    this.onDoubleTap,
    this.highlightColor = Colors.grey,
    this.shouldHighlight = false,
    this.highlightScale = 1.2,
    this.messageConfig,
  }) : super(key: key);

  final Message message;
  final bool isMessageBySender;
  final DoubleCallBack onLongPress;
  final double? chatBubbleMaxWidth;
  final ChatBubble? inComingChatBubbleConfig;
  final ChatBubble? outgoingChatBubbleConfig;
  final Duration? longPressAnimationDuration;
  final MessageCallBack? onDoubleTap;
  final Color highlightColor;
  final bool shouldHighlight;
  final double highlightScale;
  final ChatController chatController;
  final MessageConfiguration? messageConfig;

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  MessageConfiguration? get messageConfig => widget.messageConfig;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.longPressAnimationDuration ??
          const Duration(milliseconds: 250),
      upperBound: 0.1,
      lowerBound: 0.0,
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message.message;
    final emojiMessageConfiguration = messageConfig?.emojiMessageConfig;
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onDoubleTap: () {
        if (widget.onDoubleTap != null) widget.onDoubleTap!(widget.message);
      },
      child: AnimatedBuilder(
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: 1 - _animationController.value,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: widget.message.reaction.reactions.isNotEmpty ? 6 : 0),
              child: (() {
                if (message.isAllEmoji) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: emojiMessageConfiguration?.padding ??
                            EdgeInsets.fromLTRB(
                              leftPadding2,
                              4,
                              leftPadding2,
                              widget.message.reaction.reactions.isNotEmpty
                                  ? 14
                                  : 0,
                            ),
                        child: Transform.scale(
                          scale: widget.shouldHighlight
                              ? widget.highlightScale
                              : 1.0,
                          child: Text(
                            message,
                            style: emojiMessageConfiguration?.textStyle ??
                                const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                      if (widget.message.reaction.reactions.isNotEmpty)
                        ReactionWidget(
                          chatController: widget.chatController,
                          reaction: widget.message.reaction,
                          messageReactionConfig:
                              messageConfig?.messageReactionConfig,
                          isMessageBySender: widget.isMessageBySender,
                        ),
                    ],
                  );
                } else if (widget.message.messageType.isImage) {
                  return ImageMessageView(
                    message: widget.message,
                    chatController: widget.chatController,
                    isMessageBySender: widget.isMessageBySender,
                    imageMessageConfig: messageConfig?.imageMessageConfig,
                    messageReactionConfig: messageConfig?.messageReactionConfig,
                    highlightImage: widget.shouldHighlight,
                    highlightScale: widget.highlightScale,
                  );
                } else if (widget.message.messageType.isText) {
                  return TextMessageView(
                    inComingChatBubbleConfig: widget.inComingChatBubbleConfig,
                    outgoingChatBubbleConfig: widget.outgoingChatBubbleConfig,
                    isMessageBySender: widget.isMessageBySender,
                    message: widget.message,
                    chatBubbleMaxWidth: widget.chatBubbleMaxWidth,
                    messageReactionConfig: messageConfig?.messageReactionConfig,
                    chatController: widget.chatController,
                    highlightColor: widget.highlightColor,
                    highlightMessage: widget.shouldHighlight,
                  );
                } else if (widget.message.messageType.isCustom &&
                    messageConfig?.customMessageBuilder != null) {
                  return messageConfig?.customMessageBuilder!(widget.message);
                }
              }()),
            ),
          );
        },
        animation: _animationController,
      ),
    );
  }

  void _onLongPressStart(LongPressStartDetails details) async {
    await _animationController.forward();
    widget.onLongPress(
      details.globalPosition.dy - 120 - 64,
      details.globalPosition.dx,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
