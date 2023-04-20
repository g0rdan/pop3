part of 'pop3_client.dart';

enum SessionState {
  /// Once the TCP connection has been opened by a POP3 client, the POP3
  /// server issues a one line greeting.  This can be any positive
  /// response.  An example might be:
  ///
  ///   S:  +OK POP3 server ready
  ///
  /// The POP3 session is now in the AUTHORIZATION state.  The client must
  /// now identify and authenticate itself to the POP3 server.  Two
  /// possible mechanisms for doing this are described in this document,
  /// the USER and PASS command combination and the APOP command.  Both
  /// mechanisms are described later in this document.  Additional
  /// authentication mechanisms are described in [RFC1734](https://www.rfc-editor.org/rfc/rfc1734).
  /// While there is no single authentication mechanism that is required of all
  /// POP3 servers, a POP3 server must of course support at least one
  /// authentication mechanism.
  ///
  /// Once the POP3 server has determined through the use of any
  /// authentication command that the client should be given access to the
  /// appropriate maildrop, the POP3 server then acquires an exclusive-
  /// access lock on the maildrop, as necessary to prevent messages from
  /// being modified or removed before the session enters the UPDATE state.
  /// If the lock is successfully acquired, the POP3 server responds with a
  /// positive status indicator.  The POP3 session now enters the
  /// TRANSACTION state, with no messages marked as deleted.  If the
  /// maildrop cannot be opened for some reason (for example, a lock can
  /// not be acquired, the client is denied access to the appropriate
  /// maildrop, or the maildrop cannot be parsed), the POP3 server responds
  /// with a negative status indicator.  (If a lock was acquired but the
  /// POP3 server intends to respond with a negative status indicator, the
  /// POP3 server must release the lock prior to rejecting the command.)
  /// After returning a negative status indicator, the server may close the
  /// connection.  If the server does not close the connection, the client
  /// may either issue a new authentication command and start again, or the
  /// client may issue the QUIT command.
  ///
  /// After the POP3 server has opened the maildrop, it assigns a message-
  /// number to each message, and notes the size of each message in octets.
  /// The first message in the maildrop is assigned a message-number of
  /// "1", the second is assigned "2", and so on, so that the nth message
  /// in a maildrop is assigned a message-number of "n".  In POP3 commands
  /// and responses, all message-numbers and message sizes are expressed in
  /// base-10 (i.e., decimal).
  authorization,

  /// Once the client has successfully identified itself to the POP3 server
  /// and the POP3 server has locked and opened the appropriate maildrop,
  /// the POP3 session is now in the TRANSACTION state.  The client may now
  /// issue any of the following POP3 commands repeatedly.  After each
  /// command, the POP3 server issues a response.  Eventually, the client
  /// issues the QUIT command and the POP3 session enters the UPDATE state.
  transaction,

  /// When the client issues the QUIT command from the TRANSACTION state,
  /// the POP3 session enters the UPDATE state.  (Note that if the client
  /// issues the QUIT command from the AUTHORIZATION state, the POP3
  /// session terminates but does NOT enter the UPDATE state.)
  ///
  /// If a session terminates for some reason other than a client-issued
  /// QUIT command, the POP3 session does NOT enter the UPDATE state and
  /// MUST not remove any messages from the maildrop.
  update,
}

