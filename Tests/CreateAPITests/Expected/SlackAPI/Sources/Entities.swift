// Generated by Create API
// https://github.com/kean/CreateAPI
//
// swiftlint:disable all

import Foundation

public typealias DefsPinnedInfo = [String: DefsPinnedInfoItem]

public struct DefsPinnedInfoItem: Codable {
    /// User ID
    public var pinnedBy: String
    public var pinnedTs: Int

    public init(pinnedBy: String, pinnedTs: Int) {
        self.pinnedBy = pinnedBy
        self.pinnedTs = pinnedTs
    }

    private enum CodingKeys: String, CodingKey {
        case pinnedBy = "pinned_by"
        case pinnedTs = "pinned_ts"
    }
}

/// Channel Object
public struct ObjsChannel: Codable {
    /// User ID
    public var acceptedUser: String?
    public var created: Int
    /// User ID
    public var creator: String
    /// Channel ID
    public var id: String
    public var isArchived: Bool?
    public var isChannel: Bool
    public var isGeneral: Bool?
    public var isMember: Bool?
    public var isMoved: Int?
    public var isMpim: Bool
    public var isOrgShared: Bool
    public var isPendingExtShared: Bool?
    public var isPrivate: Bool
    public var isReadOnly: Bool?
    public var isShared: Bool
    /// Timestamp in format 0123456789.012345
    public var lastRead: String?
    public var latest: [String: AnyJSON]?
    public var members: [String]
    public var name: String
    public var nameNormalized: String
    public var numMembers: Int?
    public var pendingShared: [String]?
    public var previousNames: [String]?
    public var priority: Int?
    public var purpose: Purpose
    public var topic: Topic
    /// Field to determine whether a channel has ever been shared/disconnected in the past
    public var unlinked: Int?
    public var unreadCount: Int?
    public var unreadCountDisplay: Int?

    public struct Purpose: Codable {
        /// User ID or empty string, used for topic and purpose creation
        public var creator: String
        public var lastSet: Int
        public var value: String

        public init(creator: String, lastSet: Int, value: String) {
            self.creator = creator
            self.lastSet = lastSet
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case creator
            case lastSet = "last_set"
            case value
        }
    }

    public struct Topic: Codable {
        /// User ID or empty string, used for topic and purpose creation
        public var creator: String
        public var lastSet: Int
        public var value: String

        public init(creator: String, lastSet: Int, value: String) {
            self.creator = creator
            self.lastSet = lastSet
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case creator
            case lastSet = "last_set"
            case value
        }
    }

    public init(acceptedUser: String? = nil, created: Int, creator: String, id: String, isArchived: Bool? = nil, isChannel: Bool, isGeneral: Bool? = nil, isMember: Bool? = nil, isMoved: Int? = nil, isMpim: Bool, isOrgShared: Bool, isPendingExtShared: Bool? = nil, isPrivate: Bool, isReadOnly: Bool? = nil, isShared: Bool, lastRead: String? = nil, latest: [String: AnyJSON]? = nil, members: [String], name: String, nameNormalized: String, numMembers: Int? = nil, pendingShared: [String]? = nil, previousNames: [String]? = nil, priority: Int? = nil, purpose: Purpose, topic: Topic, unlinked: Int? = nil, unreadCount: Int? = nil, unreadCountDisplay: Int? = nil) {
        self.acceptedUser = acceptedUser
        self.created = created
        self.creator = creator
        self.id = id
        self.isArchived = isArchived
        self.isChannel = isChannel
        self.isGeneral = isGeneral
        self.isMember = isMember
        self.isMoved = isMoved
        self.isMpim = isMpim
        self.isOrgShared = isOrgShared
        self.isPendingExtShared = isPendingExtShared
        self.isPrivate = isPrivate
        self.isReadOnly = isReadOnly
        self.isShared = isShared
        self.lastRead = lastRead
        self.latest = latest
        self.members = members
        self.name = name
        self.nameNormalized = nameNormalized
        self.numMembers = numMembers
        self.pendingShared = pendingShared
        self.previousNames = previousNames
        self.priority = priority
        self.purpose = purpose
        self.topic = topic
        self.unlinked = unlinked
        self.unreadCount = unreadCount
        self.unreadCountDisplay = unreadCountDisplay
    }

