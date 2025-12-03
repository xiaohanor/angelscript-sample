class USanctuaryBossSkydiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 158;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryBossSkydivePlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	FVector Velocity = FVector::ZeroVector;
	float Drag = 3.0;

	ASanctuaryBossSkydiveActor SkydiveActor;

	UNiagaraComponent FallingVFX;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USanctuaryBossSkydivePlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (Player.IsPlayerDead())
			return false;

		if (PlayerComp == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (Player.IsPlayerDead())
			return true;

		if (PlayerComp == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SkydiveActor = Cast<ASanctuaryBossSkydiveActor>(PlayerComp.SkydiveActor);

		Player.PlayBlendSpace(PlayerComp.FallingAnimation);

		FallingVFX = Niagara::SpawnLoopingNiagaraSystemAttached(PlayerComp.FallingVFX, Player.Mesh);

		FTransform TeleportTransform = (Player.IsMio() ? SkydiveActor.MioStartTransform : SkydiveActor.ZoeStartTransform);
		TeleportTransform *= SkydiveActor.ActorTransform;
		Player.TeleportActor(TeleportTransform.Location, TeleportTransform.Rotation.Rotator(), this);

		MoveComp.FollowComponentMovement(SkydiveActor.RootComponent, this);
	
		SpeedEffect::RequestSpeedEffect(Player, 3.0, this, EInstigatePriority::Normal);
	
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopBlendSpace();

		FallingVFX.Deactivate();

		MoveComp.UnFollowComponentMovement(this);

		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector2D Input2D = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
				FVector Input;
				Input.Y = Input2D.X;
				Input.Z = Input2D.Y;

				Player.SetBlendSpaceValues(Input2D.X, Input2D.Y);

				Input = SkydiveActor.ActorTransform.TransformVectorNoScale(Input);

				FVector ToOrigin = SkydiveActor.ActorLocation - Player.ActorCenterLocation;
				ToOrigin = ToOrigin.VectorPlaneProject(SkydiveActor.ActorForwardVector);

				FVector ContrainForce = FVector::ZeroVector;
				if (ToOrigin.Size() > SkydiveActor.ConstrainRadius)
				{
					float ContrainForceScale = ToOrigin.Size() - SkydiveActor.ConstrainRadius;
					ContrainForce = ToOrigin.SafeNormal * ContrainForceScale * 15;
					//	Debug::DrawDebugLine(Player.ActorCenterLocation, Player.ActorCenterLocation + ContrainForce, FLinearColor::Red, 10.0, 0.0);	
				}

				//	Debug::DrawDebugLine(Player.ActorCenterLocation, Player.ActorCenterLocation + ToOrigin, FLinearColor::Green, 5.0, 0.0);

				FVector FollowDelta = SkydiveActor.DeltaMove;

				FVector Acceleration = Input * 1100.0
									+ ContrainForce
									- Velocity * Drag;

				Velocity += Acceleration * DeltaTime;

				Movement.SetRotation(SkydiveActor.ActorUpVector.Rotation());
				// Movement.AddDeltaWithCustomVelocity(FollowDelta, FollowDelta / DeltaTime);
				Movement.AddVelocity(Velocity);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);

			if (HasControl() && HadImpact())
				Player.KillPlayer();
		}
	}

	bool HadImpact()
	{
		if (MoveComp.PreviousHadGroundContact())
			return true;
		if (MoveComp.PreviousHadWallContact())
			return true;
		if (MoveComp.PreviousHadCeilingContact())
			return true;

		if (MoveComp.HasGroundContact())
			return true;
		if (MoveComp.HasWallContact())
			return true;
		if (MoveComp.HasCeilingContact())
			return true;

		return false;
	}
};