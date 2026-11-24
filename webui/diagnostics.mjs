export class DiagnosticRange {
    constructor(start, length) {
        this.start = start;
        this.length = length;
    }

    get end() {
        return this.start + this.length;
    }

    static from_to(start, end) {
        return new DiagnosticRange(start, end - start);
    }
}

export class DiagnosticError {
    constructor(message, range) {
        this.message = message;
        this.range = range;
    }
}

export class DiagnosticWarning {
    constructor(message, range) {
        this.message = message;
        this.range = range;
    }
}

export function isDiagnosticError(diagnostic) {
    return diagnostic instanceof DiagnosticError;
}

export function isDiagnosticWarning(diagnostic) {
    return diagnostic instanceof DiagnosticWarning;
}
