class UTundraPlayerOtterBreakWaterSurfaceCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	UTundraPlayerOtterSwimmingComponent SwimmingComp;
	UTundraPlayerOtterComponent OtterComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwimmingComp = UTundraPlayerOtterSwimmingComponent::Get(Player);
		OtterComp = UTundraPlayerOtterComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SwimmingComp.InstigatedSwimmingActiveState.Get() == ETundraPlayerOtterSwimmingActiveState::Inactive)
			return false;
		
		FTundraPlayerOtterSwimmingSurfaceData Data;
		SwimmingComp.CheckForSurface(Player, Data);
		if(Data.DistanceToSurface < 10.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SwimmingComp.InstigatedSwimmingActiveState.Get() == ETundraPlayerOtterSwimmingActiveState::Inactive)
			return true;
		
		FTundraPlayerOtterSwimmingSurfaceData Data;
		SwimmingComp.CheckForSurface(Player, Data);
		if(Data.DistanceToSurface < 10.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTundraPlayerOtterEffectHandler::Trigger_OnBreakWaterSurface(OtterComp.OtterActor);
	}
}