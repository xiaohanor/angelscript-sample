class UPlayerStumbleCapability : UHazeCapability 
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Stumble");
	default CapabilityTags.Add(n"HitReaction");
	default CapabilityTags.Add(n"BlockedByCutscene");

	default DebugCategory = n"Hitreaction";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 60;

	UPlayerStumbleComponent StumbleComp;	
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	FHazeAcceleratedRotator AccRot;
	FStumble Stumble;
	UPlayerRespawnComponent RespawnComp;
	UHazeCharacterSkeletalMeshComponent MeshComp;
	FRotator TargetRotation;
	FVector LocalMoveRatioStumble;
	FVector AccumulatedMoveRatioStumble;
	FHazeMoveRatioSettings MoveRatioSettings; 
	default MoveRatioSettings.YAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferXThenYZ;
	FVector AdditionalGroundVelocity;
	bool bWasGrounded;
	float LastEndTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StumbleComp = UPlayerStumbleComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");
		MeshComp = Cast<AHazeCharacter>(Owner).Mesh;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		// Reset any stumble when we return to life
		StumbleComp.ConsumeStumble(Stumble);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		StumbleComp.ClearCooldownStumbles(LastEndTime);
	}

	UFUNCTION(Blueprintoverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!StumbleComp.HasRecentStumble(0.1))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (ActiveDuration > Stumble.Duration)	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StumbleComp.ConsumeStumble(Stumble);
		if (Stumble.Duration < 0.1)
			Stumble.Duration = 0.1;

		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.BlockCapabilities(n"AdditiveHitReaction", this);

		AccRot.SnapTo(Owner.ActorRotation);
		
		EHazeCardinalDirection Direction = CardinalDirectionForActor(Owner, Stumble.Move);
		TargetRotation = Stumble.Move.Rotation();
		if (Direction == EHazeCardinalDirection::Backward)
			TargetRotation.Yaw += 180.0;
		else if (Direction == EHazeCardinalDirection::Left)
			TargetRotation.Yaw += 90.0;
		else if (Direction == EHazeCardinalDirection::Right)
			TargetRotation.Yaw -= 90.0;

		if (MoveComp.IsOnAnyGround() && (Stumble.Move.Z < 1.0))
		{
			bWasGrounded = true;

			// Short horizontal stumbles are made with move ratio only, longer 
			// or part vertical stumbles use both move ratio and additional velocity
			FVector UpDir = MoveComp.WorldUp;
			FVector VerticalMove = UpDir * UpDir.DotProduct(Stumble.Move);
			FVector HorizontalMove = Stumble.Move - VerticalMove;
			FVector MoveRatioTranslation = HorizontalMove.GetClampedToMaxSize(200.0);
			
			// Note that any actual move requiring additional velocity might be slightly 
			// shorter, since we want friction that slows to a stop while on ground
			AdditionalGroundVelocity = (HorizontalMove - MoveRatioTranslation) / Stumble.Duration; 

			FRotator InverseTargetRotation = TargetRotation.GetInverse();
			LocalMoveRatioStumble = InverseTargetRotation.RotateVector(MoveRatioTranslation);
			AccumulatedMoveRatioStumble = FVector::ZeroVector;

			// Sharp stop to any previous velocity
			Owner.SetActorVelocity(VerticalMove);
		}
		else 
		{
			// Stumble started in air, go ballistic
			bWasGrounded = false;
			LocalMoveRatioStumble = FVector::ZeroVector;
			AccumulatedMoveRatioStumble = FVector::ZeroVector;
			AdditionalGroundVelocity = FVector::ZeroVector;

			// We still use a sharp stop to any previous velocity, even though that is weird physics-wise. Feels better.
			Owner.SetActorVelocity(Stumble.Move / Stumble.Duration);
		}

		StumbleComp.AnimData.Direction = Direction;
		StumbleComp.AnimData.Duration = Stumble.Duration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.UnblockCapabilities(n"AdditiveHitReaction", this);

		// Remove any deprecated stumbles. If we want reoccurring stumbles we should fix so we can retrigger them immediately instead. 
		StumbleComp.ClearOldStumbles(0.3);

		// Make sure we come to a hard stop at end of stumble if on ground
		if (MoveComp.IsOnAnyGround() && (ActiveDuration > Stumble.Duration - 0.1) && !MoveComp.HasImpulse(1.0) && MoveComp.Velocity.IsNearlyZero(800.0))
			Owner.SetActorVelocity(FVector::ZeroVector);

		LastEndTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StumbleComp.LastStumbleTime = Time::GameTimeSeconds;
		
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if (bWasGrounded && !MoveComp.IsOnAnyGround())
				{
					bWasGrounded = false;
					AdditionalGroundVelocity = FVector::ZeroVector;
				}

				if (bWasGrounded)
				{
					// Still on ground, use move ratio from animation to determine movement 
					// with additional velocity to tweak vertical or long stumbles
					FVector LocalDelta = FVector::ZeroVector;
					TArray<FHazePlayingAnimationData> Animations;
					MeshComp.GetCurrentlyPlayingAnimations(Animations);
					for (const FHazePlayingAnimationData& AnimData : Animations)
					{	
						LocalDelta += AnimData.Sequence.GetDeltaMoveForMoveRatio(AccumulatedMoveRatioStumble, ActiveDuration, LocalMoveRatioStumble, Stumble.Duration);
					}	
					FVector MoveRatioDelta = TargetRotation.RotateVector(LocalDelta);

					// Friction for additional velocity while grounded so that we will brake hard at end of duration (while on ground)
					float Friction = Math::Pow(ActiveDuration / Stumble.Duration, 8.0) * 20.0; 
					AdditionalGroundVelocity *= Math::Pow(Math::Exp(-Friction), DeltaTime);					
					Movement.AddDelta(MoveRatioDelta + AdditionalGroundVelocity * DeltaTime);
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();

					// TODO: Would be nice to allow movement impulses here as well. 
				}
				else
				{
					// We're airborne, go ballistic (even if we later land) 
					FVector Velocity = MoveComp.Velocity;
					Velocity *= Math::Pow(Math::Exp(-0.1), DeltaTime);					
					Movement.AddVelocity(Velocity);
					Movement.AddGravityAcceleration();
					Movement.AddPendingImpulses();
				}

				AccRot.AccelerateTo(TargetRotation, 0.5, DeltaTime);
				Movement.SetRotation(AccRot.Value);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, Stumble.FeatureTag);
		}
	}
}

// No animations in this sheet, so mostly useful for testing purposes 
asset BasePlayerStumbleSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPlayerStumbleCapability);
	Components.Add(UPlayerStumbleComponent);
}
