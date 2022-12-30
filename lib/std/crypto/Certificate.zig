buffer: []const u8,
index: u32,

pub const Bundle = @import("Certificate/Bundle.zig");

pub const Algorithm = enum {
    sha1WithRSAEncryption,
    sha224WithRSAEncryption,
    sha256WithRSAEncryption,
    sha384WithRSAEncryption,
    sha512WithRSAEncryption,
    ecdsa_with_SHA224,
    ecdsa_with_SHA256,
    ecdsa_with_SHA384,
    ecdsa_with_SHA512,

    pub const map = std.ComptimeStringMap(Algorithm, .{
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x05 }, .sha1WithRSAEncryption },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B }, .sha256WithRSAEncryption },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0C }, .sha384WithRSAEncryption },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0D }, .sha512WithRSAEncryption },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0E }, .sha224WithRSAEncryption },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x01 }, .ecdsa_with_SHA224 },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x02 }, .ecdsa_with_SHA256 },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x03 }, .ecdsa_with_SHA384 },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x04 }, .ecdsa_with_SHA512 },
    });

    pub fn Hash(comptime algorithm: Algorithm) type {
        return switch (algorithm) {
            .sha1WithRSAEncryption => crypto.hash.Sha1,
            .ecdsa_with_SHA224, .sha224WithRSAEncryption => crypto.hash.sha2.Sha224,
            .ecdsa_with_SHA256, .sha256WithRSAEncryption => crypto.hash.sha2.Sha256,
            .ecdsa_with_SHA384, .sha384WithRSAEncryption => crypto.hash.sha2.Sha384,
            .ecdsa_with_SHA512, .sha512WithRSAEncryption => crypto.hash.sha2.Sha512,
        };
    }
};

pub const AlgorithmCategory = enum {
    rsaEncryption,
    X9_62_id_ecPublicKey,

    pub const map = std.ComptimeStringMap(AlgorithmCategory, .{
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01 }, .rsaEncryption },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01 }, .X9_62_id_ecPublicKey },
    });
};

pub const Attribute = enum {
    commonName,
    serialNumber,
    countryName,
    localityName,
    stateOrProvinceName,
    organizationName,
    organizationalUnitName,
    organizationIdentifier,
    pkcs9_emailAddress,

    pub const map = std.ComptimeStringMap(Attribute, .{
        .{ &[_]u8{ 0x55, 0x04, 0x03 }, .commonName },
        .{ &[_]u8{ 0x55, 0x04, 0x05 }, .serialNumber },
        .{ &[_]u8{ 0x55, 0x04, 0x06 }, .countryName },
        .{ &[_]u8{ 0x55, 0x04, 0x07 }, .localityName },
        .{ &[_]u8{ 0x55, 0x04, 0x08 }, .stateOrProvinceName },
        .{ &[_]u8{ 0x55, 0x04, 0x0A }, .organizationName },
        .{ &[_]u8{ 0x55, 0x04, 0x0B }, .organizationalUnitName },
        .{ &[_]u8{ 0x55, 0x04, 0x61 }, .organizationIdentifier },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x01 }, .pkcs9_emailAddress },
    });
};

pub const NamedCurve = enum {
    secp384r1,
    X9_62_prime256v1,

    pub const map = std.ComptimeStringMap(NamedCurve, .{
        .{ &[_]u8{ 0x2B, 0x81, 0x04, 0x00, 0x22 }, .secp384r1 },
        .{ &[_]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07 }, .X9_62_prime256v1 },
    });
};