// https://www.rfc-editor.org/rfc/rfc1939
enum Pop3CommandType {
  /// APOP name digest
  ///
  /// Arguments:
  ///   a string identifying a mailbox and a MD5 digest string
  ///   (both required)
  ///
  /// Restrictions:
  ///   may only be given in the AUTHORIZATION state after the POP3
  ///   greeting or after an unsuccessful USER or PASS command
  ///
  /// Discussion:
  ///   Normally, each POP3 session starts with a USER/PASS
  ///   exchange.  This results in a server/user-id specific
  ///   password being sent in the clear on the network. For
  ///   intermittent use of POP3, this may not introduce a sizable
  ///   risk. However, many POP3 client implementations connect to
  ///   the POP3 server on a regular basis -- to check for new
  ///   mail.  Further the interval of session initiation may be on
  ///   the order of five minutes.  Hence, the risk of password
  ///   capture is greatly enhanced.
  ///
  ///   An alternate method of authentication is required which
  ///   provides for both origin authentication and replay
  ///   protection, but which does not involve sending a password
  ///   in the clear over the network.  The APOP command provides
  ///   this functionality.
  ///
  ///   A POP3 server which implements the APOP command will
  ///   include a timestamp in its banner greeting.  The syntax of
  ///   the timestamp corresponds to the `msg-id' in [RFC822], and
  ///   MUST be different each time the POP3 server issues a banner
  ///   greeting.  For example, on a UNIX implementation in which a
  ///   separate UNIX process is used for each instance of a POP3
  ///   server, the syntax of the timestamp might be:
  ///
  ///     <process-ID.clock@hostname>
  ///
  ///   where `process-ID' is the decimal value of the process's
  ///   PID, clock is the decimal value of the system clock, and
  ///   hostname is the fully-qualified domain-name corresponding
  ///   to the host where the POP3 server is running.
  ///
  ///   The POP3 client makes note of this timestamp, and then
  ///   issues the APOP command.  The `name' parameter has
  ///   identical semantics to the `name' parameter of the USER
  ///   command. The `digest' parameter is calculated by applying
  ///   the MD5 algorithm [RFC1321] to a string consisting of the
  ///   timestamp (including angle-brackets) followed by a shared
  ///   secret.  This shared secret is a string known only to the
  ///   POP3 client and server.  Great care should be taken to
  ///   prevent unauthorized disclosure of the secret, as knowledge
  ///   of the secret will allow any entity to successfully
  ///   masquerade as the named user.  The `digest' parameter
  ///   itself is a 16-octet value which is sent in hexadecimal
  ///   format, using lower-case ASCII characters.
  ///
  ///   When the POP3 server receives the APOP command, it verifies
  ///   the digest provided.  If the digest is correct, the POP3
  ///   server issues a positive response, and the POP3 session
  ///   enters the TRANSACTION state.  Otherwise, a negative
  ///   response is issued and the POP3 session remains in the
  ///   AUTHORIZATION state.
  ///
  ///   Note that as the length of the shared secret increases, so
  ///   does the difficulty of deriving it.  As such, shared
  ///   secrets should be long strings (considerably longer than
  ///   the 8-character example shown below).
  ///
  /// Possible Responses:
  ///   +OK maildrop locked and ready
  ///   -ERR permission denied
  ///
  /// Examples:
  ///   S: +OK POP3 server ready <1896.697170952@dbc.mtview.ca.us>
  ///   C: APOP mrose c4c9334bac560ecc979e58001b3e22fb
  ///   S: +OK maildrop has 1 message (369 octets)
  ///
  ///   In this example, the shared  secret  is  the  string  `tanstaaf'.
  ///   Hence, the MD5 algorithm is applied to the string
  ///   <1896.697170952@dbc.mtview.ca.us>tanstaaf which produces a digest value
  ///   of c4c9334bac560ecc979e58001b3e22fb
  apop(
    sessionState: SessionState.authorization,
    command: 'APOP',
  ),

  /// DELE msg
  ///
  /// Arguments:
  ///   a message-number (required) which may NOT refer to a
  ///   message marked as deleted
  ///
  /// Restrictions:
  ///   may only be given in the TRANSACTION state
  ///
  /// Discussion:
  ///   The POP3 server marks the message as deleted.  Any future
  ///   reference to the message-number associated with the message
  ///   in a POP3 command generates an error.  The POP3 server does
  ///   not actually delete the message until the POP3 session
  ///   enters the UPDATE state.
  ///
  /// Possible Responses:
  ///   +OK message deleted
  ///   -ERR no such message
  ///
  /// Examples:
  ///   C: DELE 1
  ///   S: +OK message 1 deleted
  ///     ...
  ///   C: DELE 2
  ///   S: -ERR message 2 already deleted
  dele(
    sessionState: SessionState.transaction,
    command: 'DELE',
  ),

