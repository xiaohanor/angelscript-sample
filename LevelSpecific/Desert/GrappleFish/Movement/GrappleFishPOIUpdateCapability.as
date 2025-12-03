class UDesertGrappleFishPOIUpdateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Camera);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	ADesertGrappleFish GrappleFish;
	float LastTurnDirection = 1;

	FVector POIOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleFish = Cast<ADesertGrappleFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return true;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
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
		FVector ForwardOffset = GrappleFish.ActorForwardVector * GrappleFishPOI::POIForwardOffset;
		float SideAlpha = Math::GetMappedRangeValueClamped(FVector2D(-GrappleFishMovement::MaxTurnSpeedDeg, GrappleFishMovement::MaxTurnSpeedDeg), FVector2D(-1, 1), GrappleFish.AccTurnSpeed.Value);
		FVector SideOffset = GrappleFish.ActorRightVector * GrappleFishPOI::POISideOffset * SideAlpha;
		POIOffset = Math::VInterpConstantTo(POIOffset, SideOffset, DeltaTime, GrappleFishPOI::POISideInterpSpeed);
		//AccPOIOffset.AccelerateTo(ForwardOffset + SideOffset, GrappleFishPOI::POIAccelerateDuration, DeltaTime);
		FVector PoILoc = GrappleFish.ActorLocation + ForwardOffset + POIOffset;
		GrappleFish.POITarget.SetWorldLocation(PoILoc);

		// Debug::DrawDebugSphere(PoILoc, 200.0, 12, FLinearColor::Red, 10.0);
	}
};