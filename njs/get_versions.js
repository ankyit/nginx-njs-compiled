function main(r) {
    r.headersOut['Content-Type'] = "application/json; charset=utf-8";
    r.return(200, JSON.stringify({
        njsModuleVersion: njs.version,
        nginxVersion: r.variables.nginx_version
    }));
}

export default {main};