    private enum CodingKeys: String, CodingKey {
        case acceptedUser = "accepted_user"
        case created
        case creator
        case id
        case isArchived = "is_archived"
        case isChannel = "is_channel"
        case isGeneral = "is_general"
        case isMember = "is_member"
        case isMoved = "is_moved"
        case isMpim = "is_mpim"
        case isOrgShared = "is_org_shared"
        case isPendingExtShared = "is_pending_ext_shared"
        case isPrivate = "is_private"
        case isReadOnly = "is_read_only"
        case isShared = "is_shared"
        case lastRead = "last_read"
        case latest
        case members
        case name
        case nameNormalized = "name_normalized"
        case numMembers = "num_members"
        case pendingShared = "pending_shared"
        case previousNames = "previous_names"
        case priority
        case purpose
        case topic
        case unlinked
        case unreadCount = "unread_count"
        case unreadCountDisplay = "unread_count_display"
    }
}

/// File Comment Object
public struct ObjsComment: Codable {
    public var comment: String?
    public var created: Int?
    /// File Comment ID
    public var id: String?
    public var isIntro: Bool?
    /// Info for a pinned item
    public var pinnedInfo: DefsPinnedInfo?
    public var pinnedTo: [String]?
    public var reactions: [ObjsReaction]?
    public var timestamp: Int?
    public var user: String?

    public init(comment: String? = nil, created: Int? = nil, id: String? = nil, isIntro: Bool? = nil, pinnedInfo: DefsPinnedInfo? = nil, pinnedTo: [String]? = nil, reactions: [ObjsReaction]? = nil, timestamp: Int? = nil, user: String? = nil) {
        self.comment = comment
        self.created = created
        self.id = id
        self.isIntro = isIntro
        self.pinnedInfo = pinnedInfo
        self.pinnedTo = pinnedTo
        self.reactions = reactions
        self.timestamp = timestamp
        self.user = user
    }

    private enum CodingKeys: String, CodingKey {
        case comment
        case created
        case id
        case isIntro = "is_intro"
        case pinnedInfo = "pinned_info"
        case pinnedTo = "pinned_to"
        case reactions
        case timestamp
        case user
    }
}

/// File object
public struct ObjsFile: Codable {
    public var channels: [String]?
    public var commentsCount: Int?
    public var created: Int?
    public var isDisplayAsBot: Bool?
    public var isEditable: Bool?
    public var externalType: String?
    public var filetype: String?
    public var groups: [String]?
    /// File ID
    public var id: String?
    public var imageExifRotation: Int?
    public var ims: [String]?
    public var isExternal: Bool?
    public var isPublic: Bool?
    public var mimetype: String?
    public var mode: String?
    public var name: String?
    public var originalH: Int?
    public var originalW: Int?
    public var permalink: URL?
    public var permalinkPublic: URL?
    /// Info for a pinned item
    public var pinnedInfo: DefsPinnedInfo?
    public var pinnedTo: [String]?
    public var prettyType: String?
    public var isPublicURLShared: Bool?
    public var reactions: [ObjsReaction]?
    public var size: Int?
    public var thumb1024: URL?
    public var thumb1024H: Int?
    public var thumb1024W: Int?
    public var thumb160: URL?
    public var thumb360: URL?
    public var thumb360H: Int?
    public var thumb360W: Int?
    public var thumb480: URL?
    public var thumb480H: Int?
    public var thumb480W: Int?
    public var thumb64: URL?
    public var thumb720: URL?
    public var thumb720H: Int?
    public var thumb720W: Int?
    public var thumb80: URL?
    public var thumb800: URL?
    public var thumb800H: Int?
    public var thumb800W: Int?
    public var thumb960: URL?
    public var thumb960H: Int?
    public var thumb960W: Int?
    public var timestamp: Int?
    public var title: String?
    public var urlPrivate: URL?
    public var urlPrivateDownload: URL?
    public var user: String?
    public var username: String?

