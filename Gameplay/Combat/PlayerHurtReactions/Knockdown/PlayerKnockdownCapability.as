class UPlayerKnockdownCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Knockdown");
	default CapabilityTags.Add(n"HitReaction");
	default CapabilityTags.Add(n"BlockedByCutscene");

	default DebugCategory = n"Hitreaction";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 50;

	UPlayerKnockdownComponent KnockdownComp;	
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	FHazeAcceleratedRotator AccRot;
	FKnockdown Knockdown;
	UPlayerRespawnComponent RespawnComp;
	UHazeCharacterSkeletalMeshComponent MeshComp;
	FRotator TargetRotation;
	float StartKnockdownDuration;
	ULocomotionFeatureKnockDown CurrentFeature;
	AHazePlayerCharacter PlayerOwner;
	bool bInAirRecovery = false;
	const float MaxAge = 0.1;
	float LastEndTime = -BIG_NUMBER;

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
		DevTogglesMovement::Knockdown::DebugDraw.MakeVisible();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		// Reset any knockdown when we return to life
		KnockdownComp.ConsumeKnockdown(Knockdown);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		KnockdownComp.ClearCooldownKnockdowns(LastEndTime);
	}

	UFUNCTION(Blueprintoverride)
	bool ShouldActivate() const
	{
		if (!KnockdownComp.HasRecentKnockdown(MaxAge))
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (ActiveDuration > Knockdown.Duration)	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		KnockdownComp.ConsumeKnockdown(Knockdown);
		if (Knockdown.Duration < 0.1)
			Knockdown.Duration = 0.1;
		Knockdown.StandUpDuration = 0.5;

		AccRot.SnapTo(Owner.ActorRotation);

		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.BlockCapabilities(n"AdditiveHitReaction", this);
		
		PlayerOwner.CapsuleComponent.ApplyCollisionProfile(n"PlayerCharacterKnockedDown", this);
		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Owner);
		PlayerHealthComp.AddDamageInvulnerability(this, Knockdown.Duration);

		EHazeCardinalDirection Direction = CardinalDirectionForActor(Owner, Knockdown.Move);
		TargetRotation = Knockdown.Move.Rotation();
		if (Direction != EHazeCardinalDirection::Forward)
			TargetRotation.Yaw += 180.0;

		CurrentFeature = Cast<ULocomotionFeatureKnockDown>(MeshComp.GetFeatureByTag(Knockdown.FeatureTag));
		float DefaultAnimDuration = CurrentFeature.AnimData.GetStartDuration(Direction, MoveComp.IsInAir());
		StartKnockdownDuration = Math::Min(DefaultAnimDuration, Math::Max(Knockdown.Duration - Knockdown.StandUpDuration, DefaultAnimDuration * 0.5));

		KnockdownComp.AnimData.Direction = Direction;
		KnockdownComp.AnimData.StartKnockdownDuration = StartKnockdownDuration;
		KnockdownComp.AnimData.StandUpDuration = Knockdown.StandUpDuration;
		KnockdownComp.AnimData.bStandUp = false;

		KnockdownComp.bPlayerKnockedDown = true;
		bInAirRecovery = false;

		if (Knockdown.bInvertDirection)
			KnockdownComp.AnimData.Direction = GetInvertedDirection(Direction);

		// We use physics, make the mesh collide with the environment
		PlayerOwner.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
		PlayerOwner.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);

		// Sharp velocity change (do this last so no side effects, like blocking GameplayAction will change it)
		Owner.SetActorVelocity(Knockdown.Move / Knockdown.Duration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		KnockdownComp.AnimData.bStandUp = true;
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.UnblockCapabilities(n"AdditiveHitReaction", this);
		PlayerOwner.CapsuleComponent.ClearCollisionProfile(this);

		// Remove any deprecated knockdowns. If we want knockdowns while standing up etc we should fix so we can retrigger them immediately instead. 
		KnockdownComp.ClearOldKnockdowns(MaxAge);

		// Make sure we come to a hard stop at end of knockdown if on ground
		if ((ActiveDuration > Knockdown.Duration - 0.1) && MoveComp.IsOnAnyGround() && !MoveComp.HasImpulse(1.0) && MoveComp.Velocity.IsNearlyZero(800.0))
			Owner.SetActorVelocity(FVector::ZeroVector);

		KnockdownComp.bPlayerKnockedDown = false;

		PlayerOwner.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Ignore);
		PlayerOwner.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore);

		LastEndTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl() && DeltaTime > 0)
			{
				FVector Velocity = MoveComp.Velocity;
				if ((ActiveDuration < StartKnockdownDuration) || !MoveComp.IsOnAnyGround())
				{
					// Treat as if in air
					Velocity *= Math::Pow(Math::Exp(-Knockdown.AirFriction), DeltaTime); 
				}
				else
				{
					// Grounded after initial knockdown, slide to a stop 
					Velocity *= Math::Pow(Math::Exp(-Knockdown.PostKnockedFriction), DeltaTime); 
				}
				Movement.AddVelocity(Velocity);

				Movement.OverrideStepDownAmountForThisFrame(0.0); 
				Movement.AddGravityAcceleration();

				AccRot.AccelerateTo(TargetRotation, 0.5, DeltaTime);
				Movement.SetRotation(AccRot.Value);

				// We allow combining Knockback with Knockdown
				Movement.AddPendingImpulsesWithInstigator(FInstigator(n"KnockbackImpulse"));
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			if (ActiveDuration > Knockdown.Duration - Knockdown.StandUpDuration)
				KnockdownComp.AnimData.bStandUp = true;
			if (KnockdownComp.AnimData.bStandUp && MoveComp.IsInAir())
				bInAirRecovery = true;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, GetFeatureTag());
		}

		if (DevTogglesMovement::Knockdown::DebugDraw.IsEnabled())
		{
			FString DirDesc = FString("" + KnockdownComp.AnimData.Direction).RightChop(24).LeftChop(4);
			Debug::DrawDebugString(PlayerOwner.FocusLocation, "" + DirDesc + ": " + ActiveDuration + "/" + Knockdown.Duration, FLinearColor::White, 0.0, 2.0);			
			if (KnockdownComp.AnimData.bStandUp)
				Debug::DrawDebugString(PlayerOwner.FocusLocation + FVector(0.0, 0.0, 20.0), "Stand Up", FLinearColor::Green, 0.0, 2.0);			
			if (MoveComp.IsInAir())
				Debug::DrawDebugString(PlayerOwner.FocusLocation + FVector(0.0, 0.0, 40.0), "In Air", FLinearColor::LucBlue, 0.0, Scale = 2.0);			
		}
	}

	FName GetFeatureTag() const
	{
		if (!bInAirRecovery)
			return Knockdown.FeatureTag;	

		// Trying to stand up in air, we want to fake normal air movement and landing.
		if (MoveComp.IsInAir())
			return n"AirMovement";	
		if (MoveComp.NewStateIsOnWalkableGround())
			return n"Landing";
		return n"Movement";
	}

	EHazeCardinalDirection GetInvertedDirection(EHazeCardinalDirection Direction) const
	{
		switch (Direction)
		{
			case EHazeCardinalDirection::Forward:
				return EHazeCardinalDirection::Backward;
			case EHazeCardinalDirection::Left:
				return EHazeCardinalDirection::Right;
			case EHazeCardinalDirection::Right:
				return EHazeCardinalDirection::Left;
			case EHazeCardinalDirection::Backward:
				return EHazeCardinalDirection::Forward;
		}
	}
}

// No animations in this sheet, so mostly useful for testing purposes 
asset BasePlayerKnockdownSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPlayerKnockdownCapability);
	Components.Add(UPlayerKnockdownComponent);
}