class USkylineBossWaitForBikesToLandCapability : USkylineBossChildCapability
{
	float BikeInRampTimeStamp = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.HalfPipeJumpComponent.AreGravityBikesJumping())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Boss.HalfPipeJumpComponent.AreGravityBikesJumping())
			BikeInRampTimeStamp = Time::GameTimeSeconds;
	}
};