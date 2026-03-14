const admin = db.getSiblingDB("admin");

const log = {
    info: (message) => print(`${new Date().toISOString()} [INFO] mdb --- init: ${message}`),
    error: (message) => print(`${new Date().toISOString()} [ERROR] mdb --- init: ${message}`)
};

const users = [["MDB_COHABIT_USERNAME", "MDB_COHABIT_PASSWORD", "MDB_COHABIT_DATABASE_NAME"], ["MDB_COHABIT_AUTHSOURCE_USERNAME", "MDB_COHABIT_AUTHSOURCE_PASSWORD", "MDB_COHABIT_AUTHSOURCE_DATABASE_NAME"]];

log.info(`ENV: ${Object.keys(process.env)}`)

users.forEach(([env_username, env_password, env_db]) => {

    let user = process.env[env_username];
    let pwd = process.env[env_password];
    let _db = process.env[env_db];

    let roles = [{role: "dbAdmin", db: _db}, {role: "readWrite", db: _db}]

    if (!user){
        log.error(`${env_username} not found!`);
        return;
    }

    if (!pwd) {
        log.error(`${env_password} not found!`);
        return;
    }

    if (!_db) {
        log.error(`${env_db} not found!`);
        return;
    }

    const existing = admin.getUser(user);

    if (existing) {
        admin.updateUser(user, {pwd, roles});

        log.info(`${user}@admin updated successfully (pwd + roles)`);
    } else {
        admin.createUser({user, pwd, roles});

        log.info(`${user}@admin created successfully`);
    }
});

log.info("all users processed (created/updated)");