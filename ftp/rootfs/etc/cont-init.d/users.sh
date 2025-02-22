#!/usr/bin/with-contenv bashio
# ==============================================================================
# Community Hass.io Add-ons: FTP
# Configures vsftpd
# ==============================================================================
declare username
declare password

for user in $(bashio::config 'users|keys'); do
    username=$(bashio::config "users[${user}].username")

    mkdir -p "/ftproot/users/${username}"
    touch "/etc/vsftpd/users/${username}"

    for dir in "addons" "backup" "config" "share" "ssl"; do
        if bashio::config.true "users[${user}].${dir}"; then
            mkdir "/ftproot/users/${username}/${dir}"
            mount --bind "/${dir}" "/ftproot/users/${username}/${dir}"
        fi
    done

    if bashio::config.true "users[${user}].allow_chmod"; then
        echo 'chmod_enable=YES' >> "/etc/vsftpd/users/${username}"
    fi

    if bashio::config.true "users[${user}].allow_download"; then
        echo 'download_enable=YES' >> "/etc/vsftpd/users/${username}"
    fi

    if bashio::config.true "users[${user}].allow_upload"; then
        echo 'write_enable=YES' >> "/etc/vsftpd/users/${username}"
    fi

    if bashio::config.true "users[${user}].allow_dirlist"; then
        echo 'dirlist_enable=YES' >> "/etc/vsftpd/users/${username}"
    fi

    # Require a secure password
    if bashio::config.has_value "users[${user}].password" \
        && ! bashio::config.true 'i_like_to_be_pwned'; then
        bashio::config.require.safe_password "users[${user}].password"
    fi

    password=$(bashio::config "users[${user}].password" | openssl passwd -1 -stdin)
    echo "${username}:${password}" >> /etc/vsftpd/passwd
done