    public init(channels: [String]? = nil, commentsCount: Int? = nil, created: Int? = nil, isDisplayAsBot: Bool? = nil, isEditable: Bool? = nil, externalType: String? = nil, filetype: String? = nil, groups: [String]? = nil, id: String? = nil, imageExifRotation: Int? = nil, ims: [String]? = nil, isExternal: Bool? = nil, isPublic: Bool? = nil, mimetype: String? = nil, mode: String? = nil, name: String? = nil, originalH: Int? = nil, originalW: Int? = nil, permalink: URL? = nil, permalinkPublic: URL? = nil, pinnedInfo: DefsPinnedInfo? = nil, pinnedTo: [String]? = nil, prettyType: String? = nil, isPublicURLShared: Bool? = nil, reactions: [ObjsReaction]? = nil, size: Int? = nil, thumb1024: URL? = nil, thumb1024H: Int? = nil, thumb1024W: Int? = nil, thumb160: URL? = nil, thumb360: URL? = nil, thumb360H: Int? = nil, thumb360W: Int? = nil, thumb480: URL? = nil, thumb480H: Int? = nil, thumb480W: Int? = nil, thumb64: URL? = nil, thumb720: URL? = nil, thumb720H: Int? = nil, thumb720W: Int? = nil, thumb80: URL? = nil, thumb800: URL? = nil, thumb800H: Int? = nil, thumb800W: Int? = nil, thumb960: URL? = nil, thumb960H: Int? = nil, thumb960W: Int? = nil, timestamp: Int? = nil, title: String? = nil, urlPrivate: URL? = nil, urlPrivateDownload: URL? = nil, user: String? = nil, username: String? = nil) {
        self.channels = channels
        self.commentsCount = commentsCount
        self.created = created
        self.isDisplayAsBot = isDisplayAsBot
        self.isEditable = isEditable
        self.externalType = externalType
        self.filetype = filetype
        self.groups = groups
        self.id = id
        self.imageExifRotation = imageExifRotation
        self.ims = ims
        self.isExternal = isExternal
        self.isPublic = isPublic
        self.mimetype = mimetype
        self.mode = mode
        self.name = name
        self.originalH = originalH
        self.originalW = originalW
        self.permalink = permalink
        self.permalinkPublic = permalinkPublic
        self.pinnedInfo = pinnedInfo
        self.pinnedTo = pinnedTo
        self.prettyType = prettyType
        self.isPublicURLShared = isPublicURLShared
        self.reactions = reactions
        self.size = size
        self.thumb1024 = thumb1024
        self.thumb1024H = thumb1024H
        self.thumb1024W = thumb1024W
        self.thumb160 = thumb160
        self.thumb360 = thumb360
        self.thumb360H = thumb360H
        self.thumb360W = thumb360W
        self.thumb480 = thumb480
        self.thumb480H = thumb480H
        self.thumb480W = thumb480W
        self.thumb64 = thumb64
        self.thumb720 = thumb720
        self.thumb720H = thumb720H
        self.thumb720W = thumb720W
        self.thumb80 = thumb80
        self.thumb800 = thumb800
        self.thumb800H = thumb800H
        self.thumb800W = thumb800W
        self.thumb960 = thumb960
        self.thumb960H = thumb960H
        self.thumb960W = thumb960W
        self.timestamp = timestamp
        self.title = title
        self.urlPrivate = urlPrivate
        self.urlPrivateDownload = urlPrivateDownload
        self.user = user
        self.username = username
    }

    private enum CodingKeys: String, CodingKey {
        case channels
        case commentsCount = "comments_count"
        case created
        case isDisplayAsBot = "display_as_bot"
        case isEditable = "editable"
        case externalType = "external_type"
        case filetype
        case groups
        case id
        case imageExifRotation = "image_exif_rotation"
        case ims
        case isExternal = "is_external"
        case isPublic = "is_public"
        case mimetype
        case mode
        case name
        case originalH = "original_h"
        case originalW = "original_w"
        case permalink
        case permalinkPublic = "permalink_public"
        case pinnedInfo = "pinned_info"
        case pinnedTo = "pinned_to"
        case prettyType = "pretty_type"
        case isPublicURLShared = "public_url_shared"
        case reactions
        case size
        case thumb1024 = "thumb_1024"
        case thumb1024H = "thumb_1024_h"
        case thumb1024W = "thumb_1024_w"
        case thumb160 = "thumb_160"
        case thumb360 = "thumb_360"
        case thumb360H = "thumb_360_h"
        case thumb360W = "thumb_360_w"
        case thumb480 = "thumb_480"
        case thumb480H = "thumb_480_h"
        case thumb480W = "thumb_480_w"
        case thumb64 = "thumb_64"
        case thumb720 = "thumb_720"
        case thumb720H = "thumb_720_h"
        case thumb720W = "thumb_720_w"
        case thumb80 = "thumb_80"
        case thumb800 = "thumb_800"
        case thumb800H = "thumb_800_h"
        case thumb800W = "thumb_800_w"
        case thumb960 = "thumb_960"
        case thumb960H = "thumb_960_h"
        case thumb960W = "thumb_960_w"
        case timestamp
        case title
        case urlPrivate = "url_private"
        case urlPrivateDownload = "url_private_download"
        case user
        case username
    }
}

