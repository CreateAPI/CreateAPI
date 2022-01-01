// Generated by Create API
// https://github.com/kean/CreateAPI
//
// swiftlint:disable all

import Foundation
import Get

extension Paths {
    public static var image: Image {
        Image(path: "/ocr/image")
    }

    public struct Image {
        /// Path: `/ocr/image`
        public let path: String
    }
}

extension Paths.Image {
    public var toText: ToText {
        ToText(path: path + "/toText")
    }

    public struct ToText {
        /// Path: `/ocr/image/toText`
        public let path: String

        /// Convert a scanned image into text
        ///
        /// Converts an uploaded image in common formats such as JPEG, PNG into text via Optical Character Recognition.  This API is intended to be run on scanned documents.  If you want to OCR photos (e.g. taken with a smart phone camera), be sure to use the photo/toText API instead, as it is designed to unskew the image first.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.ImageToTextResponse> {
            .post(path, body: body)
        }
    }
}

extension Paths.Image {
    public var to: To {
        To(path: path + "/to")
    }

    public struct To {
        /// Path: `/ocr/image/to`
        public let path: String
    }
}

extension Paths.Image.To {
    public var wordsWithLocation: WordsWithLocation {
        WordsWithLocation(path: path + "/words-with-location")
    }

    public struct WordsWithLocation {
        /// Path: `/ocr/image/to/words-with-location`
        public let path: String

        /// Convert a scanned image into words with location
        ///
        /// Converts an uploaded image in common formats such as JPEG, PNG into words/text with location information and other metdata via Optical Character Recognition.  This API is intended to be run on scanned documents.  If you want to OCR photos (e.g. taken with a smart phone camera), be sure to use the photo/toText API instead, as it is designed to unskew the image first.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.ImageToWordsWithLocationResult> {
            .post(path, body: body)
        }
    }
}

extension Paths.Image.To {
    public var linesWithLocation: LinesWithLocation {
        LinesWithLocation(path: path + "/lines-with-location")
    }

    public struct LinesWithLocation {
        /// Path: `/ocr/image/to/lines-with-location`
        public let path: String

        /// Convert a scanned image into words with location
        ///
        /// Converts an uploaded image in common formats such as JPEG, PNG into lines/text with location information and other metdata via Optical Character Recognition.  This API is intended to be run on scanned documents.  If you want to OCR photos (e.g. taken with a smart phone camera), be sure to use the photo/toText API instead, as it is designed to unskew the image first.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.ImageToLinesWithLocationResult> {
            .post(path, body: body)
        }
    }
}

extension Paths {
    public static var photo: Photo {
        Photo(path: "/ocr/photo")
    }

    public struct Photo {
        /// Path: `/ocr/photo`
        public let path: String
    }
}

extension Paths.Photo {
    public var toText: ToText {
        ToText(path: path + "/toText")
    }

    public struct ToText {
        /// Path: `/ocr/photo/toText`
        public let path: String

        /// Convert a photo of a document into text
        ///
        /// Converts an uploaded photo of a document in common formats such as JPEG, PNG into text via Optical Character Recognition.  This API is intended to be run on photos of documents, e.g. taken with a smartphone and supports cases where other content, such as a desk, are in the frame and the camera is crooked.  If you want to OCR a scanned image, use the image/toText API call instead as it is designed for scanned images.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.ImageToTextResponse> {
            .post(path, body: body)
        }
    }
}

extension Paths.Photo {
    public var to: To {
        To(path: path + "/to")
    }

    public struct To {
        /// Path: `/ocr/photo/to`
        public let path: String
    }
}

extension Paths.Photo.To {
    public var wordsWithLocation: WordsWithLocation {
        WordsWithLocation(path: path + "/words-with-location")
    }

    public struct WordsWithLocation {
        /// Path: `/ocr/photo/to/words-with-location`
        public let path: String

        /// Convert a photo of a document or receipt into words with location
        ///
        /// Converts a photo of a document or receipt in common formats such as JPEG, PNG into words/text with location information and other metdata via Optical Character Recognition.  This API is intended to be run on photographs of documents.  If you want to OCR scanned documents (e.g. taken with a scanner), be sure to use the image/toText API instead, as it is designed for that use case.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.PhotoToWordsWithLocationResult> {
            .post(path, body: body)
        }
    }
}

extension Paths.Photo {
    public var recognize: Recognize {
        Recognize(path: path + "/recognize")
    }

    public struct Recognize {
        /// Path: `/ocr/photo/recognize`
        public let path: String
    }
}

extension Paths.Photo.Recognize {
    public var receipt: Receipt {
        Receipt(path: path + "/receipt")
    }

    public struct Receipt {
        /// Path: `/ocr/photo/recognize/receipt`
        public let path: String

