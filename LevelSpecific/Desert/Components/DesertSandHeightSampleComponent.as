class UDesertSandHeightSampleComponent : UBillboardComponent
{
	UPROPERTY(EditAnywhere)
	ESandSharkLandscapeLevel LandscapeLevel;

	UPROPERTY(EditAnywhere)
	float Priority = 1;

	private float CachedSandHeight = 0;
	private uint CachedSandHeightFrame = 0;

	UFUNCTION(BlueprintPure)
	float GetSandHeight()
	{
		if(CachedSandHeightFrame != Time::FrameNumber)
		{
			CachedSandHeight = Desert::GetLandscapeHeightByLevel(WorldLocation, LandscapeLevel);
			CachedSandHeightFrame = Time::FrameNumber;
		}

		return CachedSandHeight;
	}
};