/// Group object
public struct ObjsGroup: Codable {
    public var created: Int
    /// User ID
    public var creator: String
    /// Private Channel ID
    public var id: String
    public var isArchived: Bool?
    public var isGroup: Bool
    public var isMoved: Int?
    public var isMpim: Bool?
    public var isOpen: Bool?
    public var isPendingExtShared: Bool?
    /// Timestamp in format 0123456789.012345
    public var lastRead: String?
    public var latest: [String: AnyJSON]?
    public var members: [String]
    public var name: String
    public var nameNormalized: String
    public var priority: Int?
    public var purpose: Purpose
    public var topic: Topic
    public var unreadCount: Int?
    public var unreadCountDisplay: Int?

    public struct Purpose: Codable {
        /// User ID or empty string, used for topic and purpose creation
        public var creator: String
        public var lastSet: Int
        public var value: String

        public init(creator: String, lastSet: Int, value: String) {
            self.creator = creator
            self.lastSet = lastSet
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case creator
            case lastSet = "last_set"
            case value
        }
    }

    public struct Topic: Codable {
        /// User ID or empty string, used for topic and purpose creation
        public var creator: String
        public var lastSet: Int
        public var value: String

        public init(creator: String, lastSet: Int, value: String) {
            self.creator = creator
            self.lastSet = lastSet
            self.value = value
        }

        private enum CodingKeys: String, CodingKey {
            case creator
            case lastSet = "last_set"
            case value
        }
    }

    public init(created: Int, creator: String, id: String, isArchived: Bool? = nil, isGroup: Bool, isMoved: Int? = nil, isMpim: Bool? = nil, isOpen: Bool? = nil, isPendingExtShared: Bool? = nil, lastRead: String? = nil, latest: [String: AnyJSON]? = nil, members: [String], name: String, nameNormalized: String, priority: Int? = nil, purpose: Purpose, topic: Topic, unreadCount: Int? = nil, unreadCountDisplay: Int? = nil) {
        self.created = created
        self.creator = creator
        self.id = id
        self.isArchived = isArchived
        self.isGroup = isGroup
        self.isMoved = isMoved
        self.isMpim = isMpim
        self.isOpen = isOpen
        self.isPendingExtShared = isPendingExtShared
        self.lastRead = lastRead
        self.latest = latest
        self.members = members
        self.name = name
        self.nameNormalized = nameNormalized
        self.priority = priority
        self.purpose = purpose
        self.topic = topic
        self.unreadCount = unreadCount
        self.unreadCountDisplay = unreadCountDisplay
    }

    private enum CodingKeys: String, CodingKey {
        case created
        case creator
        case id
        case isArchived = "is_archived"
        case isGroup = "is_group"
        case isMoved = "is_moved"
        case isMpim = "is_mpim"
        case isOpen = "is_open"
        case isPendingExtShared = "is_pending_ext_shared"
        case lastRead = "last_read"
        case latest
        case members
        case name
        case nameNormalized = "name_normalized"
        case priority
        case purpose
        case topic
        case unreadCount = "unread_count"
        case unreadCountDisplay = "unread_count_display"
    }
}

/// IM Object
public struct ObjsIm: Codable {
    public var created: Int
    /// Direct Message Channel ID
    public var id: String
    public var isIm: Bool
    public var isOrgShared: Bool
    public var isUserDeleted: Bool
    public var priority: Int?
    /// User ID
    public var user: String

    public init(created: Int, id: String, isIm: Bool, isOrgShared: Bool, isUserDeleted: Bool, priority: Int? = nil, user: String) {
        self.created = created
        self.id = id
        self.isIm = isIm
        self.isOrgShared = isOrgShared
        self.isUserDeleted = isUserDeleted
        self.priority = priority
        self.user = user
    }

    private enum CodingKeys: String, CodingKey {
        case created
        case id
        case isIm = "is_im"
        case isOrgShared = "is_org_shared"
        case isUserDeleted = "is_user_deleted"
        case priority
        case user
    }
}