  /// LIST [msg]
  ///
  /// Arguments:
  ///   a message-number (optional), which, if present, may NOT
  ///   refer to a message marked as deleted
  ///
  /// Restrictions:
  ///   may only be given in the TRANSACTION state
  ///
  /// Discussion:
  ///   If an argument was given and the POP3 server issues a
  ///   positive response with a line containing information for
  ///   that message.  This line is called a "scan listing" for
  ///   that message.
  ///
  ///   If no argument was given and the POP3 server issues a
  ///   positive response, then the response given is multi-line.
  ///   After the initial +OK, for each message in the maildrop,
  ///   the POP3 server responds with a line containing
  ///   information for that message.  This line is also called a
  ///   "scan listing" for that message.  If there are no
  ///   messages in the maildrop, then the POP3 server responds
  ///   with no scan listings--it issues a positive response
  ///   followed by a line containing a termination octet and a
  ///   CRLF pair.
  ///
  ///   In order to simplify parsing, all POP3 servers are
  ///   required to use a certain format for scan listings.  A
  ///   scan listing consists of the message-number of the
  ///   message, followed by a single space and the exact size of
  ///   the message in octets.  Methods for calculating the exact
  ///   size of the message are described in the "Message Format"
  ///   section below.  This memo makes no requirement on what
  ///   follows the message size in the scan listing.  Minimal
  ///   implementations should just end that line of the response
  ///   with a CRLF pair.  More advanced implementations may
  ///   include other information, as parsed from the message.
  ///
  ///   NOTE: This memo STRONGLY discourages implementations
  ///   from supplying additional information in the scan
  ///   listing.  Other, optional, facilities are discussed
  ///   later on which permit the client to parse the messages
  ///   in the maildrop.
  ///
  ///   Note that messages marked as deleted are not listed.
  ///
  /// Possible Responses:
  ///   +OK scan listing follows
  ///   -ERR no such message
  ///
  /// Examples:
  ///   C: LIST
  ///   S: +OK 2 messages (320 octets)
  ///   S: 1 120
  ///   S: 2 200
  ///   S: .
  ///     ...
  ///   C: LIST 2
  ///   S: +OK 2 200
  ///     ...
  ///   C: LIST 3
  ///   S: -ERR no such message, only 2 messages in maildrop
  list(
    sessionState: SessionState.transaction,
    command: 'LIST',
  ),

  /// NOOP
  ///
  /// Arguments: none
  ///
  /// Restrictions: may only be given in the TRANSACTION state
  ///
  /// Discussion:
  ///   The POP3 server does nothing, it merely replies with a positive
  ///   response.
  ///
  /// Possible Responses:
  ///   +OK
  ///
  /// Examples:
  ///   C: NOOP
  ///   S: +OK
  noop(
    sessionState: SessionState.transaction,
    command: 'NOOP',
  ),

  /// PASS string
  ///
  /// Arguments:
  ///   a server/mailbox-specific password (required)
  ///
  /// Restrictions:
  ///   may only be given in the AUTHORIZATION state immediately
  ///   after a successful USER command
  ///
  /// Discussion:
  ///   When the client issues the PASS command, the POP3 server
  ///   uses the argument pair from the USER and PASS commands to
  ///   determine if the client should be given access to the
  ///   appropriate maildrop.
  ///
  ///   Since the PASS command has exactly one argument, a POP3
  ///   server may treat spaces in the argument as part of the
  ///   password, instead of as argument separators.
  ///
  /// Possible Responses:
  ///   +OK maildrop locked and ready
  ///   -ERR invalid password
  ///   -ERR unable to lock maildrop
  ///
  /// Examples:
  ///   C: USER mrose
  ///   S: +OK mrose is a real hoopy frood
  ///   C: PASS secret
  ///   S: -ERR maildrop already locked
  ///     ...
  ///   C: USER mrose
  ///   S: +OK mrose is a real hoopy frood
  ///   C: PASS secret
  ///   S: +OK mrose's maildrop has 2 messages (320 octets)
  pass(
    sessionState: SessionState.authorization,
    command: 'PASS',
  ),

  /// QUIT
  ///
  /// Arguments: none
  ///
  /// Restrictions: none
  ///
  /// Discussion:
  ///   The POP3 server removes all messages marked as deleted
  ///   from the maildrop and replies as to the status of this
  ///   operation.  If there is an error, such as a resource
  ///   shortage, encountered while removing messages, the
  ///   maildrop may result in having some or none of the messages
  ///   marked as deleted be removed.  In no case may the server
  ///   remove any messages not marked as deleted.
  ///
  ///   Whether the removal was successful or not, the server
  ///   then releases any exclusive-access lock on the maildrop
  ///   and closes the TCP connection.
  ///
  /// Possible Responses:
  ///   +OK
  ///   -ERR some deleted messages not removed
  ///
  /// Examples:
  ///   C: QUIT
  ///   S: +OK dewey POP3 server signing off (maildrop empty)
  ///     ...
  ///   C: QUIT
  quit(
    sessionState: SessionState.update,
    command: 'QUIT',
  ),

