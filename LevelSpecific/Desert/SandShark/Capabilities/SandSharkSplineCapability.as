class USandSharkSplineCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkSpline);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 500;

	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;

	FVector CurrentSplinePoint;
	FVector TargetSplinePoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SandShark.AnimationSpline = FHazeRuntimeSpline();
		SandShark.AnimationSpline.AddPointWithUpDirection(SandShark.ActorLocation - SandShark.ActorForwardVector * 500, SandShark.ActorUpVector);
		SandShark.AnimationSpline.AddPointWithUpDirection(SandShark.ActorLocation - SandShark.ActorForwardVector * 250, SandShark.ActorUpVector);
		SandShark.AnimationSpline.AddPointWithUpDirection(SandShark.ActorLocation, SandShark.ActorUpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SandShark.AnimationSpline = FHazeRuntimeSpline();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Location = SandShark.SharkRoot.WorldLocation;

		auto NumPoints = SandShark.AnimationSpline.Points.Num();
		if (NumPoints < 3 || SandShark.AnimationSpline.Points[NumPoints - 2].Distance(Location) > 50)
		{
			SandShark.AnimationSpline.AddPoint(Location);
			while (SandShark.AnimationSpline.Length > 1000)
				SandShark.AnimationSpline.RemovePoint(0);
		}
		else
		{
			SandShark.AnimationSpline.SetPoint(Location, NumPoints - 1);
		}

		CurrentSplinePoint = Location;
	}
};