/// Message object
public struct ObjsMessage: Codable {
    public var attachments: [Attachmants]?
    public var botID: [String: AnyJSON]?
    /// File Comment Object
    public var comment: ObjsComment?
    public var isDisplayAsBot: Bool?
    /// File object
    public var file: ObjsFile?
    public var icons: Icons?
    /// User ID
    public var inviter: String?
    public var isIntro: Bool?
    /// Timestamp in format 0123456789.012345
    public var lastRead: String?
    public var name: String?
    public var oldName: String?
    public var permalink: URL?
    public var pinnedTo: [String]?
    public var purpose: String?
    public var reactions: [ObjsReaction]?
    public var replies: [Reply]?
    public var replyCount: Int?
    /// Team ID
    public var sourceTeam: String?
    public var isSubscribed: Bool?
    public var subtype: String?
    /// Team ID
    public var team: String?
    public var text: String
    /// Timestamp in format 0123456789.012345
    public var threadTs: String?
    public var topic: String?
    /// Timestamp in format 0123456789.012345
    public var ts: String
    public var type: String
    public var unreadCount: Int?
    public var isUpload: Bool?
    /// User ID
    public var user: String?
    public var userProfile: ObjsUserProfileShort?
    /// Team ID
    public var userTeam: String?
    public var username: String?

    public struct Attachmants: Codable {
        public var fallback: String?
        public var id: Int
        public var imageBytes: Int?
        public var imageHeight: Int?
        public var imageURL: String?
        public var imageWidth: Int?

        public init(fallback: String? = nil, id: Int, imageBytes: Int? = nil, imageHeight: Int? = nil, imageURL: String? = nil, imageWidth: Int? = nil) {
            self.fallback = fallback
            self.id = id
            self.imageBytes = imageBytes
            self.imageHeight = imageHeight
            self.imageURL = imageURL
            self.imageWidth = imageWidth
        }

        private enum CodingKeys: String, CodingKey {
            case fallback
            case id
            case imageBytes = "image_bytes"
            case imageHeight = "image_height"
            case imageURL = "image_url"
            case imageWidth = "image_width"
        }
    }

    public struct Icons: Codable {
        public var emoji: String?

        public init(emoji: String? = nil) {
            self.emoji = emoji
        }
    }

    public struct Reply: Codable {
        /// Timestamp in format 0123456789.012345
        public var ts: String
        /// User ID
        public var user: String

        public init(ts: String, user: String) {
            self.ts = ts
            self.user = user
        }
    }

    public init(attachments: [Attachmants]? = nil, botID: [String: AnyJSON]? = nil, comment: ObjsComment? = nil, isDisplayAsBot: Bool? = nil, file: ObjsFile? = nil, icons: Icons? = nil, inviter: String? = nil, isIntro: Bool? = nil, lastRead: String? = nil, name: String? = nil, oldName: String? = nil, permalink: URL? = nil, pinnedTo: [String]? = nil, purpose: String? = nil, reactions: [ObjsReaction]? = nil, replies: [Reply]? = nil, replyCount: Int? = nil, sourceTeam: String? = nil, isSubscribed: Bool? = nil, subtype: String? = nil, team: String? = nil, text: String, threadTs: String? = nil, topic: String? = nil, ts: String, type: String, unreadCount: Int? = nil, isUpload: Bool? = nil, user: String? = nil, userProfile: ObjsUserProfileShort? = nil, userTeam: String? = nil, username: String? = nil) {
        self.attachments = attachments
        self.botID = botID
        self.comment = comment
        self.isDisplayAsBot = isDisplayAsBot
        self.file = file
        self.icons = icons
        self.inviter = inviter
        self.isIntro = isIntro
        self.lastRead = lastRead
        self.name = name
        self.oldName = oldName
        self.permalink = permalink
        self.pinnedTo = pinnedTo
        self.purpose = purpose
        self.reactions = reactions
        self.replies = replies
        self.replyCount = replyCount
        self.sourceTeam = sourceTeam
        self.isSubscribed = isSubscribed
        self.subtype = subtype
        self.team = team
        self.text = text
        self.threadTs = threadTs
        self.topic = topic
        self.ts = ts
        self.type = type
        self.unreadCount = unreadCount
        self.isUpload = isUpload
        self.user = user
        self.userProfile = userProfile
        self.userTeam = userTeam
        self.username = username
    }

