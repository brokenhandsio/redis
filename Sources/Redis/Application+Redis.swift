import Vapor

extension Application {
    public struct Redis {
        public let id: RedisID

        @usableFromInline
        internal let application: Application

        internal init(application: Application, redisID: RedisID) {
            self.application = application
            self.id = redisID
        }

        @usableFromInline
        internal func pool(for eventLoop: EventLoop) throws -> RedisConnectionPool {
            try self.application.redisStorage.pool(for: eventLoop, id: self.id)
        }
    }
}

// MARK: RedisClient
extension Application.Redis: RedisClient {
    public var eventLoop: EventLoop { self.application.eventLoopGroup.next() }
    public var defaultLogger: Logger? { self.application.logger }

    public func logging(to logger: Logger) throws -> RedisClient {
        try self.application.redis(self.id)
            .pool(for: self.eventLoop)
            .logging(to: logger)
    }

    public func send<CommandResult>(
        _ command: RedisCommand<CommandResult>,
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil
    ) -> EventLoopFuture<CommandResult> {
        do {
            return try self.application.redis(self.id)
                .pool(for: self.eventLoop)
                .logging(to: self.application.logger)
                .send(command, eventLoop: eventLoop, logger: logger)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    public func subscribe(
        to channels: [RedisChannelName],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) -> EventLoopFuture<Void> {
        do {
            return try self.application.redis(self.id)
                .pubsubClient()
                .logging(to: self.application.logger)
                .subscribe(to: channels, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    public func unsubscribe(from channels: [RedisChannelName], eventLoop: EventLoop? = nil, logger: Logger? = nil) -> EventLoopFuture<Void> {
        do {
            return try self.application.redis(self.id)
                .pubsubClient()
                .logging(to: self.application.logger)
                .unsubscribe(from: channels, eventLoop: eventLoop, logger: logger)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    public func psubscribe(
        to patterns: [String],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) -> EventLoopFuture<Void> {
        do {
            return try self.application.redis(self.id)
                .pubsubClient()
                .logging(to: self.application.logger)
                .psubscribe(to: patterns, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    public func punsubscribe(from patterns: [String], eventLoop: EventLoop? = nil, logger: Logger? = nil) -> EventLoopFuture<Void> {
        do {
            return try self.application.redis(self.id)
                .pubsubClient()
                .logging(to: self.application.logger)
                .punsubscribe(from: patterns, eventLoop: eventLoop, logger: logger)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}

// MARK: Connection Leasing
extension Application.Redis {
    /// Provides temporary exclusive access to a single Redis client.
    ///
    /// See `RedisConnectionPool.leaseConnection(_:)` for more details.
    @inlinable
    public func withBorrowedConnection<Result>(
        _ operation: @escaping (RedisClient) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<Result> {
        do {
            return try self.application.redis(self.id)
            .pool(for: self.eventLoop)
            .leaseConnection {
                return operation($0.logging(to: self.application.logger))
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}
