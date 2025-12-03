class USteerSandFishStartFallCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AVortexSandFish SandFish;

	const float END_OF_SPLINE_THRESHOLD = 100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
			return false;

		if(SandFish.SteerDistanceAlongSpline < SandFish.SteerSpline.Spline.SplineLength - END_OF_SPLINE_THRESHOLD)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Desert::SetDesertLevelState(EDesertLevelState::Fall);
	}
};