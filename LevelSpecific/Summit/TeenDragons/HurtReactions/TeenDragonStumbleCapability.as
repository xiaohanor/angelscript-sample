class UTeenDragonStumbleCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Stumble");

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 60;

	//ATeenDragon TeenDragon;
	//AHazePlayerCharacter Player;	

	FTeenDragonStumble Stumble;
	UPlayerTeenDragonComponent DragonComp;
	UTeenDragonStumbleComponent StumbleComp;
	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;
	FHazeAcceleratedRotator AccRot;
	UHazeCharacterSkeletalMeshComponent MeshComp;
	FRotator TargetRotation;
	FVector LocalStumble;
	FVector AccumulatedStumble;
	FHazeMoveRatioSettings MoveRatioSettings; 
	default MoveRatioSettings.YAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferXThenYZ;

	float CurrentArcHeight = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//TeenDragon = Cast<ATeenDragon>(Owner);
		//Player = TeenDragon.Player;
		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");
		MoveComp = UHazeMovementComponent::Get(Player);
		StumbleComp = UTeenDragonStumbleComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		MeshComp = DragonComp.DragonMesh;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		// Reset any Stumble when we return to life
		StumbleComp.ConsumeStumble(Stumble);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!StumbleComp.HasStumble())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > Stumble.Duration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StumbleComp.ConsumeStumble(Stumble);

		AccRot.SnapTo(Owner.ActorRotation);
		
		EHazeCardinalDirection Direction = CardinalDirectionForActor(Owner, Stumble.Move);
		TargetRotation = Stumble.Move.Rotation();

		// HACK: Currently we only have a backward stumble, so rotate towards inverse stumble direction
		TargetRotation.Yaw += 180.0;
		// if (Direction == EHazeCardinalDirection::Backward)
		// 	TargetRotation.Yaw += 180.0;
		// else if (Direction == EHazeCardinalDirection::Left)
		// 	TargetRotation.Yaw += 90.0;
		// else if (Direction == EHazeCardinalDirection::Right)
		// 	TargetRotation.Yaw -= 90.0;

		FRotator InverseTargetRotation = TargetRotation.GetInverse();
		LocalStumble = InverseTargetRotation.RotateVector(Stumble.Move);
		AccumulatedStumble = FVector::ZeroVector;

		StumbleComp.AnimData.Direction = Direction;
		StumbleComp.AnimData.Duration = Stumble.Duration;

		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);

		CurrentArcHeight = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		// Remove any deprecated stumbles. If we want reoccurring stumbles we should fix so we can retrigger them immediately instead. 
		StumbleComp.ClearOldStumbles(0.3);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StumbleComp.LastStumbleTime = Time::GameTimeSeconds;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// Extract move ratio delta
				if (DeltaTime > 0.0)
				{
					FVector LocalDelta = FVector::ZeroVector;
					TArray<FHazePlayingAnimationData> Animations;
					MeshComp.GetCurrentlyPlayingAnimations(Animations);
					for (const FHazePlayingAnimationData& AnimData : Animations)
					{	
						LocalDelta += AnimData.Sequence.GetDeltaMoveForMoveRatio(AccumulatedStumble, ActiveDuration, LocalStumble, Stumble.Duration);
					}	

					FVector WorldDelta = TargetRotation.RotateVector(LocalDelta);
					Movement.AddDelta(WorldDelta);
					if (Stumble.ArcHeight == 0.0)
					{
						Movement.AddGravityAcceleration();
					}
					else
					{
						float Alpha = ActiveDuration / Stumble.Duration; // 0..1, use -1..1 in next line to get a ballistic trajectory without friction
						float NewArcHeight = Math::Sqrt(1.0 - Math::Square((Alpha - 0.5) * 2.0)) * Stumble.ArcHeight; 
						FVector ArcDelta = Owner.ActorUpVector * (NewArcHeight - CurrentArcHeight);
						Movement.AddDelta(ArcDelta);
						CurrentArcHeight = NewArcHeight;
					}

					AccRot.AccelerateTo(TargetRotation, 0.5, DeltaTime);
					Movement.SetRotation(AccRot.Value);
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(Stumble.FeatureTag);
		}
	}
};

// No animations in this sheet, so mostly useful for testing purposes 
asset BaseTeenDragonStumbleSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UTeenDragonStumbleCapability);
	Components.Add(UTeenDragonStumbleComponent);
}