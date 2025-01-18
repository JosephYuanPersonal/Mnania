// 引入必要的依赖
const path = require('path');

module.exports = {
    entry: "./src/mnania.res.js",
    output: {
        filename: "mnania.js",
        path: path.resolve(__dirname, "dist"),
        library: {
            name: 'Mnania',
            type: 'umd'
        },
        globalObject: 'this'
    },
    resolve: {
        fallback: {
            "path": require.resolve("path-browserify")
        }
    },
    module: {
        rules: [
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader']
            }
        ]
    },
    externals: {
        'jquery': 'jQuery'
    }
}; 