pub const Parsed = struct {
    certificate: Certificate,
    issuer_slice: Slice,
    subject_slice: Slice,
    common_name_slice: Slice,
    signature_slice: Slice,
    signature_algorithm: Algorithm,
    pub_key_algo: PubKeyAlgo,
    pub_key_slice: Slice,
    message_slice: Slice,
    validity: Validity,

    pub const PubKeyAlgo = union(AlgorithmCategory) {
        rsaEncryption: void,
        X9_62_id_ecPublicKey: NamedCurve,
    };

    pub const Validity = struct {
        not_before: u64,
        not_after: u64,
    };

    pub const Slice = der.Element.Slice;

    pub fn slice(p: Parsed, s: Slice) []const u8 {
        return p.certificate.buffer[s.start..s.end];
    }

    pub fn issuer(p: Parsed) []const u8 {
        return p.slice(p.issuer_slice);
    }

    pub fn subject(p: Parsed) []const u8 {
        return p.slice(p.subject_slice);
    }

    pub fn commonName(p: Parsed) []const u8 {
        return p.slice(p.common_name_slice);
    }

    pub fn signature(p: Parsed) []const u8 {
        return p.slice(p.signature_slice);
    }

    pub fn pubKey(p: Parsed) []const u8 {
        return p.slice(p.pub_key_slice);
    }

    pub fn pubKeySigAlgo(p: Parsed) []const u8 {
        return p.slice(p.pub_key_signature_algorithm_slice);
    }

    pub fn message(p: Parsed) []const u8 {
        return p.slice(p.message_slice);
    }

    pub const VerifyError = error{
        CertificateIssuerMismatch,
        CertificateNotYetValid,
        CertificateExpired,
        CertificateSignatureAlgorithmUnsupported,
        CertificateSignatureAlgorithmMismatch,
        CertificateFieldHasInvalidLength,
        CertificateFieldHasWrongDataType,
        CertificatePublicKeyInvalid,
        CertificateSignatureInvalidLength,
        CertificateSignatureInvalid,
        CertificateSignatureUnsupportedBitCount,
        CertificateSignatureNamedCurveUnsupported,
    };

    /// This function checks the time validity for the subject only. Checking
    /// the issuer's time validity is out of scope.
    pub fn verify(parsed_subject: Parsed, parsed_issuer: Parsed) VerifyError!void {
        // Check that the subject's issuer name matches the issuer's
        // subject name.
        if (!mem.eql(u8, parsed_subject.issuer(), parsed_issuer.subject())) {
            return error.CertificateIssuerMismatch;
        }

        const now_sec = std.time.timestamp();
        if (now_sec < parsed_subject.validity.not_before)
            return error.CertificateNotYetValid;
        if (now_sec > parsed_subject.validity.not_after)
            return error.CertificateExpired;

        switch (parsed_subject.signature_algorithm) {
            inline .sha1WithRSAEncryption,
            .sha224WithRSAEncryption,
            .sha256WithRSAEncryption,
            .sha384WithRSAEncryption,
            .sha512WithRSAEncryption,
            => |algorithm| return verifyRsa(
                algorithm.Hash(),
                parsed_subject.message(),
                parsed_subject.signature(),
                parsed_issuer.pub_key_algo,
                parsed_issuer.pubKey(),
            ),

            inline .ecdsa_with_SHA224,
            .ecdsa_with_SHA256,
            .ecdsa_with_SHA384,
            .ecdsa_with_SHA512,
            => |algorithm| return verify_ecdsa(
                algorithm.Hash(),
                parsed_subject.message(),
                parsed_subject.signature(),
                parsed_issuer.pub_key_algo,
                parsed_issuer.pubKey(),
            ),
        }
    }
};

