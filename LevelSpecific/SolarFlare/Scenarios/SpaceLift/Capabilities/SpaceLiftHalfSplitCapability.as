class USpaceLiftHalfSplitCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SpaceLiftHalfSplitCapability");
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	ASolarFlareSpaceLiftMain SpaceLift;
	float LastOffset;
	float Distance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceLift = Cast<ASolarFlareSpaceLiftMain>(Owner);
		LastOffset = SpaceLift.TargetSplitOffsetY;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (LastOffset == SpaceLift.TargetSplitOffsetY)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Distance < 0.5)
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
		LastOffset = SpaceLift.TargetSplitOffsetY;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector LeftLocation =  FVector(0.0, SpaceLift.TargetSplitOffsetY, 0.0);
		FVector RightLocation =  FVector(0.0, -SpaceLift.TargetSplitOffsetY, 0.0);
		SpaceLift.LeftRoot.RelativeLocation = Math::VInterpConstantTo(SpaceLift.LeftRoot.RelativeLocation, LeftLocation, DeltaTime, SpaceLift.TargetSplitOffsetY);
		SpaceLift.RightRoot.RelativeLocation = Math::VInterpConstantTo(SpaceLift.RightRoot.RelativeLocation, RightLocation, DeltaTime, SpaceLift.TargetSplitOffsetY);

		Distance = (SpaceLift.RightRoot.RelativeLocation - RightLocation).Size();	
	}
}