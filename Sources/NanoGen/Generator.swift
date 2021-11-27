// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import OpenAPIKit

struct Generator {
    let spec: OpenAPI.Document
    
    init(spec: OpenAPI.Document) {
        self.spec = spec
    }
    
    func generate() {
        // TODO: Group by path
    }
}