pub fn parse(cert: Certificate) !Parsed {
    const cert_bytes = cert.buffer;
    const certificate = try der.Element.parse(cert_bytes, cert.index);
    const tbs_certificate = try der.Element.parse(cert_bytes, certificate.slice.start);
    const version = try der.Element.parse(cert_bytes, tbs_certificate.slice.start);
    try checkVersion(cert_bytes, version);
    const serial_number = try der.Element.parse(cert_bytes, version.slice.end);
    // RFC 5280, section 4.1.2.3:
    // "This field MUST contain the same algorithm identifier as
    // the signatureAlgorithm field in the sequence Certificate."
    const tbs_signature = try der.Element.parse(cert_bytes, serial_number.slice.end);
    const issuer = try der.Element.parse(cert_bytes, tbs_signature.slice.end);
    const validity = try der.Element.parse(cert_bytes, issuer.slice.end);
    const not_before = try der.Element.parse(cert_bytes, validity.slice.start);
    const not_before_utc = try parseTime(cert, not_before);
    const not_after = try der.Element.parse(cert_bytes, not_before.slice.end);
    const not_after_utc = try parseTime(cert, not_after);
    const subject = try der.Element.parse(cert_bytes, validity.slice.end);

    const pub_key_info = try der.Element.parse(cert_bytes, subject.slice.end);
    const pub_key_signature_algorithm = try der.Element.parse(cert_bytes, pub_key_info.slice.start);
    const pub_key_algo_elem = try der.Element.parse(cert_bytes, pub_key_signature_algorithm.slice.start);
    const pub_key_algo_tag = try parseAlgorithmCategory(cert_bytes, pub_key_algo_elem);
    var pub_key_algo: Parsed.PubKeyAlgo = undefined;
    switch (pub_key_algo_tag) {
        .rsaEncryption => {
            pub_key_algo = .{ .rsaEncryption = {} };
        },
        .X9_62_id_ecPublicKey => {
            // RFC 5480 Section 2.1.1.1 Named Curve
            // ECParameters ::= CHOICE {
            //   namedCurve         OBJECT IDENTIFIER
            //   -- implicitCurve   NULL
            //   -- specifiedCurve  SpecifiedECDomain
            // }
            const params_elem = try der.Element.parse(cert_bytes, pub_key_algo_elem.slice.end);
            const named_curve = try parseNamedCurve(cert_bytes, params_elem);
            pub_key_algo = .{ .X9_62_id_ecPublicKey = named_curve };
        },
    }
    const pub_key_elem = try der.Element.parse(cert_bytes, pub_key_signature_algorithm.slice.end);
    const pub_key = try parseBitString(cert, pub_key_elem);

    var common_name = der.Element.Slice.empty;
    var name_i = subject.slice.start;
    while (name_i < subject.slice.end) {
        const rdn = try der.Element.parse(cert_bytes, name_i);
        var rdn_i = rdn.slice.start;
        while (rdn_i < rdn.slice.end) {
            const atav = try der.Element.parse(cert_bytes, rdn_i);
            var atav_i = atav.slice.start;
            while (atav_i < atav.slice.end) {
                const ty_elem = try der.Element.parse(cert_bytes, atav_i);
                const ty = try parseAttribute(cert_bytes, ty_elem);
                const val = try der.Element.parse(cert_bytes, ty_elem.slice.end);
                switch (ty) {
                    .commonName => common_name = val.slice,
                    else => {},
                }
                atav_i = val.slice.end;
            }
            rdn_i = atav.slice.end;
        }
        name_i = rdn.slice.end;
    }

    const sig_algo = try der.Element.parse(cert_bytes, tbs_certificate.slice.end);
    const algo_elem = try der.Element.parse(cert_bytes, sig_algo.slice.start);
    const signature_algorithm = try parseAlgorithm(cert_bytes, algo_elem);
    const sig_elem = try der.Element.parse(cert_bytes, sig_algo.slice.end);
    const signature = try parseBitString(cert, sig_elem);

    return .{
        .certificate = cert,
        .common_name_slice = common_name,
        .issuer_slice = issuer.slice,
        .subject_slice = subject.slice,
        .signature_slice = signature,
        .signature_algorithm = signature_algorithm,
        .message_slice = .{ .start = certificate.slice.start, .end = tbs_certificate.slice.end },
        .pub_key_algo = pub_key_algo,
        .pub_key_slice = pub_key,
        .validity = .{
            .not_before = not_before_utc,
            .not_after = not_after_utc,
        },
    };
}

pub fn verify(subject: Certificate, issuer: Certificate) !void {
    const parsed_subject = try subject.parse();
    const parsed_issuer = try issuer.parse();
    return parsed_subject.verify(parsed_issuer);
}

pub fn contents(cert: Certificate, elem: der.Element) []const u8 {
    return cert.buffer[elem.slice.start..elem.slice.end];
}

pub fn parseBitString(cert: Certificate, elem: der.Element) !der.Element.Slice {
    if (elem.identifier.tag != .bitstring) return error.CertificateFieldHasWrongDataType;
    if (cert.buffer[elem.slice.start] != 0) return error.CertificateHasInvalidBitString;
    return .{ .start = elem.slice.start + 1, .end = elem.slice.end };
}

/// Returns number of seconds since epoch.
pub fn parseTime(cert: Certificate, elem: der.Element) !u64 {
    const bytes = cert.contents(elem);
    switch (elem.identifier.tag) {
        .utc_time => {
            // Example: "YYMMDD000000Z"
            if (bytes.len != 13)
                return error.CertificateTimeInvalid;
            if (bytes[12] != 'Z')
                return error.CertificateTimeInvalid;

            return Date.toSeconds(.{
                .year = @as(u16, 2000) + try parseTimeDigits(bytes[0..2].*, 0, 99),
                .month = try parseTimeDigits(bytes[2..4].*, 1, 12),
                .day = try parseTimeDigits(bytes[4..6].*, 1, 31),
                .hour = try parseTimeDigits(bytes[6..8].*, 0, 23),
                .minute = try parseTimeDigits(bytes[8..10].*, 0, 59),
                .second = try parseTimeDigits(bytes[10..12].*, 0, 59),
            });
        },
        .generalized_time => {
            // Examples:
            // "19920521000000Z"
            // "19920622123421Z"
            // "19920722132100.3Z"
            if (bytes.len < 15)
                return error.CertificateTimeInvalid;
            return Date.toSeconds(.{
                .year = try parseYear4(bytes[0..4]),
                .month = try parseTimeDigits(bytes[4..6].*, 1, 12),
                .day = try parseTimeDigits(bytes[6..8].*, 1, 31),
                .hour = try parseTimeDigits(bytes[8..10].*, 0, 23),
                .minute = try parseTimeDigits(bytes[10..12].*, 0, 59),
                .second = try parseTimeDigits(bytes[12..14].*, 0, 59),
            });
        },
        else => return error.CertificateFieldHasWrongDataType,
    }
}

