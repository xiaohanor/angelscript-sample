class UGameShowArenaBombTrajectoryMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GameShowBombTrajectoryMovement");

	default DebugCategory = GameShowArena::DebugCategory;

	default TickGroup = EHazeTickGroup::Movement;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	AGameShowArenaBomb Bomb;

	FVector Velocity;

	bool bHasBlockedVisuals = false;
	float CurrentRoll = 0;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Bomb.Holder != nullptr)
			return false;

		if (Bomb.State.Get() != EGameShowArenaBombState::Thrown)
			return false;

		if (Bomb.HomingLaunchParams.bIsValid)
			return false;

		if (!Bomb.bWasLaunchedWithoutTarget)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Bomb.Holder != nullptr)
			return true;

		if (Bomb.IsActorDisabled())
			return true;

		if (Bomb.bIsAttached)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Velocity = Bomb.TrajectoryLaunchVelocity;
		CurrentRoll = 0;
		Bomb.AirborneHazeSphere.SetVisibility(true);
		if (Network::IsGameNetworked() && Bomb.Thrower != nullptr && Bomb.Thrower.HasControl() && HasControl())
		{
			Bomb.SimulatedMesh.WorldLocation = Bomb.Mesh.WorldLocation;
			Bomb.ShowProxyMeshes();
			bHasBlockedVisuals = true;
			Bomb.SimBombTrailVFX.Activate();
		}
		else
			Bomb.BombTrailVFX.Activate();

		if (Bomb.Thrower != nullptr)
		{
			auto PlayerMoveComp = UPlayerMovementComponent::Get(Bomb.Thrower);
			if (PlayerMoveComp.HasGroundContact() && PlayerMoveComp.GroundContact.Actor != nullptr)
			{
				TArray<AActor> IgnoreActors;
				IgnoreActors.Add(PlayerMoveComp.GroundContact.Actor);
				MoveComp.AddMovementIgnoresActors(this, IgnoreActors);
			}
			Bomb.SetActorControlSide(Bomb.Thrower.OtherPlayer);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// MoveComp.Reset(bResetVelocity = true);
		Bomb.HomingLaunchParams.Invalidate();
		if (bHasBlockedVisuals)
		{
			Bomb.ShowNonProxyMeshes();
			Bomb.SimBombTrailVFX.Deactivate();
		}
		else
			Bomb.BombTrailVFX.Deactivate();

		Bomb.AirborneHazeSphere.SetVisibility(false);
		bHasBlockedVisuals = false;
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Bomb.bIsAttached)
			return;

		if (MoveComp.PrepareMove(Movement))
		{
			Velocity += FVector::DownVector * 1250 * DeltaTime;
			if (HasControl())
			{
				Movement.AddVelocity(Velocity);
				Movement.SetRotation(FRotator::MakeFromZX(Velocity.ToOrientationRotator().ForwardVector, FVector::UpVector));
				Bomb.Mesh.AddRelativeRotation(FRotator(0, 500 * DeltaTime, 0));
			}
			else
			{
				Bomb.SimulatedMesh.WorldLocation += Velocity * DeltaTime;
				Bomb.SimulatedMesh.WorldRotation = FRotator::MakeFromZX(Velocity.ToOrientationRotator().ForwardVector, FVector::UpVector);
			}
			MoveComp.ApplyMove(Movement);
		}
	}
}