    private enum CodingKeys: String, CodingKey {
        case attachments
        case botID = "bot_id"
        case comment
        case isDisplayAsBot = "display_as_bot"
        case file
        case icons
        case inviter
        case isIntro = "is_intro"
        case lastRead = "last_read"
        case name
        case oldName = "old_name"
        case permalink
        case pinnedTo = "pinned_to"
        case purpose
        case reactions
        case replies
        case replyCount = "reply_count"
        case sourceTeam = "source_team"
        case isSubscribed = "subscribed"
        case subtype
        case team
        case text
        case threadTs = "thread_ts"
        case topic
        case ts
        case type
        case unreadCount = "unread_count"
        case isUpload = "upload"
        case user
        case userProfile = "user_profile"
        case userTeam = "user_team"
        case username
    }
}

/// Paging object for files
public struct ObjsPaging: Codable {
    public var count: Int
    public var page: Int
    public var pages: Int?
    public var total: Int

    public init(count: Int, page: Int, pages: Int? = nil, total: Int) {
        self.count = count
        self.page = page
        self.pages = pages
        self.total = total
    }
}

/// Reaction object
public struct ObjsReaction: Codable {
    public var count: Int
    public var name: String
    public var users: [String]

    public init(count: Int, name: String, users: [String]) {
        self.count = count
        self.name = name
        self.users = users
    }
}

/// Team Object
public struct ObjsTeam: Codable {
    public var avatarBaseURL: URL?
    public var domain: String
    public var emailDomain: String
    public var enterpriseID: String?
    public var enterpriseName: String?
    public var hasComplianceExport: Bool?
    public var icon: Icon
    /// Team ID
    public var id: String
    public var messagesCount: Int?
    public var msgEditWindowMins: Int?
    public var name: String
    public var isOverIntegrationsLimit: Bool?
    public var isOverStorageLimit: Bool?
    public var plan: String?

    public struct Icon: Codable {
        public var image102: String?
        public var image132: String?
        public var image230: String?
        public var image34: String?
        public var image44: String?
        public var image68: String?
        public var image88: String?
        public var isImageDefault: Bool?

        public init(image102: String? = nil, image132: String? = nil, image230: String? = nil, image34: String? = nil, image44: String? = nil, image68: String? = nil, image88: String? = nil, isImageDefault: Bool? = nil) {
            self.image102 = image102
            self.image132 = image132
            self.image230 = image230
            self.image34 = image34
            self.image44 = image44
            self.image68 = image68
            self.image88 = image88
            self.isImageDefault = isImageDefault
        }

        private enum CodingKeys: String, CodingKey {
            case image102 = "image_102"
            case image132 = "image_132"
            case image230 = "image_230"
            case image34 = "image_34"
            case image44 = "image_44"
            case image68 = "image_68"
            case image88 = "image_88"
            case isImageDefault = "image_default"
        }
    }

    public init(avatarBaseURL: URL? = nil, domain: String, emailDomain: String, enterpriseID: String? = nil, enterpriseName: String? = nil, hasComplianceExport: Bool? = nil, icon: Icon, id: String, messagesCount: Int? = nil, msgEditWindowMins: Int? = nil, name: String, isOverIntegrationsLimit: Bool? = nil, isOverStorageLimit: Bool? = nil, plan: String? = nil) {
        self.avatarBaseURL = avatarBaseURL
        self.domain = domain
        self.emailDomain = emailDomain
        self.enterpriseID = enterpriseID
        self.enterpriseName = enterpriseName
        self.hasComplianceExport = hasComplianceExport
        self.icon = icon
        self.id = id
        self.messagesCount = messagesCount
        self.msgEditWindowMins = msgEditWindowMins
        self.name = name
        self.isOverIntegrationsLimit = isOverIntegrationsLimit
        self.isOverStorageLimit = isOverStorageLimit
        self.plan = plan
    }

    private enum CodingKeys: String, CodingKey {
        case avatarBaseURL = "avatar_base_url"
        case domain
        case emailDomain = "email_domain"
        case enterpriseID = "enterprise_id"
        case enterpriseName = "enterprise_name"
        case hasComplianceExport = "has_compliance_export"
        case icon
        case id
        case messagesCount = "messages_count"
        case msgEditWindowMins = "msg_edit_window_mins"
        case name
        case isOverIntegrationsLimit = "over_integrations_limit"
        case isOverStorageLimit = "over_storage_limit"
        case plan
    }
}

