const path = require('path')
const { generateWebpackConfig, merge } = require('shakapacker')
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
const { VueLoaderPlugin } = require('vue-loader')

const configs = generateWebpackConfig({
  resolve: {
    extensions: ['.css', '.scss', '.vue', '.js', '.jsx', '.png', '.jpg', '.jpeg', '.gif', '.svg'],
    alias: {
      '@': path.resolve(__dirname, '../../app/javascript'),
      images: path.resolve(__dirname, '../../app/javascript/images')
    }
  },
  performance: {
    maxEntrypointSize: 0
  },
  optimization: {
    runtimeChunk: false,
    concatenateModules: !process.env.BUNDLE_ANALYZE,
    splitChunks: {
      chunks(chunk) {
        return chunk.name !== 'rollbar'
      },
      cacheGroups: {
        default: false,
        applicationVendors: {
          test: /\/node_modules\//,
          chunks: chunk => chunk.name === 'application'
        },
        drawVendors: {
          test: /\/node_modules\//,
          chunks: chunk => chunk.name === 'draw'
        },
        formVendors: {
          test: /\/node_modules\//,
          chunks: chunk => chunk.name === 'form'
        }
      }
    }
  },
  plugins: [
    process.env.BUNDLE_ANALYZE && new BundleAnalyzerPlugin(),
    new VueLoaderPlugin()
  ].filter(Boolean)
})

// Add module rules
configs.module = merge({
  rules: [
    {
      test: /\.vue$/,
      use: [{
        loader: 'vue-loader',
        options: {
          compilerOptions: {
            isCustomElement: tag => tag.includes('-')
          }
        }
      }]
    },
    {
      test: /\.(png|jpg|jpeg|gif|svg|ico)$/i,
      type: 'asset/resource',
      generator: {
        filename: 'images/[name][ext]'
      }
    }
  ]
}, configs.module)

module.exports = configs