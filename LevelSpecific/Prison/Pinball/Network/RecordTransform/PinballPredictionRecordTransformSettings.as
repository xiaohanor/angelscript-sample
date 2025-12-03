namespace Pinball::Prediction::RecordTransform
{
	// 20 per second should suffice
	const int SamplesPerSecond = 20;

	float GetBufferDuration()
	{
		return ::Network::PingRoundtripSeconds * 2;
	}
}