public struct ObjsTeamProfileField: Codable {
    public var fieldName: String?
    public var hint: String
    public var id: String
    public var isHidden: Bool?
    public var label: String
    public var options: [String]
    public var ordering: Double
    public var possibleValues: [String]?
    public var type: `Type`

    public enum `Type`: String, Codable, CaseIterable {
        case text
        case date
        case link
        case mailto
        case optionsList = "options_list"
        case user
    }

    public init(fieldName: String? = nil, hint: String, id: String, isHidden: Bool? = nil, label: String, options: [String], ordering: Double, possibleValues: [String]? = nil, type: `Type`) {
        self.fieldName = fieldName
        self.hint = hint
        self.id = id
        self.isHidden = isHidden
        self.label = label
        self.options = options
        self.ordering = ordering
        self.possibleValues = possibleValues
        self.type = type
    }

    private enum CodingKeys: String, CodingKey {
        case fieldName = "field_name"
        case hint
        case id
        case isHidden = "is_hidden"
        case label
        case options
        case ordering
        case possibleValues = "possible_values"
        case type
    }
}

public struct ObjsUser: Codable {
    public var color: String
    public var isDeleted: Bool
    public var isHas2fa: Bool?
    /// User ID
    public var id: String
    public var isAdmin: Bool
    public var isAppUser: Bool
    public var isBot: Bool
    public var isOwner: Bool
    public var isPrimaryOwner: Bool
    public var isRestricted: Bool
    public var isUltraRestricted: Bool
    public var locale: String?
    public var name: String
    public var presence: String?
    /// User profile object
    public var profile: ObjsUserProfile
    public var realName: String
    public var teamID: String
    public var tz: String
    public var tzLabel: String
    public var tzOffset: Double
    public var updated: Double

    public init(color: String, isDeleted: Bool, isHas2fa: Bool? = nil, id: String, isAdmin: Bool, isAppUser: Bool, isBot: Bool, isOwner: Bool, isPrimaryOwner: Bool, isRestricted: Bool, isUltraRestricted: Bool, locale: String? = nil, name: String, presence: String? = nil, profile: ObjsUserProfile, realName: String, teamID: String, tz: String, tzLabel: String, tzOffset: Double, updated: Double) {
        self.color = color
        self.isDeleted = isDeleted
        self.isHas2fa = isHas2fa
        self.id = id
        self.isAdmin = isAdmin
        self.isAppUser = isAppUser
        self.isBot = isBot
        self.isOwner = isOwner
        self.isPrimaryOwner = isPrimaryOwner
        self.isRestricted = isRestricted
        self.isUltraRestricted = isUltraRestricted
        self.locale = locale
        self.name = name
        self.presence = presence
        self.profile = profile
        self.realName = realName
        self.teamID = teamID
        self.tz = tz
        self.tzLabel = tzLabel
        self.tzOffset = tzOffset
        self.updated = updated
    }

    private enum CodingKeys: String, CodingKey {
        case color
        case isDeleted = "deleted"
        case isHas2fa = "has_2fa"
        case id
        case isAdmin = "is_admin"
        case isAppUser = "is_app_user"
        case isBot = "is_bot"
        case isOwner = "is_owner"
        case isPrimaryOwner = "is_primary_owner"
        case isRestricted = "is_restricted"
        case isUltraRestricted = "is_ultra_restricted"
        case locale
        case name
        case presence
        case profile
        case realName = "real_name"
        case teamID = "team_id"
        case tz
        case tzLabel = "tz_label"
        case tzOffset = "tz_offset"
        case updated
    }
}

/// User profile object
public struct ObjsUserProfile: Codable {
    public var isAlwaysActive: Bool?
    public var avatarHash: String
    public var displayName: String
    public var displayNameNormalized: String
    public var email: String?
    public var fields: [String: AnyJSON]?
    public var firstName: String?
    public var guestChannels: String?
    public var image192: URL
    public var image24: URL
    public var image32: URL
    public var image48: URL
    public var image512: URL?
    public var image72: URL
    public var imageOriginal: URL?
    public var lastName: String?
    public var phone: String?
    public var realName: String
    public var realNameNormalized: String
    public var skype: String?
    public var statusEmoji: String?
    public var statusExpiration: Int?
    public var statusText: String?
    public var statusTextCanonical: String?
    /// Team ID
    public var team: String?
    public var title: String?

