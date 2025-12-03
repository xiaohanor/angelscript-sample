namespace Pinball::Rail
{
	/**
	 * How long to wait at a sync point
	 * This should match the timelike in EBP_Pinball_Rail
	 */
	const float SyncPointDelay = 0.5;

	float GetSyncPointTimeOutDuration()
	{
		return (SyncPointDelay * 2) + (::Network::PingRoundtripSeconds * 2);
	}
}