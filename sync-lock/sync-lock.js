var mysql = require('mysql')
var debug = false;

const createStatement = 'CREATE TABLE IF NOT EXISTS `lock_status` (`key` VARCHAR(200) NOT NULL, `status` int(1) NOT NULL, PRIMARY KEY (`key`))';
const insertStatement = 'INSERT INTO lock_status(`key`, `status`) VALUES (?, ?);';
const updateStatement = 'UPDATE lock_status SET status = ? WHERE `key` = ?';
const selectStmt = 'SELECT `status` FROM `lock_status` WHERE `key` = ? FOR UPDATE';
const lockStmt = 'LOCK TABLES `lock_status` WRITE';
const unlockStmt = 'UNLOCK TABLES;';

function getConnection() {
    var connection = mysql.createConnection({
        host: 'localhost',
        user: 'mysql',
        password: 'mysql',
        database: 'lock_db'
    });
    return connection;
}

const execute = function (sql) {
    return new Promise((resolve, reject) => {
        var connection = getConnection();
        connection.connect(function (err) {
            if (err) reject(err);

            if (debug) console.log('Executing statement: ' + sql);
            connection.query(sql, function (err, result) {
                if (err) reject(err);

                if (debug) console.log('Statement executed successfully!');
                connection.end();
                resolve(result);
            });
        });
    });
}

const executeWithParams = function (sql, params) {
    return new Promise((resolve, reject) => {
        var connection = getConnection();
        connection.connect(function (err) {
            if (err) reject(err);

            if (debug) console.log('Executing statement: ' + sql);
            connection.query(sql, params, function (err, result) {
                if (err) reject(err);

                if (debug) console.log('Statement executed successfully!');
                connection.end();
                resolve(result);
            });
        });
    });
}

async function main(key, value) {
    try {
        console.log('Acquiring lock...');
        await Promise.resolve(execute(lockStmt));
        console.log('Lock acquired');
    } catch (err) {
        console.log('Error: ' + err);
        return;
    }

    try {
        // Create table if not exists
        await Promise.resolve(execute(createStatement));
    } catch (err) {
        console.log('Error: ' + err);
        return;
    }

    try {
        var result = await Promise.resolve(executeWithParams(selectStmt, [key]));
        if (result.length > 0) {
            try {
                // Existing record found, update
                var params = [value, key];
                await executeWithParams(updateStatement, params);
                console.log('Record updated [' + key + '] = ' + value);
            } catch (err) {
                console.log('Error: ' + err);
                return;
            }
        } else {
            try {
                // No record found, insert
                var params = [key, value];
                await executeWithParams(insertStatement, params);
                console.log('Record added [' + key + '] = ' + value);
            } catch (err) {
                console.log('Error: ' + err);
                return;
            }
        }
    } catch (err) {
        console.log('Error: ' + err);
        return;
    } finally {
        await Promise.resolve(execute(unlockStmt));
        console.log('Lock released');
    }
}

if(process.argv.length != 4) {
    console.log('Usage sync-lock [key] [value]');
    process.exit();
}
main(process.argv[2], process.argv[3]);