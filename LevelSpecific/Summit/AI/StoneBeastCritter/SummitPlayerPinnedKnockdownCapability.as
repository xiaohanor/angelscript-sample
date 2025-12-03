class USummitStoneBeastCritterPlayerPinnedKnockdownCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Knockdown");
	default CapabilityTags.Add(n"HitReaction");
	default CapabilityTags.Add(n"BlockedByCutscene");

	default DebugCategory = n"Hitreaction";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 40;

	UPlayerKnockdownComponent KnockdownComp;	
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	FHazeAcceleratedRotator AccRot;
	FKnockdown Knockdown;
	UPlayerRespawnComponent RespawnComp;
	UHazeCharacterSkeletalMeshComponent MeshComp;
	FRotator TargetRotation;
	FVector LocalKnockedMove;
	FVector AccumulatedKnockedMove;
	ULocomotionFeatureKnockDown CurrentFeature;
	float StartKnockdownDuration;
	float MaxStartVelocity;
	FHazeMoveRatioSettings MoveRatioSettings; 
	default MoveRatioSettings.YAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferXThenYZ;
	AHazePlayerCharacter PlayerOwner;

	USummitStoneBeastCritterAttackManagerComponent AttackManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		KnockdownComp = UPlayerKnockdownComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		RespawnComp = UPlayerRespawnComponent::Get(Owner);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");
		MeshComp = Cast<AHazeCharacter>(Owner).Mesh;
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		AttackManager = SummitStoneBeastCritter::GetManager(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		// Reset any knockdown when we return to life
		KnockdownComp.ConsumeKnockdown(Knockdown);
	}

	UFUNCTION(Blueprintoverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!KnockdownComp.HasKnockdown())
			return false;
		if (!AttackManager.HasAttackHit())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;		
		if (!AttackManager.HasAttackHit())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		KnockdownComp.ConsumeKnockdown(Knockdown);
		Owner.SetActorVelocity(Owner.ActorVelocity + Knockdown.Move);
		AccRot.SnapTo(Owner.ActorRotation);
		
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		
		PlayerOwner.CapsuleComponent.ApplyCollisionProfile(n"PlayerCharacterKnockedDown", this);
		//UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Owner);
		//PlayerHealthComp.AddDamageInvulnerability(this, Knockdown.Duration);

		EHazeCardinalDirection Direction = CardinalDirectionForActor(Owner, Knockdown.Move);
		TargetRotation = Knockdown.Move.Rotation();
		if (Direction == EHazeCardinalDirection::Backward)
			TargetRotation.Yaw += 180.0;
		else if (Direction == EHazeCardinalDirection::Left)
			TargetRotation.Yaw += 90.0;
		else if (Direction == EHazeCardinalDirection::Right)
			TargetRotation.Yaw -= 90.0;

		LocalKnockedMove = TargetRotation.GetInverse().RotateVector(Knockdown.Move);
		AccumulatedKnockedMove = FVector::ZeroVector;

		CurrentFeature = Cast<ULocomotionFeatureKnockDown>(MeshComp.GetFeatureByTag(Knockdown.FeatureTag));
		UPlayerMovementComponent MoveComponent = UPlayerMovementComponent::Get(Owner);
		float DefaultAnimDuration = CurrentFeature.AnimData.GetStartDuration(Direction, MoveComponent.IsInAir());
		StartKnockdownDuration = Math::Min(DefaultAnimDuration, Math::Max(Knockdown.Duration - Knockdown.StandUpDuration, DefaultAnimDuration * 0.5));

		MaxStartVelocity = (Knockdown.Move.Size() / StartKnockdownDuration) * 2.0; // Safety margin for large animation velocities

		KnockdownComp.AnimData.Direction = Direction;
		KnockdownComp.AnimData.StartKnockdownDuration = StartKnockdownDuration;
		KnockdownComp.AnimData.StandUpDuration = Knockdown.StandUpDuration;
		KnockdownComp.AnimData.bStandUp = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		KnockdownComp.AnimData.bStandUp = true;
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		PlayerOwner.CapsuleComponent.ClearCollisionProfile(this);

		// Remove any deprecated knockdowns. If we want knockdowns while standing up etc we should fix so we can retrigger them immediately instead. 
		KnockdownComp.ClearOldKnockdowns(0.3);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl() && DeltaTime > 0)
			{
				if (ActiveDuration < StartKnockdownDuration)
				{
					// Extract move ratio delta
					FVector LocalDelta = FVector::ZeroVector;
					TArray<FHazePlayingAnimationData> Animations;
					MeshComp.GetCurrentlyPlayingAnimations(Animations);
					for (const FHazePlayingAnimationData& AnimData : Animations)
					{	
						// We only want anim movement from the initial knocked down sequence
						if (CurrentFeature.AnimData.IsStartSequence(AnimData.Sequence))
							LocalDelta = AnimData.Sequence.GetDeltaMoveForMoveRatio(AccumulatedKnockedMove, ActiveDuration, LocalKnockedMove, StartKnockdownDuration);
					}	

					FVector WorldDelta = TargetRotation.RotateVector(LocalDelta);
					FVector CustomVelocity = (WorldDelta / DeltaTime).GetClampedToMaxSize(MaxStartVelocity);
					Movement.AddDeltaWithCustomVelocity(WorldDelta, CustomVelocity);
				}
				else
				{
					// Slide to a stop 
					FVector Velocity = MoveComp.Velocity;
					Velocity -= Velocity * Knockdown.PostKnockedFriction * DeltaTime; 
					Movement.AddVelocity(Velocity);
				}

				Movement.OverrideStepDownAmountForThisFrame(0.0); 
				Movement.AddGravityAcceleration();

				AccRot.AccelerateTo(TargetRotation, 0.5, DeltaTime);
				Movement.SetRotation(AccRot.Value);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, Knockdown.FeatureTag);
		}

		if (ActiveDuration > Knockdown.Duration - Knockdown.StandUpDuration)
			KnockdownComp.AnimData.bStandUp = true;
	}
}

// No animations in this sheet, so mostly useful for testing purposes 
asset BaseSummitStoneBeastCritterPlayerPinnedKnockdownSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USummitStoneBeastCritterPlayerPinnedKnockdownCapability);
	Components.Add(UPlayerKnockdownComponent);
}