const Date = struct {
    /// example: 1999
    year: u16,
    /// range: 1 to 12
    month: u8,
    /// range: 1 to 31
    day: u8,
    /// range: 0 to 59
    hour: u8,
    /// range: 0 to 59
    minute: u8,
    /// range: 0 to 59
    second: u8,

    /// Convert to number of seconds since epoch.
    pub fn toSeconds(date: Date) u64 {
        var sec: u64 = 0;

        {
            var year: u16 = 1970;
            while (year < date.year) : (year += 1) {
                const days: u64 = std.time.epoch.getDaysInYear(year);
                sec += days * std.time.epoch.secs_per_day;
            }
        }

        {
            const is_leap = std.time.epoch.isLeapYear(date.year);
            var month: u4 = 1;
            while (month < date.month) : (month += 1) {
                const days: u64 = std.time.epoch.getDaysInMonth(
                    @intToEnum(std.time.epoch.YearLeapKind, @boolToInt(is_leap)),
                    @intToEnum(std.time.epoch.Month, month),
                );
                sec += days * std.time.epoch.secs_per_day;
            }
        }

        sec += (date.day - 1) * @as(u64, std.time.epoch.secs_per_day);
        sec += date.hour * @as(u64, 60 * 60);
        sec += date.minute * @as(u64, 60);
        sec += date.second;

        return sec;
    }
};

pub fn parseTimeDigits(nn: @Vector(2, u8), min: u8, max: u8) !u8 {
    const zero: @Vector(2, u8) = .{ '0', '0' };
    const mm: @Vector(2, u8) = .{ 10, 1 };
    const result = @reduce(.Add, (nn -% zero) *% mm);
    if (result < min) return error.CertificateTimeInvalid;
    if (result > max) return error.CertificateTimeInvalid;
    return result;
}

test parseTimeDigits {
    const expectEqual = std.testing.expectEqual;
    try expectEqual(@as(u8, 0), try parseTimeDigits("00".*, 0, 99));
    try expectEqual(@as(u8, 99), try parseTimeDigits("99".*, 0, 99));
    try expectEqual(@as(u8, 42), try parseTimeDigits("42".*, 0, 99));

    const expectError = std.testing.expectError;
    try expectError(error.CertificateTimeInvalid, parseTimeDigits("13".*, 1, 12));
    try expectError(error.CertificateTimeInvalid, parseTimeDigits("00".*, 1, 12));
}

pub fn parseYear4(text: *const [4]u8) !u16 {
    const nnnn: @Vector(4, u16) = .{ text[0], text[1], text[2], text[3] };
    const zero: @Vector(4, u16) = .{ '0', '0', '0', '0' };
    const mmmm: @Vector(4, u16) = .{ 1000, 100, 10, 1 };
    const result = @reduce(.Add, (nnnn -% zero) *% mmmm);
    if (result > 9999) return error.CertificateTimeInvalid;
    return result;
}

test parseYear4 {
    const expectEqual = std.testing.expectEqual;
    try expectEqual(@as(u16, 0), try parseYear4("0000"));
    try expectEqual(@as(u16, 9999), try parseYear4("9999"));
    try expectEqual(@as(u16, 1988), try parseYear4("1988"));

    const expectError = std.testing.expectError;
    try expectError(error.CertificateTimeInvalid, parseYear4("999b"));
    try expectError(error.CertificateTimeInvalid, parseYear4("crap"));
}

pub fn parseAlgorithm(bytes: []const u8, element: der.Element) !Algorithm {
    return parseEnum(Algorithm, bytes, element);
}

pub fn parseAlgorithmCategory(bytes: []const u8, element: der.Element) !AlgorithmCategory {
    return parseEnum(AlgorithmCategory, bytes, element);
}

pub fn parseAttribute(bytes: []const u8, element: der.Element) !Attribute {
    return parseEnum(Attribute, bytes, element);
}

pub fn parseNamedCurve(bytes: []const u8, element: der.Element) !NamedCurve {
    return parseEnum(NamedCurve, bytes, element);
}

fn parseEnum(comptime E: type, bytes: []const u8, element: der.Element) !E {
    if (element.identifier.tag != .object_identifier)
        return error.CertificateFieldHasWrongDataType;
    const oid_bytes = bytes[element.slice.start..element.slice.end];
    return E.map.get(oid_bytes) orelse return error.CertificateHasUnrecognizedObjectId;
}

pub fn checkVersion(bytes: []const u8, version: der.Element) !void {
    if (@bitCast(u8, version.identifier) != 0xa0 or
        !mem.eql(u8, bytes[version.slice.start..version.slice.end], "\x02\x01\x02"))
    {
        return error.UnsupportedCertificateVersion;
    }
}

