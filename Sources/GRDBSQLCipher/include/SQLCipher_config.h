#ifndef grdb_config_h
#define grdb_config_h

#include <SQLCipher/sqlite3.h>

typedef void(*_errorLogCallback)(void *pArg, int iErrCode, const char *zMsg);

static inline void _registerErrorLogCallback(_errorLogCallback callback) {
    sqlite3_config(SQLITE_CONFIG_LOG, callback, 0);
}

#if SQLITE_VERSION_NUMBER >= 3029000
static inline void _disableDoubleQuotedStringLiterals(sqlite3 *db) {
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DDL, 0, (void *)0);
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DML, 0, (void *)0);
}

static inline void _enableDoubleQuotedStringLiterals(sqlite3 *db) {
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DDL, 1, (void *)0);
    sqlite3_db_config(db, SQLITE_DBCONFIG_DQS_DML, 1, (void *)0);
}
#else
static inline void _disableDoubleQuotedStringLiterals(sqlite3 *db) { }
static inline void _enableDoubleQuotedStringLiterals(sqlite3 *db) { }
#endif
#endif
