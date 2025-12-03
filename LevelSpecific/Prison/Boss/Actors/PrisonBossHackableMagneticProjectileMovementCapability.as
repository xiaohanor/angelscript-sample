class UPrisonBossHackableMagneticProjectileMovementCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	APrisonBossHackableMagneticProjectile Projectile;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	FVector Velocity = FVector::ZeroVector;
	float MoveSpeed = 600.0;

	FVector DefaultLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Projectile = Cast<APrisonBossHackableMagneticProjectile>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		DefaultLoc = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Velocity = Projectile.InitialHackedVelocity * 800.0;
		Projectile.SyncedActorPositionComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Projectile.SyncedActorPositionComp.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Projectile.bMagnetBursted)
			return;

		if (Projectile.RootComponent.AttachParent != nullptr)
			return;

		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector Input = PlayerMoveComp.MovementInput;
			Velocity = Math::VInterpTo(Velocity, Input * MoveSpeed, DeltaTime, 1.8);
			FVector DeltaMove = Velocity * DeltaTime;
			Movement.AddDelta(DeltaMove);
			Movement.AddGravityAcceleration();
			Movement.AddOwnerVerticalVelocity();
		}
		else
		{
			if (MoveComp.IsOnAnyGround())
				Movement.ApplyCrumbSyncedGroundMovement();
			else
				Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);

		// Rotate the projectile based on the current velocity, so it rolls instead of slides
		FVector AngularVelocity =  MoveComp.GetVelocity().CrossProduct(FVector::UpVector);

		float RotationSpeed = (AngularVelocity.Size() / 60.0);
		RotationSpeed = Math::Clamp(RotationSpeed, -20.0, 20.0);

		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
		Projectile.RotationRoot.AddWorldRotation(DeltaQuat);
	}
}