        /// Recognize a photo of a receipt, extract key business information
        ///
        /// Analyzes a photograph of a receipt as input, and outputs key business information such as the name of the business, the address of the business, the phone number of the business, the total of the receipt, the date of the receipt, and more.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.ReceiptRecognitionResult> {
            .post(path, body: body)
        }
    }
}

extension Paths.Photo.Recognize {
    public var businessCard: BusinessCard {
        BusinessCard(path: path + "/business-card")
    }

    public struct BusinessCard {
        /// Path: `/ocr/photo/recognize/business-card`
        public let path: String

        /// Recognize a photo of a business card, extract key business information
        ///
        /// Analyzes a photograph of a business card as input, and outputs key business information such as the name of the person, name of the business, the address of the business, the phone number, the email address and more.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.BusinessCardRecognitionResult> {
            .post(path, body: body)
        }
    }
}

extension Paths.Photo.Recognize {
    public var form: Form {
        Form(path: path + "/form")
    }

    public struct Form {
        /// Path: `/ocr/photo/recognize/form`
        public let path: String

        /// Recognize a photo of a form, extract key fields and business information
        ///
        /// Analyzes a photograph of a form as input, and outputs key business fields and information.  Customzie data to be extracted by defining fields for the form.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.FormRecognitionResult> {
            .post(path, body: body)
        }
    }
}

extension Paths.Photo.Recognize.Form {
    public var advanced: Advanced {
        Advanced(path: path + "/advanced")
    }

    public struct Advanced {
        /// Path: `/ocr/photo/recognize/form/advanced`
        public let path: String

        /// Recognize a photo of a form, extract key fields using stored templates
        ///
        /// Analyzes a photograph of a form as input, and outputs key business fields and information.  Customzie data to be extracted by defining fields for the form.  Uses template definitions stored in Cloudmersive Configuration; to configure stored templates in a configuration bucket, log into Cloudmersive Management Portal and navigate to Settings &gt; API Configuration &gt; Create Bucket.  Note: for free tier API keys, it is required to add a credit card to your account for security reasons, to use the free tier key with this API.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.FormRecognitionResult> {
            .post(path, body: body)
        }
    }
}

extension Paths {
    public static var pdf: Pdf {
        Pdf(path: "/ocr/pdf")
    }

    public struct Pdf {
        /// Path: `/ocr/pdf`
        public let path: String
    }
}

extension Paths.Pdf {
    public var toText: ToText {
        ToText(path: path + "/toText")
    }

    public struct ToText {
        /// Path: `/ocr/pdf/toText`
        public let path: String

        /// Converts an uploaded PDF file into text via Optical Character Recognition.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.PdfToTextResponse> {
            .post(path, body: body)
        }
    }
}

extension Paths.Pdf {
    public var to: To {
        To(path: path + "/to")
    }

    public struct To {
        /// Path: `/ocr/pdf/to`
        public let path: String
    }
}

extension Paths.Pdf.To {
    public var wordsWithLocation: WordsWithLocation {
        WordsWithLocation(path: path + "/words-with-location")
    }

    public struct WordsWithLocation {
        /// Path: `/ocr/pdf/to/words-with-location`
        public let path: String

        /// Convert a PDF into words with location
        ///
        /// Converts a PDF into words/text with location information and other metdata via Optical Character Recognition.  This API is intended to be run on scanned documents.  If you want to OCR photos (e.g. taken with a smart phone camera), be sure to use the photo/toText API instead, as it is designed to unskew the image first.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.PdfToWordsWithLocationResult> {
            .post(path, body: body)
        }
    }
}

extension Paths.Pdf.To {
    public var linesWithLocation: LinesWithLocation {
        LinesWithLocation(path: path + "/lines-with-location")
    }

    public struct LinesWithLocation {
        /// Path: `/ocr/pdf/to/lines-with-location`
        public let path: String

        /// Convert a PDF into text lines with location
        ///
        /// Converts a PDF into lines/text with location information and other metdata via Optical Character Recognition.  This API is intended to be run on scanned documents.  If you want to OCR photos (e.g. taken with a smart phone camera), be sure to use the photo/toText API instead, as it is designed to unskew the image first.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.PdfToLinesWithLocationResult> {
            .post(path, body: body)
        }
    }
}

extension Paths {
    public static var preprocessing: Preprocessing {
        Preprocessing(path: "/ocr/preprocessing")
    }

    public struct Preprocessing {
        /// Path: `/ocr/preprocessing`
        public let path: String
    }
}

extension Paths.Preprocessing {
    public var image: Image {
        Image(path: path + "/image")
    }

    public struct Image {
        /// Path: `/ocr/preprocessing/image`
        public let path: String
    }
}