fn verifyRsa(
    comptime Hash: type,
    message: []const u8,
    sig: []const u8,
    pub_key_algo: Parsed.PubKeyAlgo,
    pub_key: []const u8,
) !void {
    if (pub_key_algo != .rsaEncryption) return error.CertificateSignatureAlgorithmMismatch;
    const pk_components = try rsa.PublicKey.parseDer(pub_key);
    const exponent = pk_components.exponent;
    const modulus = pk_components.modulus;
    if (exponent.len > modulus.len) return error.CertificatePublicKeyInvalid;
    if (sig.len != modulus.len) return error.CertificateSignatureInvalidLength;

    const hash_der = switch (Hash) {
        crypto.hash.Sha1 => [_]u8{
            0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e,
            0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14,
        },
        crypto.hash.sha2.Sha224 => [_]u8{
            0x30, 0x2d, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
            0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x04, 0x05,
            0x00, 0x04, 0x1c,
        },
        crypto.hash.sha2.Sha256 => [_]u8{
            0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
            0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05,
            0x00, 0x04, 0x20,
        },
        crypto.hash.sha2.Sha384 => [_]u8{
            0x30, 0x41, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
            0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x02, 0x05,
            0x00, 0x04, 0x30,
        },
        crypto.hash.sha2.Sha512 => [_]u8{
            0x30, 0x51, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
            0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03, 0x05,
            0x00, 0x04, 0x40,
        },
        else => @compileError("unreachable"),
    };

    var msg_hashed: [Hash.digest_length]u8 = undefined;
    Hash.hash(message, &msg_hashed, .{});

    var rsa_mem_buf: [512 * 32]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&rsa_mem_buf);
    const ally = fba.allocator();

    switch (modulus.len) {
        inline 128, 256, 512 => |modulus_len| {
            const ps_len = modulus_len - (hash_der.len + msg_hashed.len) - 3;
            const em: [modulus_len]u8 =
                [2]u8{ 0, 1 } ++
                ([1]u8{0xff} ** ps_len) ++
                [1]u8{0} ++
                hash_der ++
                msg_hashed;

            const public_key = rsa.PublicKey.fromBytes(exponent, modulus, ally) catch |err| switch (err) {
                error.OutOfMemory => unreachable, // rsa_mem_buf is big enough
            };
            const em_dec = rsa.encrypt(modulus_len, sig[0..modulus_len].*, public_key, ally) catch |err| switch (err) {
                error.OutOfMemory => unreachable, // rsa_mem_buf is big enough

                error.MessageTooLong => unreachable,
                error.NegativeIntoUnsigned => @panic("TODO make RSA not emit this error"),
                error.TargetTooSmall => @panic("TODO make RSA not emit this error"),
                error.BufferTooSmall => @panic("TODO make RSA not emit this error"),
            };

            if (!mem.eql(u8, &em, &em_dec)) {
                return error.CertificateSignatureInvalid;
            }
        },
        else => {
            return error.CertificateSignatureUnsupportedBitCount;
        },
    }
}

fn verify_ecdsa(
    comptime Hash: type,
    message: []const u8,
    encoded_sig: []const u8,
    pub_key_algo: Parsed.PubKeyAlgo,
    sec1_pub_key: []const u8,
) !void {
    const sig_named_curve = switch (pub_key_algo) {
        .X9_62_id_ecPublicKey => |named_curve| named_curve,
        else => return error.CertificateSignatureAlgorithmMismatch,
    };

    switch (sig_named_curve) {
        .secp384r1 => {
            const P = crypto.ecc.P384;
            const Ecdsa = crypto.sign.ecdsa.Ecdsa(P, Hash);
            const sig = Ecdsa.Signature.fromDer(encoded_sig) catch |err| switch (err) {
                error.InvalidEncoding => return error.CertificateSignatureInvalid,
            };
            const pub_key = Ecdsa.PublicKey.fromSec1(sec1_pub_key) catch |err| switch (err) {
                error.InvalidEncoding => return error.CertificateSignatureInvalid,
                error.NonCanonical => return error.CertificateSignatureInvalid,
                error.NotSquare => return error.CertificateSignatureInvalid,
            };
            sig.verify(message, pub_key) catch |err| switch (err) {
                error.IdentityElement => return error.CertificateSignatureInvalid,
                error.NonCanonical => return error.CertificateSignatureInvalid,
                error.SignatureVerificationFailed => return error.CertificateSignatureInvalid,
            };
        },
        .X9_62_prime256v1 => {
            return error.CertificateSignatureNamedCurveUnsupported;
        },
    }
}

