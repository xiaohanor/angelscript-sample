class UIslandWalkerClusterMineFallCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local; // Lots of mines, move them locally

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	AIslandWalkerClusterMine Mine;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	const float Friction = 3.0;
	const FVector Gravity = FVector(0.0, 0.0, -982.0 * 3.0);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mine = Cast<AIslandWalkerClusterMine>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Mine.bLaunched)
			return false;
		if (Mine.bLanded)
			return false;
		if (!Mine.bBounced)
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Mine.bLaunched)
			return true;
		if (Mine.bLanded)
			return true;
		if (!Mine.bBounced)
			return true;
		if (MoveComp.HasMovedThisFrame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;		

		// Fall and slide to a stop
		Movement.AddAcceleration(Gravity);
		FVector Velocity = MoveComp.Velocity;
		Velocity *= Math::Pow(Math::Exp(-Friction), DeltaTime);
		Movement.AddVelocity(Velocity);

		MoveComp.ApplyMove(Movement);

		// Time to land?
		if (MoveComp.HasImpactedGround())
			Mine.Land();

		// Align mesh with velocity while falling and right it when landed.
		FRotator MeshRot = Mine.Mesh.WorldRotation;
		if (!Mine.ProjectileComp.Velocity.IsNearlyZero(1.0))
			MeshRot = FRotator::MakeFromZX(-Mine.ProjectileComp.Velocity, Owner.ActorForwardVector);
		Mine.Mesh.SetWorldRotation(MeshRot);
	}
}
