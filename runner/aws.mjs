// In-sandbox AWS helper. Credentials come from the AgentCore execution role (IMDS).
//   node aws.mjs put <key> <file>        upload a file under the run prefix
//   node aws.mjs get <key|s3-uri> <file|->  download an object (streamed; '-' = stdout)
//   node aws.mjs stop                    stop this runtime session (releases the sandbox)
// Configuration is read from the environment written by the client at submit time.
import fs from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { BedrockAgentCoreClient, StopRuntimeSessionCommand } from '@aws-sdk/client-bedrock-agentcore';

const env = process.env;
const [, , cmd, a, b] = process.argv;
const s3 = new S3Client({ region: env.BENCH_S3_REGION });

if (cmd === 'put') {
  await s3.send(new PutObjectCommand({ Bucket: env.BENCH_BUCKET, Key: a, Body: fs.readFileSync(b) }));
} else if (cmd === 'get') {
  const m = a.match(/^s3:\/\/([^/]+)\/(.+)$/);
  const [Bucket, Key] = m ? [m[1], m[2]] : [env.BENCH_BUCKET, a];
  const r = await s3.send(new GetObjectCommand({ Bucket, Key }));
  await pipeline(r.Body, b === '-' ? process.stdout : fs.createWriteStream(b));
} else if (cmd === 'stop') {
  const ac = new BedrockAgentCoreClient({ region: env.BENCH_REGION });
  await ac.send(new StopRuntimeSessionCommand({
    agentRuntimeArn: env.BENCH_RUNTIME_ARN, runtimeSessionId: env.BENCH_SESSION_ID, qualifier: 'DEFAULT',
  }));
} else {
  console.error('usage: aws.mjs put|get <key> <file> | stop');
  process.exit(2);
}