const std = @import("../std.zig");
const crypto = std.crypto;
const mem = std.mem;
const Certificate = @This();

pub const der = struct {
    pub const Class = enum(u2) {
        universal,
        application,
        context_specific,
        private,
    };

    pub const PC = enum(u1) {
        primitive,
        constructed,
    };

    pub const Identifier = packed struct(u8) {
        tag: Tag,
        pc: PC,
        class: Class,
    };

    pub const Tag = enum(u5) {
        boolean = 1,
        integer = 2,
        bitstring = 3,
        null = 5,
        object_identifier = 6,
        sequence = 16,
        sequence_of = 17,
        utc_time = 23,
        generalized_time = 24,
        _,
    };

    pub const Element = struct {
        identifier: Identifier,
        slice: Slice,

        pub const Slice = struct {
            start: u32,
            end: u32,

            pub const empty: Slice = .{ .start = 0, .end = 0 };
        };

        pub const ParseError = error{CertificateFieldHasInvalidLength};

        pub fn parse(bytes: []const u8, index: u32) ParseError!Element {
            var i = index;
            const identifier = @bitCast(Identifier, bytes[i]);
            i += 1;
            const size_byte = bytes[i];
            i += 1;
            if ((size_byte >> 7) == 0) {
                return .{
                    .identifier = identifier,
                    .slice = .{
                        .start = i,
                        .end = i + size_byte,
                    },
                };
            }

            const len_size = @truncate(u7, size_byte);
            if (len_size > @sizeOf(u32)) {
                return error.CertificateFieldHasInvalidLength;
            }

            const end_i = i + len_size;
            var long_form_size: u32 = 0;
            while (i < end_i) : (i += 1) {
                long_form_size = (long_form_size << 8) | bytes[i];
            }

            return .{
                .identifier = identifier,
                .slice = .{
                    .start = i,
                    .end = i + long_form_size,
                },
            };
        }
    };
};

test {
    _ = Bundle;
}

