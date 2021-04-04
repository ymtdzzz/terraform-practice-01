import type { AWS } from '@serverless/typescript';

// Terraform vars
// app_name: terraform-practice

const serverlessConfiguration: AWS = {
  service: "${self:custom.appName}",
  frameworkVersion: '2',
  custom: {
    appName: 'terraform-practice',
    defaultStage: 'dev',
    webpack: {
      webpackConfig: './webpack.config.js',
      includeModules: true
    },
    s3Sync: [
      {
        bucketName: "${ssm:/${self:custom.appName}/${self:provider.stage}/bucket_name}",
        localDir: '../laravel/public/',
        deleteRemoved: true,
      }
    ]
  },
  // Add the serverless-webpack plugin
  plugins: [
    'serverless-webpack',
    'serverless-offline',
    'serverless-s3-sync'
  ],
  provider: {
    name: 'aws',
    region: 'us-east-1',
    runtime: 'nodejs12.x',
    apiGateway: {
      minimumCompressionSize: 1024,
    },
    stage: "${opt:stage, self:custom.defaultStage}",
    environment: {
      AWS_NODEJS_CONNECTION_REUSE_ENABLED: '1',
      REGION: 'us-east-1',
      SQS_QUEUE_URL: "${ssm:/${self:custom.appName}/${self:provider.stage}/sample_queue_url}",
    },
    iamRoleStatements: [
      {
        Effect: 'Allow',
        Action: ['sqs:SendMessage'],
        Resource: ["${ssm:/${self:custom.appName}/${self:provider.stage}/sample_queue_arn}"]
      }
    ]
  },
  functions: {
    hello: {
      handler: 'handler.hello',
      events: [
        {
          http: {
            method: 'get',
            path: 'hello',
          }
        }
      ]
    }
  }
}

module.exports = serverlessConfiguration;
