class USummitStoneBallFuseRegenerateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitStoneBall Ball;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitStoneBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSinceLastShotByAcid = Time::GetGameTimeSince(Ball.TimeLastHitByAcid);
		if(TimeSinceLastShotByAcid < Ball.FuseRegenerateDelay)
			return false;

		if(Ball.CurrentFuseHealth >= Ball.FuseStartHealth)
			return false;

		if(Ball.bIsExploding)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		float TimeSinceLastShotByAcid = Time::GetGameTimeSince(Ball.TimeLastHitByAcid);
		if(TimeSinceLastShotByAcid < Ball.FuseRegenerateDelay)
			return true;

		if(Ball.CurrentFuseHealth >= Ball.FuseStartHealth)
			return true;

		if(Ball.bIsExploding)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Ball.AlterFuseHealth(Ball.FuseRegenerationSpeed * DeltaTime);
	}
};