  /// RETR msg
  ///
  /// Arguments:
  ///   a message-number (required) which may NOT refer to a
  ///   message marked as deleted
  ///
  /// Restrictions:
  ///   may only be given in the TRANSACTION state
  ///
  /// Discussion:
  ///   If the POP3 server issues a positive response, then the
  ///   response given is multi-line.  After the initial +OK, the
  ///   POP3 server sends the message corresponding to the given
  ///   message-number, being careful to byte-stuff the termination
  ///   character (as with all multi-line responses).
  ///
  /// Possible Responses:
  ///   +OK message follows
  ///   -ERR no such message
  ///
  /// Examples:
  ///   C: RETR 1
  ///   S: +OK 120 octets
  ///   S: <the POP3 server sends the entire message here>
  ///   S: .
  retr(
    sessionState: SessionState.transaction,
    command: 'RETR',
  ),

  /// RSET
  ///
  /// Arguments: none
  /// Restrictions: may only be given in the TRANSACTION state
  /// Discussion:
  ///   If any messages have been marked as deleted by the POP3
  ///   server, they are unmarked.  The POP3 server then replies
  ///   with a positive response.
  /// Possible Responses:
  ///   +OK
  /// Examples:
  ///   C: RSET
  ///   S: +OK maildrop has 2 messages (320 octets)
  rset(
    sessionState: SessionState.transaction,
    command: 'RSET',
  ),

  /// STAT
  ///
  /// Arguments: none
  ///
  /// Restrictions:
  ///   may only be given in the TRANSACTION state
  ///
  /// Discussion:
  ///   The POP3 server issues a positive response with a line
  ///   containing information for the maildrop.  This line is
  ///   called a "drop listing" for that maildrop.
  ///
  ///   In order to simplify parsing, all POP3 servers are
  ///   required to use a certain format for drop listings.  The
  ///   positive response consists of "+OK" followed by a single
  ///   space, the number of messages in the maildrop, a single
  ///   space, and the size of the maildrop in octets.  This memo
  ///   makes no requirement on what follows the maildrop size.
  ///   Minimal implementations should just end that line of the
  ///   response with a CRLF pair.  More advanced implementations
  ///   may include other information.
  ///
  ///   NOTE: This memo STRONGLY discourages implementations
  ///   from supplying additional information in the drop
  ///   listing.  Other, optional, facilities are discussed
  ///   later on which permit the client to parse the messages
  ///   in the maildrop.
  ///
  ///   Note that messages marked as deleted are not counted in either total.
  ///
  /// Possible Responses:
  ///   +OK nn mm
  ///
  /// Examples:
  ///   C: STAT
  ///   S: +OK 2 320
  stat(
    sessionState: SessionState.transaction,
    command: 'STAT',
  ),

  /// TOP msg n
  ///
  /// Arguments:
  ///   a message-number (required) which may NOT refer to a
  ///   message marked as deleted, and a non-negative number
  ///   of lines (required)
  ///
  /// Restrictions:
  ///   may only be given in the TRANSACTION state
  ///
  /// Discussion:
  ///   If the POP3 server issues a positive response, then the
  ///   response given is multi-line.  After the initial +OK, the
  ///   POP3 server sends the headers of the message, the blank
  ///   line separating the headers from the body, and then the
  ///   number of lines of the indicated message's body, being
  ///   careful to byte-stuff the termination character (as with
  ///   all multi-line responses).
  ///
  ///   Note that if the number of lines requested by the POP3
  ///   client is greater than than the number of lines in the
  ///   body, then the POP3 server sends the entire message.
  ///
  /// Possible Responses:
  ///   +OK top of message follows
  ///   -ERR no such message
  ///
  /// Examples:
  ///   C: TOP 1 10
  ///   S: +OK
  ///   S: <the POP3 server sends the headers of the
  ///   message, a blank line, and the first 10 lines
  ///   of the body of the message>
  ///   S: .
  ///     ...
  ///   C: TOP 100 3
  ///   S: -ERR no such message
  top(
    sessionState: SessionState.transaction,
    command: 'TOP',
  ),