    public init(isAlwaysActive: Bool? = nil, avatarHash: String, displayName: String, displayNameNormalized: String, email: String? = nil, fields: [String: AnyJSON]? = nil, firstName: String? = nil, guestChannels: String? = nil, image192: URL, image24: URL, image32: URL, image48: URL, image512: URL? = nil, image72: URL, imageOriginal: URL? = nil, lastName: String? = nil, phone: String? = nil, realName: String, realNameNormalized: String, skype: String? = nil, statusEmoji: String? = nil, statusExpiration: Int? = nil, statusText: String? = nil, statusTextCanonical: String? = nil, team: String? = nil, title: String? = nil) {
        self.isAlwaysActive = isAlwaysActive
        self.avatarHash = avatarHash
        self.displayName = displayName
        self.displayNameNormalized = displayNameNormalized
        self.email = email
        self.fields = fields
        self.firstName = firstName
        self.guestChannels = guestChannels
        self.image192 = image192
        self.image24 = image24
        self.image32 = image32
        self.image48 = image48
        self.image512 = image512
        self.image72 = image72
        self.imageOriginal = imageOriginal
        self.lastName = lastName
        self.phone = phone
        self.realName = realName
        self.realNameNormalized = realNameNormalized
        self.skype = skype
        self.statusEmoji = statusEmoji
        self.statusExpiration = statusExpiration
        self.statusText = statusText
        self.statusTextCanonical = statusTextCanonical
        self.team = team
        self.title = title
    }

    private enum CodingKeys: String, CodingKey {
        case isAlwaysActive = "always_active"
        case avatarHash = "avatar_hash"
        case displayName = "display_name"
        case displayNameNormalized = "display_name_normalized"
        case email
        case fields
        case firstName = "first_name"
        case guestChannels = "guest_channels"
        case image192 = "image_192"
        case image24 = "image_24"
        case image32 = "image_32"
        case image48 = "image_48"
        case image512 = "image_512"
        case image72 = "image_72"
        case imageOriginal = "image_original"
        case lastName = "last_name"
        case phone
        case realName = "real_name"
        case realNameNormalized = "real_name_normalized"
        case skype
        case statusEmoji = "status_emoji"
        case statusExpiration = "status_expiration"
        case statusText = "status_text"
        case statusTextCanonical = "status_text_canonical"
        case team
        case title
    }
}

public struct ObjsUserProfileShort: Codable {
    public var avatarHash: String
    public var displayName: String
    public var firstName: String
    public var image72: URL
    public var isRestricted: Bool
    public var isUltraRestricted: Bool
    public var name: String
    public var realName: String
    /// Team ID
    public var team: String

    public init(avatarHash: String, displayName: String, firstName: String, image72: URL, isRestricted: Bool, isUltraRestricted: Bool, name: String, realName: String, team: String) {
        self.avatarHash = avatarHash
        self.displayName = displayName
        self.firstName = firstName
        self.image72 = image72
        self.isRestricted = isRestricted
        self.isUltraRestricted = isUltraRestricted
        self.name = name
        self.realName = realName
        self.team = team
    }

    private enum CodingKeys: String, CodingKey {
        case avatarHash = "avatar_hash"
        case displayName = "display_name"
        case firstName = "first_name"
        case image72 = "image_72"
        case isRestricted = "is_restricted"
        case isUltraRestricted = "is_ultra_restricted"
        case name
        case realName = "real_name"
        case team
    }
}

public enum AnyJSON: Equatable, Codable {
    case string(String)
    case number(Double)
    case object([String: AnyJSON])
    case array([AnyJSON])
    case bool(Bool)

    var value: Any {
        switch self {
        case .string(let string): return string
        case .number(let double): return double
        case .object(let dictionary): return dictionary
        case .array(let array): return array
        case .bool(let bool): return bool
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .array(array): try container.encode(array)
        case let .object(object): try container.encode(object)
        case let .string(string): try container.encode(string)
        case let .number(number): try container.encode(number)
        case let .bool(bool): try container.encode(bool)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let object = try? container.decode([String: AnyJSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([AnyJSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}

struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {
    private let string: String
    private var int: Int?

    var stringValue: String { return string }

    init(string: String) {
        self.string = string
    }

    init?(stringValue: String) {
        self.string = stringValue
    }

    var intValue: Int? { return int }

    init?(intValue: Int) {
        self.string = String(describing: intValue)
        self.int = intValue
    }

    init(stringLiteral value: String) {
        self.string = value
    }
}