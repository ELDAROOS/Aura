import Foundation
import SQLite3

class RawSQLService {
    static let shared = RawSQLService()
    
    private var db: OpaquePointer?
    
    func connect(to dbPath: String) -> Bool {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            return true
        } else {
            print("DEBUG: ERROR - Could not open database at \(dbPath)")
            return false
        }
    }
    
    func executeQuery(_ sql: String) -> [[String: String]] {
        var results: [[String: String]] = []
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            let columnCount = sqlite3_column_count(statement)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: String] = [:]
                for i in 0..<columnCount {
                    let name = String(cString: sqlite3_column_name(statement, i))
                    let value: String
                    
                    switch sqlite3_column_type(statement, i) {
                    case SQLITE_INTEGER:
                        value = "\(sqlite3_column_int64(statement, i))"
                    case SQLITE_FLOAT:
                        value = "\(sqlite3_column_double(statement, i))"
                    case SQLITE_TEXT:
                        value = String(cString: sqlite3_column_text(statement, i))
                    case SQLITE_BLOB:
                        value = "[BLOB Data]"
                    case SQLITE_NULL:
                        value = "NULL"
                    default:
                        value = "Unknown"
                    }
                    row[name] = value
                }
                results.append(row)
            }
        } else {
            let error = String(cString: sqlite3_errmsg(db))
            print("DEBUG: SQL ERROR - \(error)")
            return [["Error": error]]
        }
        
        sqlite3_finalize(statement)
        return results
    }
    
    func executeNonQuery(_ sql: String) -> String {
        var errMsg: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) == SQLITE_OK {
            return "Success: Rows affected \(sqlite3_changes(db))"
        } else {
            let error = String(cString: errMsg!)
            sqlite3_free(errMsg)
            return "Error: \(error)"
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
}
