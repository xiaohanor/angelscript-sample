class UEvergreenBarrelEnterCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 1;

	UPlayerMovementComponent MoveComp;
	UEvergreenBarrelPlayerComponent BarrelPlayerComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTeleportingMovementData Movement;
	FTransform OriginalTransform;
	FVector PreviousPlayerLocation;
	bool bMoveDone = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
		BarrelPlayerComp = UEvergreenBarrelPlayerComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FEvergreenBarrelActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(CurrentBarrel != nullptr)
			return false;

		AEvergreenBarrel BarrelToEnter;
		TListedActors<AEvergreenBarrel> ListedBarrels;
		for(AEvergreenBarrel Barrel : ListedBarrels.Array)
		{
			if(BarrelPlayerComp.BarrelToBlock == Barrel)
				continue;

			if(Barrel.ShouldPlayerEnterBarrel())
			{
				BarrelToEnter = Barrel;
				continue;
			}
		}

		if(BarrelToEnter == nullptr)
			return false;

		Params.CurrentBarrel = BarrelToEnter;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FEvergreenBarrelActivatedParams Params)
	{
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
		BarrelPlayerComp.StartEnterBarrel(Params.CurrentBarrel);
		CurrentBarrel.OnStartEnteringBarrel(Player);
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, true);

		// Because of tick order shapeshifting component is created later than this barrel so we can't cache the reference in BeginPlay
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftingComp.AddShapeTypeBlocker(ETundraShapeshiftShape::Player, this);
		OriginalTransform = Player.ActorTransform;
		bMoveDone = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		ShapeshiftingComp.RemoveShapeTypeBlockerInstigator(this);

		if(IsBlocked())
		{
			BarrelPlayerComp.ExitBarrel();
		}
		else
		{
			BarrelPlayerComp.FullyEnterBarrel();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				const float Alpha = Math::Saturate(ActiveDuration / CurrentBarrel.EnterDuration);
				FVector TargetLocation = SkeletalMesh.WorldLocation - SkeletalMesh.UpVector * (TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 0.5);
				FVector CurrentLocation = Math::Lerp(OriginalTransform.Location, TargetLocation, Alpha);
				FRotator CurrentRotation = Math::LerpShortestPath(OriginalTransform.Rotator(), SkeletalMesh.WorldRotation, Alpha);
				
				Movement.AddDelta(CurrentLocation - Player.ActorLocation);
				Movement.SetRotation(CurrentRotation);

				if(Alpha == 1.0)
					bMoveDone = true;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}

	AEvergreenBarrel GetCurrentBarrel() const property
	{
		return BarrelPlayerComp.CurrentBarrel;
	}

	UHazeSkeletalMeshComponentBase GetSkeletalMesh() property
	{
		return CurrentBarrel.SkeletalMesh;
	}
}

struct FEvergreenBarrelActivatedParams
{
	AEvergreenBarrel CurrentBarrel;
}