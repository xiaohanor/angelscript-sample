class UPlayerCentipedeComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<APlayerCentipedeCollision> CentipedeCollisionClass;
	UPROPERTY(Transient, NotEditable)
	private APlayerCentipedeCollision CentipedeCollision;

	UPROPERTY()
	TSubclassOf<ACentipede> CentipedeClass;
	UPROPERTY(Transient, NotEditable, BlueprintReadOnly)
	ACentipede Centipede;

	UPROPERTY(Category = "Locomotion", EditDefaultsOnly)
	UPlayerCentipedeRideAnimationSettings PlayerRideAnimationSettings;
	private FName PlayerMountBone;

	UPROPERTY(Category = "Locomotion", EditDefaultsOnly)
	float MovementCatchUpOtherHeadDistance = 800.0;

	UPROPERTY(Category = "Locomotion", EditDefaultsOnly)
	float MovementCatchUpOtherHeadSpeedMultiplier = 1.4;

	UPROPERTY(Category = "Stretch", EditDefaultsOnly)
	float BaseStretchMaxDistanceBeforeKill = 1250.0;

	UPROPERTY(Category = "Stretch", EditDefaultsOnly)
	float SwingStretchMaxDistanceBeforeKill = 1750.0;

	UPROPERTY(Category = "Stretch", EditDefaultsOnly)
	float SwingStretchNetworkAddedDistance = 200.0; // if your ping is high (400ms) this is how much more lenient stretch dying is

	UPROPERTY(Category = "Lava Impact", EditDefaultsOnly)
	UNiagaraSystem LavaDeathVFXSystem;

	UPROPERTY(Category = "Lava Impact", EditDefaultsOnly)
	UForceFeedbackEffect LavaImpactForceFeedbackEffect;

	UPROPERTY(Category = "Lava Impact", EditDefaultsOnly)
	UForceFeedbackEffect LavaDeathForceFeedbackEffect;

	bool bAllowRespawn = true;

	TArray<ACentipedeAllowStretchVolume> AllowStretchDeathVolumes;

	UPROPERTY()
	float StretchAlpha = 0.0;

	AHazePlayerCharacter PlayerOwner;
	bool bWasSpeedingToOtherHead = false;
	float CatchUpSpeedMultiplier = 1.0;

	UPlayerMovementComponent MovementComponent;

	access CrawlCapability = private, UCentipedeHeadCrawlCapability;
	access : CrawlCapability bool bCrawling;

	access CrawlConstraint = private, ACentipedeCrawlConstraintVolume;

	UPROPERTY(NotEditable, BlueprintReadOnly, Transient)
	private TArray<ACentipedeCrawlConstraintVolume> ActiveCrawlConstraints;

	private bool bCentipedeActive;

	int NumPassingProjectiles = 0;
	bool bPassingProjectile = false;
	bool bAutoTargeting = false;

	UCentipedeProjectileTargetableComponent AutoTargetedComponent;

	bool bShootingWater = false;
	bool bBitingWater = false;

	private TInstigated<FVector> InstigatedMovementFacingDirectionOverride;
	default InstigatedMovementFacingDirectionOverride.SetDefaultValue(FVector::ZeroVector);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UPlayerMovementComponent::Get(PlayerOwner);

		if (PlayerRideAnimationSettings != nullptr)
			PlayerMountBone = PlayerRideAnimationSettings.GetMountBoneForPlayer(PlayerOwner.Player);
	}

	// Should be called from static function
	void MountCentipede(ACentipede InCentipede)
	{
		if (bCentipedeActive)
			return;

		Centipede = InCentipede;

		Outline::ApplyNoOutlineOnActor(PlayerOwner, PlayerOwner, this, EInstigatePriority::Normal);
		Outline::ApplyNoOutlineOnActor(PlayerOwner, PlayerOwner.OtherPlayer, this, EInstigatePriority::Normal);

		// Create collision
		CentipedeCollision = SpawnActor(CentipedeCollisionClass, bDeferredSpawn = true);
		CentipedeCollision.MakeNetworked(this, Time::FrameNumber);
		CentipedeCollision.SetActorControlSide(this);
		CentipedeCollision.AttachToComponent(PlayerOwner.MeshOffsetComponent);
		FinishSpawningActor(CentipedeCollision);
		CentipedeCollision.SetActorRelativeTransform(FTransform::Identity);

		// Assign centipede collision
		MovementComponent.SetupShapeComponent(CentipedeCollision.Collision);

		// Setup targetables to top-down evaluation
		PlayerOwner.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::TopDown, this);

		bCentipedeActive = true;

		UPlayerRespawnComponent PlayerRespawnComponent = UPlayerRespawnComponent::Get(PlayerOwner);
		if (PlayerRespawnComponent != nullptr)
			PlayerRespawnComponent.OnPlayerRespawned.AddUFunction(Centipede, n"OnPlayerRespawned");
	}

	UFUNCTION()
	void ClearCentipede()
	{
		if (!bCentipedeActive)
			return;

		bCentipedeActive = false;

		PlayerOwner.ClearGameplayPerspectiveMode(this);

		MovementComponent.ClearSplineCollision(this);

		// Restore player's movement component collider
		MovementComponent.SetupShapeComponent(PlayerOwner.CapsuleComponent);

		Outline::ClearOutlineOnActor(PlayerOwner, PlayerOwner, this);
		Outline::ClearOutlineOnActor(PlayerOwner, PlayerOwner.OtherPlayer, this);

		if (CentipedeCollision != nullptr)
		{
			CentipedeCollision.DestroyActor();
			CentipedeCollision = nullptr;
		}

		if (Centipede != nullptr)
		{
			Centipede.DestroyActor();
			Centipede = nullptr;
		}
	}

	void ApplyHurryToOtherHeadSpeed(FVector MoveInput)
	{
		if (MoveInput.Size() < KINDA_SMALL_NUMBER)
		{
			if (bWasSpeedingToOtherHead)
			{
				bWasSpeedingToOtherHead = false;
				MovementComponent.ClearMoveSpeedMultiplier(this);
			}
			return;
		}
		FVector PlayerInput = MoveInput.GetSafeNormal();
		bool bWantToSpeedToOtherHead = false;
		FVector ToOtherHead = PlayerOwner.OtherPlayer.GetActorLocation() - PlayerOwner.ActorLocation;

		// are we far away and going towards other head?
		bWantToSpeedToOtherHead = ToOtherHead.Size() > MovementCatchUpOtherHeadDistance && ToOtherHead.GetSafeNormal().DotProduct(PlayerInput) > 0.0;
		if (bWantToSpeedToOtherHead && !bWasSpeedingToOtherHead)
			CatchUpSpeedMultiplier = MovementCatchUpOtherHeadSpeedMultiplier;
		else if (bWasSpeedingToOtherHead && !bWantToSpeedToOtherHead)
			CatchUpSpeedMultiplier = 1.0;
		bWasSpeedingToOtherHead = bWantToSpeedToOtherHead;

		// Debug::DrawDebugSphere(PlayerOwner.ActorLocation, MovementCatchUpOtherHeadDistance, 12, FLinearColor::White, 1.0);
		// Debug::DrawDebugLine(PlayerOwner.ActorLocation, PlayerOwner.ActorLocation + PlayerInput * 500.0, FLinearColor::Red, 5.0, 0.0, true);
		// Debug::DrawDebugString(PlayerOwner.ActorLocation, "" + ToOtherHead.GetSafeNormal().DotProduct(PlayerInput));
		// Debug::DrawDebugString(PlayerOwner.ActorLocation, "\n" + bWantToSpeedToOtherHead);
	}

	bool IsFullyStretched() const
	{
		return PlayerOwner.GetSquaredDistanceTo(PlayerOwner.OtherPlayer) >= Centipede::GetMaxPlayerDistanceSquared();
	}

	float GetStretchFraction() const
	{
		return Math::Saturate(PlayerOwner.GetSquaredDistanceTo(PlayerOwner.OtherPlayer) / Centipede::GetMaxPlayerDistanceSquared());
	}

	float GetBodyLength() const property
	{
		return Centipede.GetBodyLength();
	}

	float GetBodyLengthSquared() const property
	{
		return Math::Square(GetBodyLength());
	}

	TArray<FVector> GetBodyLocations() const
	{
		return Centipede.GetBodyLocations();
	}

	FVector GetNeckJointLocationForPlayer(EHazePlayer Player) const
	{
		// Can be null during network shutdown, no biggie since we won't move anymore
		if (Centipede != nullptr)
			return Centipede.GetNeckJointLocationForPlayer(Player);

		return Game::GetPlayer(Player).ActorLocation;
	}

	// 0 is this player's location and 1 is other player's
	FVector GetLocationAtBodyFraction(float Fraction) const
	{
		return Centipede.GetLocationAtBodyFractionForHeadPlayer(Fraction, PlayerOwner.Player);
	}

	FVector GetMovementInput() const property
	{
#if !RELEASE
		auto DebugMovementComponent = UPlayerCentipedeDebugMovementComponent::GetOrCreate(Owner);
		if (DebugMovementComponent != nullptr && DebugMovementComponent.IsActive())
			return DebugMovementComponent.GetMovementInput();
#endif

		return MovementComponent.MovementInput;
	}

	void ApplyCentipedeBodyPlayerWorldUp(FVector WorldUp, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if (Centipede != nullptr)
			Centipede.ApplyPlayerWorldUp(PlayerOwner, WorldUp, Instigator, Priority);
	}

	void ClearCentipedeBodyPlayerWorldUp(FInstigator Instigator)
	{
		if (Centipede != nullptr)
			Centipede.ClearPlayerWorldUp(PlayerOwner, Instigator);
	}

	void ApplyDisableBodyCollisionWithPlayer(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if (Centipede != nullptr)
			Centipede.ApplyDisableCollisionWithPlayer(Instigator, Priority);
	}

	void ClearDisableBodyCollisionWithPlayer(FInstigator Instigator)
	{
		if (Centipede != nullptr)
			Centipede.ClearDisableCollisionWithPlayer(Instigator);
	}

	void ApplyMovementFacingDirectionOverride(FVector DirectionOverride, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedMovementFacingDirectionOverride.Apply(DirectionOverride, Instigator, Priority);
	}

	void ClearMovementFacingDirectionOverride(FInstigator Instigator)
	{
		InstigatedMovementFacingDirectionOverride.Clear(Instigator);
	}

	FVector GetMovementFacingDirectionOverride() const
	{
		return InstigatedMovementFacingDirectionOverride.Get();
	}

	bool HasMovementFacingDirectionOverride() const
	{
		return !InstigatedMovementFacingDirectionOverride.IsDefaultValue();
	}

	FTransform GetMountBoneTransform() const
	{
		if (Centipede != nullptr)
			return Centipede.Mesh.GetSocketTransform(PlayerMountBone);

		return FTransform();
	}

	FTransform GetMeshHeadTransform() const
	{
		if (Centipede == nullptr)
			return FTransform();

		FName BoneName = GetMeshHeadBoneName();
		FTransform Transform = Centipede.Mesh.GetSocketTransform(BoneName, ERelativeTransformSpace::RTS_World);

		if (BoneName == n"BlueHead")
		{
			FQuat YawFlip = FQuat(Transform.Rotation.UpVector, PI);
			Transform.SetRotation(YawFlip * Transform.Rotation);
		}

		return Transform;
	}

	FName GetMeshHeadBoneName() const
	{
		return IsHeadPlayer() ? n"GreenHead" : n"BlueHead";
	}

	access : CrawlConstraint
	void AddCrawlConstraint(ACentipedeCrawlConstraintVolume CrawlConstraint)
    {
    	ActiveCrawlConstraints.Add(CrawlConstraint);
    }

	access : CrawlConstraint
    void RemoveCrawlConstraint(ACentipedeCrawlConstraintVolume CrawlConstraint)
    {
    	ActiveCrawlConstraints.Remove(CrawlConstraint);
    }

	const TArray<ACentipedeCrawlConstraintVolume>& GetActiveCrawlConstraints() const
	{
		return ActiveCrawlConstraints;
	}

	// Kills both players and centipede actor.
	// Call this on both net sides!!
	void KillCentipede()
	{
		if (Centipede != nullptr)
		{
			PlayerOwner.KillPlayer();
			Centipede.KillCentipede();
		}
	}

	bool IsCentipedeDead() const
	{
		if (Centipede == nullptr)
			return true;

		if (Centipede.IsDead())
			return true;

		return false;
	}

	bool IsHeadPlayer() const
	{
		return PlayerOwner.Player == Centipede::HeadHazePlayer;
	}

	bool IsTailPlayer() const
	{
		return PlayerOwner.Player == Centipede::TailHazePlayer;
	}

	UFUNCTION(BlueprintPure)
	bool IsCentipedeActive() const
	{
		return bCentipedeActive;
	}

	UFUNCTION(BlueprintPure)
	bool IsCrawling() const
	{
		return bCrawling;
	}

	UFUNCTION(BlueprintPure)
	bool IsFalling() const
	{
		return PlayerOwner.IsAnyCapabilityActive(CentipedeTags::CentipedeAirMovement) || PlayerOwner.IsAnyCapabilityActive(CentipedeTags::CentipedeSwingJump);
	}

	UFUNCTION(BlueprintPure)
	bool IsOtherPlayerFalling() const
	{
		return UPlayerCentipedeComponent::Get(PlayerOwner.OtherPlayer).IsFalling();
	}
}