class UDarkCaveSpiritStatueCompleteCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeSplineComponent SplineComp;
	FSplinePosition SplinePos;

	FHazeAcceleratedFloat AccelMoveSpeed;

	ADarkCaveDragonSpirit DragonSpirit;

	FVector TargetScale;
	float ScaleMultiplierTarget = 4.0;
	float ScaleSpeed = 1.7;

	TArray<ADarkCaveDragonOrnament> Ornaments;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonSpirit = Cast<ADarkCaveDragonSpirit>(Owner);
		TargetScale = DragonSpirit.SkelMesh.RelativeScale3D;
		DragonSpirit.SkelMesh.RelativeScale3D = FVector(0.05);

		Ornaments = TListedActors<ADarkCaveDragonOrnament>().GetArray();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonSpirit.bSpiritCompletedJourney)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonSpirit.bSpiritCompletedJourney)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineComp = DragonSpirit.SplineActor.Spline; 
		SplinePos = SplineComp.GetSplinePositionAtSplineDistance(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonSpirit.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("MOVING");
		
		AccelMoveSpeed.AccelerateTo(DragonSpirit.MoveSpeed, 3.0, DeltaTime);
		SplinePos.Move(AccelMoveSpeed.Value * DeltaTime);

		DragonSpirit.ActorLocation = SplinePos.WorldLocation;
		DragonSpirit.ActorRotation = SplinePos.WorldRotation.Rotator();

		DragonSpirit.SkelMesh.RelativeScale3D = Math::VInterpConstantTo(DragonSpirit.SkelMesh.RelativeScale3D, TargetScale, DeltaTime, ScaleSpeed);

		if (SplinePos.CurrentSplineDistance == SplineComp.SplineLength)
		{
			DragonSpirit.bSpiritCompletedJourney = true;
			DragonSpirit.TargetDragonOrnament.ActivateDragonOrnament();

			int Count = 0;

			for (ADarkCaveDragonOrnament Ornament : Ornaments)
			{
				if (Ornament.bIsCompleted)
					Count++;
			}

			DragonSpirit.OwningStatue.OnDarkCaveSpiritStatueCompletedJourney.Broadcast(Count >= Ornaments.Num());
		}
	}
};