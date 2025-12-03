class UVillageCanalGetSuckedIntoPipeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UVillageCanalExitPlayerComponent ExitComp;

	float SplineDist = 0.0;
	bool bReachedEnd = false;

	float SuckDuration = 1.5;
	float SuckAlpha = 0.0;

	FHazeRuntimeSpline FollowSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ExitComp = UVillageCanalExitPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ExitComp.SuckedIntoPipeTarget == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ExitComp.SuckedIntoPipeTarget == nullptr)
			return true;

		if (bReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		TArray<FVector> Points;
		Points.Add(Player.ActorLocation);
		Points.Add(ExitComp.SuckedIntoPipeTarget.ActorLocation - (FVector::UpVector * 400.0));
		Points.Add(ExitComp.SuckedIntoPipeTarget.ActorLocation);

		FollowSpline.Points = Points;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ResetMovement();
		Player.SetActorVelocity(FVector(0.0, 0.0, -2500.0));
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		ExitComp.SuckedIntoPipeTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"AirMovement", this);

		SuckAlpha = Curve::EaseInCurveZeroToOne.GetFloatValue( Math::Saturate(ActiveDuration/SuckDuration));
		PrintToScreen("" + SuckAlpha);

		FVector Loc = FollowSpline.GetLocation(SuckAlpha);
		FRotator TargetRot = FollowSpline.GetRotation(SuckAlpha);
		FRotator Rot = Math::RInterpTo(Player.ActorRotation, TargetRot, DeltaTime, 2.0);
		Player.SetActorLocationAndRotation(Loc, Rot);

		if (SuckAlpha >= 1.0)
			bReachedEnd = true;
	}
}