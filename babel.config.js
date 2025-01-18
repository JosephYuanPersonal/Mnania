module.exports = {
    presets: [
        [
            '@babel/preset-env',
            {
                targets: {
                    browsers: ['last 2 versions']
                },
                useBuiltIns: 'usage',
                corejs: 3
            }
        ]
    ]
}; 