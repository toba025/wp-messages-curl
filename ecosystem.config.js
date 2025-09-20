module.exports = {
  apps: [{
    name: 'whatsapp-bot',
    script: 'server.js',
    cwd: '/home/ubuntu/wp-messages-curl',
    env: {
      NODE_ENV: 'production',
      DISPLAY: ':99'
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    kill_timeout: 5000,
    wait_ready: true,
    listen_timeout: 10000,
    restart_delay: 4000
  }]
};
