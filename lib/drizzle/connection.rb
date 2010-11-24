require 'drizzle/ffidrizzle'

module Drizzle

  class ConnectionPtr < FFI::AutoPointer
    def self.release(ptr)
      LibDrizzle.drizzle_con_free(ptr)
    end
  end

  class Connection

    attr_accessor :host, :port, :db

    def initialize(host = "localhost", port = 4427, db = nil, opts = [], drizzle_ptr = nil)
      @host = host
      @port = port
      @db = db
      @drizzle_handle = drizzle_ptr || DrizzlePtr.new(LibDrizzle.drizzle_create(nil))
      @con_ptr = ConnectionPtr.new(LibDrizzle.drizzle_con_create(@drizzle_handle, nil))
      opts.each do |opt|
        LibDrizzle.drizzle_con_add_options(@con_ptr, LibDrizzle::ConnectionOptions[opt])
      end
      LibDrizzle.drizzle_con_set_tcp(@con_ptr, @host, @port) 
      LibDrizzle.drizzle_con_set_db(@con_ptr, @db) if @db
      @ret_ptr = FFI::MemoryPointer.new(:int)
    end

    def set_tcp(host, port)
      @host = host
      @port = port
      LibDrizzle.drizzle_con_set_tcp(@con_ptr, @host, @port)
    end

    def set_db(db_name)
      @db = db_name
      LibDrizzle.drizzle_con_set_db(@con_ptr, @db)
    end

    def query(query)
      res = LibDrizzle.drizzle_query_str(@con_ptr, nil, query, @ret_ptr)
      check_return_code
      Result.new(res)
    end

    def check_return_code
      case LibDrizzle::ReturnCode[@ret_ptr.get_int(0)]
      when :DRIZZLE_RETURN_IO_WAIT
        raise IoWait.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_PAUSE
        raise Pause.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_ROW_BREAK
        raise RowBreak.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_MEMORY
        raise Memory.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_INTERNAL_ERROR
        raise InternalError.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_NOT_READY
        raise NotReady.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_BAD_PACKET_NUMBER
        raise BadPacketNumber.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_BAD_HANDSHAKE_PACKET
        raise BadHandshake.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_BAD_PACKET
        raise BadPacket.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_PROTOCOL_NOT_SUPPORTED
        raise ProtocolNotSupported.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_UNEXPECTED_DATA
        raise UnexpectedData.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_NO_SCRAMBLE
        raise NoScramble.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_AUTH_FAILED
        raise AuthFailed.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_NULL_SIZE
        raise NullSize.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_TOO_MANY_COLUMNS
        raise TooManyColumns.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_ROW_END
        raise RowEnd.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_LOST_CONNECTION
        raise LostConnection.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_COULD_NOT_CONNECT
        raise CouldNotConnect.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_NO_ACTIVE_CONNECTIONS
        raise NoActiveConnections.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_HANDSHAKE_FAILED
        raise HandshakeFailed.new(LibDrizzle.drizzle_error(@drizzle_handle))
      when :DRIZZLE_RETURN_TIMEOUT
        raise ReturnTimeout.new(LibDrizzle.drizzle_error(@drizzle_handle))
      end
    end

  end

end
