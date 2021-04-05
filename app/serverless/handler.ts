import { APIGatewayProxyHandler } from 'aws-lambda';
import { config, SQS } from 'aws-sdk';

export const hello: APIGatewayProxyHandler = async (event, _context) => {
  console.log('hello function start');
  const job = 'App\\Jobs\\ProcessQueue@handle';
  const region = process.env.REGION;
  const sqs_queue_url = (process.env.IS_OFFLINE) ?
    'http://localhost:9324/queue/laravel' :
    process.env.SQS_QUEUE_URL;

  console.log(sqs_queue_url);
  
  config.update({
    region: region,
  });

  const sqs = new SQS({apiVersion: '2012-11-05'});

  const params: SQS.SendMessageRequest = {
    DelaySeconds: 10,
    MessageBody: JSON.stringify({
      job,
      'data': 'test queue message'
    }),
    QueueUrl: sqs_queue_url,
  };

  try {
    const res = await sqs.sendMessage(params).promise();
    console.log('Queue message pushing succeeded', res.MessageId);
  } catch (e) {
    console.error('Failed to push queue message', e);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Something went wrong when pushing queue message...',
        input: event,
      }, null, 2),
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Pushed sample queue message!!!!',
      input: event,
    }, null, 2),
  };
}