extension Paths.Preprocessing.Image {
    public var binarize: Binarize {
        Binarize(path: path + "/binarize")
    }

    public struct Binarize {
        /// Path: `/ocr/preprocessing/image/binarize`
        public let path: String

        /// Convert an image of text into a binarized (light and dark) view
        ///
        /// Perform an adaptive binarization algorithm on the input image to prepare it for further OCR operations.
        public func post(_ body: Data) -> Request<String> {
            .post(path, body: body)
        }
    }
}

extension Paths.Preprocessing.Image.Binarize {
    public var advanced: Advanced {
        Advanced(path: path + "/advanced")
    }

    public struct Advanced {
        /// Path: `/ocr/preprocessing/image/binarize/advanced`
        public let path: String

        /// Convert an image of text into a binary (light and dark) view with ML
        ///
        /// Perform an advanced adaptive, Deep Learning-based binarization algorithm on the input image to prepare it for further OCR operations.  Provides enhanced accuracy than adaptive binarization.  Image will be upsampled to 300 DPI if it has a DPI below 300.
        public func post(_ body: Data) -> Request<String> {
            .post(path, body: body)
        }
    }
}

extension Paths.Preprocessing.Image {
    public var getPageAngle: GetPageAngle {
        GetPageAngle(path: path + "/get-page-angle")
    }

    public struct GetPageAngle {
        /// Path: `/ocr/preprocessing/image/get-page-angle`
        public let path: String

        /// Get the angle of the page / document / receipt
        ///
        /// Analyzes a photo or image of a document and identifies the rotation angle of the page.
        public func post(_ body: Data) -> Request<CloudmersiveAPI.GetPageAngleResult> {
            .post(path, body: body)
        }
    }
}

extension Paths.Preprocessing.Image {
    public var unrotate: Unrotate {
        Unrotate(path: path + "/unrotate")
    }

    public struct Unrotate {
        /// Path: `/ocr/preprocessing/image/unrotate`
        public let path: String

        /// Detect and unrotate a document image
        ///
        /// Detect and unrotate an image of a document (e.g. that was scanned at an angle).  Great for document scanning applications; once unskewed, this image is perfect for converting to PDF using the Convert API or optical character recognition using the OCR API.
        public func post(_ body: Data) -> Request<String> {
            .post(path, body: body)
        }
    }
}

extension Paths.Preprocessing.Image.Unrotate {
    public var advanced: Advanced {
        Advanced(path: path + "/advanced")
    }

    public struct Advanced {
        /// Path: `/ocr/preprocessing/image/unrotate/advanced`
        public let path: String

        /// Detect and unrotate a document image (advanced)
        ///
        /// Detect and unrotate an image of a document (e.g. that was scanned at an angle) using deep learning.  Great for document scanning applications; once unskewed, this image is perfect for converting to PDF using the Convert API or optical character recognition using the OCR API.
        public func post(_ body: Data) -> Request<String> {
            .post(path, body: body)
        }
    }
}

extension Paths.Preprocessing.Image {
    public var unskew: Unskew {
        Unskew(path: path + "/unskew")
    }

    public struct Unskew {
        /// Path: `/ocr/preprocessing/image/unskew`
        public let path: String

        /// Detect and unskew a photo of a document
        ///
        /// Detect and unskew a photo of a document (e.g. taken on a cell phone) into a perfectly square image.  Great for document scanning applications; once unskewed, this image is perfect for converting to PDF using the Convert API or optical character recognition using the OCR API.
        public func post(_ body: Data) -> Request<String> {
            .post(path, body: body)
        }
    }
}

extension Paths {
    public static var receipts: Receipts {
        Receipts(path: "/ocr/receipts")
    }

    public struct Receipts {
        /// Path: `/ocr/receipts`
        public let path: String
    }
}

extension Paths.Receipts {
    public var photo: Photo {
        Photo(path: path + "/photo")
    }

    public struct Photo {
        /// Path: `/ocr/receipts/photo`
        public let path: String
    }
}

extension Paths.Receipts.Photo {
    public var to: To {
        To(path: path + "/to")
    }

    public struct To {
        /// Path: `/ocr/receipts/photo/to`
        public let path: String
    }
}

extension Paths.Receipts.Photo.To {
    public var csv: Csv {
        Csv(path: path + "/csv")
    }

    public struct Csv {
        /// Path: `/ocr/receipts/photo/to/csv`
        public let path: String

        /// Convert a photo of a receipt into a CSV file containing structured information from the receipt
        ///
        /// Leverage Deep Learning to automatically turn a photo of a receipt into a CSV file containing the structured information from the receipt.
        @available(*, deprecated, message: "Deprecated")
        public func post(_ body: Data) -> Request<[String: AnyJSON]> {
            .post(path, body: body)
        }
    }
}

public enum Paths {}