  /// UIDL [msg]
  ///
  /// Arguments:
  ///   a message-number (optional), which, if present, may NOT
  ///   refer to a message marked as deleted
  ///
  /// Restrictions:
  ///   may only be given in the TRANSACTION state.
  ///
  /// Discussion:
  ///   If an argument was given and the POP3 server issues a positive
  ///   response with a line containing information for that message.
  ///   This line is called a "unique-id listing" for that message.
  ///
  ///   If no argument was given and the POP3 server issues a positive
  ///   response, then the response given is multi-line.  After the
  ///   initial +OK, for each message in the maildrop, the POP3 server
  ///   responds with a line containing information for that message.
  ///   This line is called a "unique-id listing" for that message.
  ///
  ///   In order to simplify parsing, all POP3 servers are required to
  ///   use a certain format for unique-id listings.  A unique-id
  ///   listing consists of the message-number of the message,
  ///   followed by a single space and the unique-id of the message.
  ///   No information follows the unique-id in the unique-id listing.
  ///
  ///   The unique-id of a message is an arbitrary server-determined
  ///   string, consisting of one to 70 characters in the range 0x21
  ///   to 0x7E, which uniquely identifies a message within a
  ///   maildrop and which persists across sessions.  This
  ///   persistence is required even if a session ends without
  ///   entering the UPDATE state.  The server should never reuse an
  ///   unique-id in a given maildrop, for as long as the entity
  ///   using the unique-id exists.
  ///
  ///   Note that messages marked as deleted are not listed.
  ///
  ///   While it is generally preferable for server implementations
  ///   to store arbitrarily assigned unique-ids in the maildrop,
  ///   this specification is intended to permit unique-ids to be
  ///   calculated as a hash of the message.  Clients should be able
  ///   to handle a situation where two identical copies of a
  ///   message in a maildrop have the same unique-id.
  ///
  /// Possible Responses:
  ///   +OK unique-id listing follows
  ///   -ERR no such message
  ///
  /// Examples:
  ///   C: UIDL
  ///   S: +OK
  ///   S: 1 whqtswO00WBw418f9t5JxYwZ
  ///   S: 2 QhdPYR:00WBw1Ph7x7
  ///   S: .
  ///     ...
  ///   C: UIDL 2
  ///   S: +OK 2 QhdPYR:00WBw1Ph7x7
  ///     ...
  ///   C: UIDL 3
  ///   S: -ERR no such message, only 2 messages in maildrop
  uidl(
    sessionState: SessionState.transaction,
    command: 'UIDL',
  ),

  /// USER name
  ///
  /// Arguments:
  ///   a string identifying a mailbox (required), which is of
  ///   significance ONLY to the server
  ///
  /// Restrictions:
  ///   may only be given in the AUTHORIZATION state after the POP3
  ///   greeting or after an unsuccessful USER or PASS command
  ///
  /// Discussion:
  ///   To authenticate using the USER and PASS command
  ///   combination, the client must first issue the USER
  ///   command.  If the POP3 server responds with a positive
  ///   status indicator ("+OK"), then the client may issue
  ///   either the PASS command to complete the authentication,
  ///   or the QUIT command to terminate the POP3 session.  If
  ///   the POP3 server responds with a negative status indicator
  ///   ("-ERR") to the USER command, then the client may either
  ///   issue a new authentication command or may issue the QUIT
  ///   command.
  ///
  ///   The server may return a positive response even though no
  ///   such mailbox exists.  The server may return a negative
  ///   response if mailbox exists, but does not permit plaintext
  ///   password authentication.
  ///
  /// Possible Responses:
  ///   +OK name is a valid mailbox
  ///   -ERR never heard of mailbox name
  ///
  /// Examples:
  ///   C: USER frated
  ///   S: -ERR sorry, no mailbox for frated here
  ///     ...
  ///   C: USER mrose
  ///   S: +OK mrose is a real hoopy frood
  user(
    sessionState: SessionState.authorization,
    command: 'USER',
  );

  final SessionState sessionState;
  final String command;

  // ignore: sort_constructors_first
  const Pop3CommandType({
    required this.sessionState,
    required this.command,
  });

  @override
  String toString() => command;
}

class Pop3Response extends Equatable {
  const Pop3Response({
    required this.data,
    required this.command,
  });
  final String data;
  final Pop3Command<dynamic>? command;

  bool get success => data.startsWith('+OK');
  bool get isError => data.startsWith('-ERR');
  // The very first response from teh server.
  bool get greeting => success && command == null;

  @override
  List<Object?> get props => [
        data,
        command,
      ];
}