/// TODO: replace this with Frank's upcoming RSA implementation. the verify
/// function won't have the possibility of failure - it will either identify a
/// valid signature or an invalid signature.
/// This code is borrowed from https://github.com/shiguredo/tls13-zig
/// which is licensed under the Apache License Version 2.0, January 2004
/// http://www.apache.org/licenses/
/// The code has been modified.
pub const rsa = struct {
    const BigInt = std.math.big.int.Managed;

    pub const PSSSignature = struct {
        pub fn fromBytes(comptime modulus_len: usize, msg: []const u8) [modulus_len]u8 {
            var result = [1]u8{0} ** modulus_len;
            std.mem.copy(u8, &result, msg);
            return result;
        }

        pub fn verify(comptime modulus_len: usize, sig: [modulus_len]u8, msg: []const u8, public_key: PublicKey, comptime Hash: type, allocator: std.mem.Allocator) !void {
            const mod_bits = try countBits(public_key.n.toConst(), allocator);
            const em_dec = try encrypt(modulus_len, sig, public_key, allocator);

            try EMSA_PSS_VERIFY(msg, &em_dec, mod_bits - 1, Hash.digest_length, Hash, allocator);
        }

        fn EMSA_PSS_VERIFY(msg: []const u8, em: []const u8, emBit: usize, sLen: usize, comptime Hash: type, allocator: std.mem.Allocator) !void {
            // TODO
            // 1.   If the length of M is greater than the input limitation for
            //      the hash function (2^61 - 1 octets for SHA-1), output
            //      "inconsistent" and stop.

            // emLen = \ceil(emBits/8)
            const emLen = ((emBit - 1) / 8) + 1;
            std.debug.assert(emLen == em.len);

            // 2.   Let mHash = Hash(M), an octet string of length hLen.
            var mHash: [Hash.digest_length]u8 = undefined;
            Hash.hash(msg, &mHash, .{});

            // 3.   If emLen < hLen + sLen + 2, output "inconsistent" and stop.
            if (emLen < Hash.digest_length + sLen + 2) {
                return error.InvalidSignature;
            }

            // 4.   If the rightmost octet of EM does not have hexadecimal value
            //      0xbc, output "inconsistent" and stop.
            if (em[em.len - 1] != 0xbc) {
                return error.InvalidSignature;
            }

            // 5.   Let maskedDB be the leftmost emLen - hLen - 1 octets of EM,
            //      and let H be the next hLen octets.
            const maskedDB = em[0..(emLen - Hash.digest_length - 1)];
            const h = em[(emLen - Hash.digest_length - 1)..(emLen - 1)];

            // 6.   If the leftmost 8emLen - emBits bits of the leftmost octet in
            //      maskedDB are not all equal to zero, output "inconsistent" and
            //      stop.
            const zero_bits = emLen * 8 - emBit;
            var mask: u8 = maskedDB[0];
            var i: usize = 0;
            while (i < 8 - zero_bits) : (i += 1) {
                mask = mask >> 1;
            }
            if (mask != 0) {
                return error.InvalidSignature;
            }

            // 7.   Let dbMask = MGF(H, emLen - hLen - 1).
            const mgf_len = emLen - Hash.digest_length - 1;
            var mgf_out = try allocator.alloc(u8, ((mgf_len - 1) / Hash.digest_length + 1) * Hash.digest_length);
            defer allocator.free(mgf_out);
            var dbMask = try MGF1(mgf_out, h, mgf_len, Hash, allocator);

            // 8.   Let DB = maskedDB \xor dbMask.
            i = 0;
            while (i < dbMask.len) : (i += 1) {
                dbMask[i] = maskedDB[i] ^ dbMask[i];
            }

            // 9.   Set the leftmost 8emLen - emBits bits of the leftmost octet
            //      in DB to zero.
            i = 0;
            mask = 0;
            while (i < 8 - zero_bits) : (i += 1) {
                mask = mask << 1;
                mask += 1;
            }
            dbMask[0] = dbMask[0] & mask;

            // 10.  If the emLen - hLen - sLen - 2 leftmost octets of DB are not
            //      zero or if the octet at position emLen - hLen - sLen - 1 (the
            //      leftmost position is "position 1") does not have hexadecimal
            //      value 0x01, output "inconsistent" and stop.
            if (dbMask[mgf_len - sLen - 2] != 0x00) {
                return error.InvalidSignature;
            }

            if (dbMask[mgf_len - sLen - 1] != 0x01) {
                return error.InvalidSignature;
            }

            // 11.  Let salt be the last sLen octets of DB.
            const salt = dbMask[(mgf_len - sLen)..];

            // 12.  Let
            //         M' = (0x)00 00 00 00 00 00 00 00 || mHash || salt ;
            //      M' is an octet string of length 8 + hLen + sLen with eight
            //      initial zero octets.
            var m_p = try allocator.alloc(u8, 8 + Hash.digest_length + sLen);
            defer allocator.free(m_p);
            std.mem.copy(u8, m_p, &([_]u8{0} ** 8));
            std.mem.copy(u8, m_p[8..], &mHash);
            std.mem.copy(u8, m_p[(8 + Hash.digest_length)..], salt);

            // 13.  Let H' = Hash(M'), an octet string of length hLen.
            var h_p: [Hash.digest_length]u8 = undefined;
            Hash.hash(m_p, &h_p, .{});

            // 14.  If H = H', output "consistent".  Otherwise, output
            //      "inconsistent".
            if (!std.mem.eql(u8, h, &h_p)) {
                return error.InvalidSignature;
            }
        }

        fn MGF1(out: []u8, seed: []const u8, len: usize, comptime Hash: type, allocator: std.mem.Allocator) ![]u8 {
            var counter: usize = 0;
            var idx: usize = 0;
            var c: [4]u8 = undefined;

            var hash = try allocator.alloc(u8, seed.len + c.len);
            defer allocator.free(hash);
            std.mem.copy(u8, hash, seed);
            var hashed: [Hash.digest_length]u8 = undefined;

            while (idx < len) {
                c[0] = @intCast(u8, (counter >> 24) & 0xFF);
                c[1] = @intCast(u8, (counter >> 16) & 0xFF);
                c[2] = @intCast(u8, (counter >> 8) & 0xFF);
                c[3] = @intCast(u8, counter & 0xFF);

                std.mem.copy(u8, hash[seed.len..], &c);
                Hash.hash(hash, &hashed, .{});

                std.mem.copy(u8, out[idx..], &hashed);
                idx += hashed.len;

                counter += 1;
            }

            return out[0..len];
        }
    };

    pub const PublicKey = struct {
        n: BigInt,
        e: BigInt,

        pub fn deinit(self: *PublicKey) void {
            self.n.deinit();
            self.e.deinit();
        }

        pub fn fromBytes(pub_bytes: []const u8, modulus_bytes: []const u8, allocator: std.mem.Allocator) !PublicKey {
            var _n = try BigInt.init(allocator);
            errdefer _n.deinit();
            try setBytes(&_n, modulus_bytes, allocator);

            var _e = try BigInt.init(allocator);
            errdefer _e.deinit();
            try setBytes(&_e, pub_bytes, allocator);

            return .{
                .n = _n,
                .e = _e,
            };
        }

        pub fn parseDer(pub_key: []const u8) !struct { modulus: []const u8, exponent: []const u8 } {
            const pub_key_seq = try der.Element.parse(pub_key, 0);
            if (pub_key_seq.identifier.tag != .sequence) return error.CertificateFieldHasWrongDataType;
            const modulus_elem = try der.Element.parse(pub_key, pub_key_seq.slice.start);
            if (modulus_elem.identifier.tag != .integer) return error.CertificateFieldHasWrongDataType;
            const exponent_elem = try der.Element.parse(pub_key, modulus_elem.slice.end);
            if (exponent_elem.identifier.tag != .integer) return error.CertificateFieldHasWrongDataType;
            // Skip over meaningless zeroes in the modulus.
            const modulus_raw = pub_key[modulus_elem.slice.start..modulus_elem.slice.end];
            const modulus_offset = for (modulus_raw) |byte, i| {
                if (byte != 0) break i;
            } else modulus_raw.len;
            return .{
                .modulus = modulus_raw[modulus_offset..],
                .exponent = pub_key[exponent_elem.slice.start..exponent_elem.slice.end],
            };
        }
    };

    fn encrypt(comptime modulus_len: usize, msg: [modulus_len]u8, public_key: PublicKey, allocator: std.mem.Allocator) ![modulus_len]u8 {
        var m = try BigInt.init(allocator);
        defer m.deinit();

        try setBytes(&m, &msg, allocator);

        if (m.order(public_key.n) != .lt) {
            return error.MessageTooLong;
        }

        var e = try BigInt.init(allocator);
        defer e.deinit();

        try pow_montgomery(&e, &m, &public_key.e, &public_key.n, allocator);

        var res: [modulus_len]u8 = undefined;

        try toBytes(&res, &e, allocator);

        return res;
    }

    fn setBytes(r: *BigInt, bytes: []const u8, allcator: std.mem.Allocator) !void {
        try r.set(0);
        var tmp = try BigInt.init(allcator);
        defer tmp.deinit();
        for (bytes) |b| {
            try r.shiftLeft(r, 8);
            try tmp.set(b);
            try r.add(r, &tmp);
        }
    }

    fn pow_montgomery(r: *BigInt, a: *const BigInt, x: *const BigInt, n: *const BigInt, allocator: std.mem.Allocator) !void {
        var bin_raw: [512]u8 = undefined;
        try toBytes(&bin_raw, x, allocator);

        var i: usize = 0;
        while (bin_raw[i] == 0x00) : (i += 1) {}
        const bin = bin_raw[i..];

        try r.set(1);
        var r1 = try BigInt.init(allocator);
        defer r1.deinit();
        try BigInt.copy(&r1, a.toConst());
        i = 0;
        while (i < bin.len * 8) : (i += 1) {
            if (((bin[i / 8] >> @intCast(u3, (7 - (i % 8)))) & 0x1) == 0) {
                try BigInt.mul(&r1, r, &r1);
                try mod(&r1, &r1, n, allocator);
                try BigInt.sqr(r, r);
                try mod(r, r, n, allocator);
            } else {
                try BigInt.mul(r, r, &r1);
                try mod(r, r, n, allocator);
                try BigInt.sqr(&r1, &r1);
                try mod(&r1, &r1, n, allocator);
            }
        }
    }

    fn toBytes(out: []u8, a: *const BigInt, allocator: std.mem.Allocator) !void {
        const Error = error{
            BufferTooSmall,
        };

        var mask = try BigInt.initSet(allocator, 0xFF);
        defer mask.deinit();
        var tmp = try BigInt.init(allocator);
        defer tmp.deinit();

        var a_copy = try BigInt.init(allocator);
        defer a_copy.deinit();
        try a_copy.copy(a.toConst());

        // Encoding into big-endian bytes
        var i: usize = 0;
        while (i < out.len) : (i += 1) {
            try tmp.bitAnd(&a_copy, &mask);
            const b = try tmp.to(u8);
            out[out.len - i - 1] = b;
            try a_copy.shiftRight(&a_copy, 8);
        }

        if (!a_copy.eqZero()) {
            return Error.BufferTooSmall;
        }
    }

    fn mod(rem: *BigInt, a: *const BigInt, n: *const BigInt, allocator: std.mem.Allocator) !void {
        var q = try BigInt.init(allocator);
        defer q.deinit();

        try BigInt.divFloor(&q, rem, a, n);
    }

    fn countBits(a: std.math.big.int.Const, allocator: std.mem.Allocator) !usize {
        var i: usize = 0;
        var a_copy = try BigInt.init(allocator);
        defer a_copy.deinit();
        try a_copy.copy(a);

        while (!a_copy.eqZero()) {
            try a_copy.shiftRight(&a_copy, 1);
            i += 1;
        }

        return i;
    }
};
