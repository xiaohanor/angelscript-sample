class UGameShowArenaBombMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GameShowBombMovement");

	default TickGroup = EHazeTickGroup::Movement;

	default DebugCategory = GameShowArena::DebugCategory;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	AGameShowArenaBomb Bomb;
	FHazeRuntimeSpline RuntimeSpline;

	FVector StartPoint;
	FVector ControlPoint;
	FVector EndPoint;

	FVector Velocity;
	FVector SimulatedVelocity;
	FVector SimulatedPosition;

	float CurrentThrowTravelTime = 0;
	float SimulatedThrowTravelTime = 0;

	bool bHasDestinationEndPoint = false;
	bool bHasSwitchedControlSide = false;

	bool bHasBlockedVisuals = false;
	bool bHasBlockedContact = false;
	float CurrentRoll = 0;
	bool bHasBeenCaught = false;
	FVector BombCaughtLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bomb = Cast<AGameShowArenaBomb>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
		MoveComp.AddMovementIgnoresActor(this, Game::Mio);
		MoveComp.AddMovementIgnoresActor(this, Game::Zoe);
		Bomb.OnNetBombCaught.AddUFunction(this, n"OnBombCaught");
	}

	UFUNCTION()
	private void OnBombCaught(FVector CatchLocation)
	{
		bHasBeenCaught = true;
		BombCaughtLocation = CatchLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Bomb.Holder != nullptr)
			return false;

		if (Bomb.State.Get() != EGameShowArenaBombState::Thrown)
			return false;

		if (!Bomb.HomingLaunchParams.bIsValid)
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
		bHasBeenCaught = false;
		RuntimeSpline = FHazeRuntimeSpline();
		bHasSwitchedControlSide = false;
		bHasDestinationEndPoint = false;
		Bomb.AirborneHazeSphere.SetVisibility(true);
		if (!Bomb.HomingLaunchParams.bIsValid)
			return;

		RuntimeSpline.SetPoints(Bomb.HomingLaunchParams.Points);

		SimulatedPosition = StartPoint;
		if (Network::IsGameNetworked() && Bomb.Thrower != nullptr && Bomb.Thrower.HasControl() && HasControl())
		{
			Bomb.SimulatedMesh.WorldLocation = Bomb.Mesh.WorldLocation;
			Bomb.ShowProxyMeshes();
			bHasBlockedVisuals = true;
			Bomb.SimBombTrailVFX.Activate();
		}

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
			Bomb.BombTrailVFX.Activate();
		}

		bHasSwitchedControlSide = true;

		CurrentThrowTravelTime = Bomb.HomingLaunchParams.TravelTime;
		SimulatedThrowTravelTime = CurrentThrowTravelTime + Network::PingOneWaySeconds + Time::EstimatedCrumbReachedDelay;
		Bomb.SetActorEnableCollision(false);

		Bomb.BlockCapabilities(n"BombContactExplosion", this);
		bHasBlockedContact = true;
		CurrentRoll = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bHasBlockedContact)
		{
			Bomb.UnblockCapabilities(n"BombContactExplosion", this);
		}
		Velocity = FVector::ZeroVector;
		// MoveComp.Reset(bResetVelocity = true);
		Bomb.HomingLaunchParams.Invalidate();
		if (bHasBlockedVisuals)
		{
			Bomb.ShowNonProxyMeshes();
		}

		Bomb.SimBombTrailVFX.Deactivate();
		Bomb.BombTrailVFX.Deactivate();
		Bomb.AirborneHazeSphere.SetVisibility(false);

		bHasBlockedVisuals = false;
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (MoveComp.PrepareMove(Movement))
			{
				UpdateVelocity(Bomb.ActorLocation, CurrentThrowTravelTime, DeltaTime, Velocity);
				Movement.AddDelta(Velocity * DeltaTime);
				Movement.SetRotation(FRotator::MakeFromZX(Velocity.ToOrientationRotator().ForwardVector, FVector::UpVector));
				Bomb.Mesh.AddRelativeRotation(FRotator(0, 500 * DeltaTime, 0));
				if (ActiveDuration > 3)
					Bomb.CrumbExplode(Bomb.ActorLocation);

				if (ActiveDuration > 0.4 && bHasBlockedContact)
				{
					Bomb.UnblockCapabilities(n"BombContactExplosion", this);
					bHasBlockedContact = false;
				}
				MoveComp.ApplyMove(Movement);
			}
		}
		else
		{
			// Move simulated bomb
			UpdateVelocity(SimulatedPosition, SimulatedThrowTravelTime, DeltaTime, SimulatedVelocity);
			SimulatedPosition += SimulatedVelocity * DeltaTime;
			Bomb.SimulatedMesh.WorldLocation = SimulatedPosition;
			Bomb.SimulatedMesh.WorldRotation = FRotator::MakeFromZX(SimulatedVelocity.ToOrientationRotator().ForwardVector, FVector::UpVector);
		}
	}

	void UpdateVelocity(FVector Location, float TravelTime, float DeltaTime, FVector&out OutVelocity)
	{
		// add gravity if reached end of spline
		bool bShouldAddGravity = ActiveDuration >= TravelTime;
		if (!bShouldAddGravity && Bomb.HomingLaunchParams.bIsValid)
		{
			float Alpha = ActiveDuration / TravelTime;
			auto PlayerTarget = Bomb.HomingLaunchParams.TargetPlayer;
			if (PlayerTarget != nullptr)
			{
				RuntimeSpline.SetPoint(PlayerTarget.ActorCenterLocation, RuntimeSpline.Points.Num() - 1);
			}

			if (Alpha <= 0.9)
			{
				auto NewLocation = RuntimeSpline.GetLocation(Alpha);
				OutVelocity = (NewLocation - Location) / DeltaTime;
			}
		}

		if (bShouldAddGravity)
		{
			OutVelocity += FVector::DownVector * 982 * DeltaTime;
		}
	}
};