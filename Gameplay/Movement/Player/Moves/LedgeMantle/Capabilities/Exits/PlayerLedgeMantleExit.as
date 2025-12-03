class UPlayerLedgeMantleExit : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 5;

	UPlayerLedgeMantleComponent MantleComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	float MoveSpeed = 0.0;
	bool bMoveCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MantleComp.Data.HasValidData())
			return false;

		if (!MantleComp.Data.bEnterCompleted)
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::LowMantleEnter && MantleComp.GetState() != EPlayerLedgeMantleState::HighMantleEnter)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (bMoveCompleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);

		bMoveCompleted = false;

		FVector ToTarget = MantleComp.Data.ExitLocation - Player.ActorLocation;
		FVector ToTargetFlattened = ToTarget.ConstrainToPlane(MoveComp.WorldUp);
		float MoveDuration = ToTargetFlattened.Size() / MantleComp.Data.EnterSpeed;
		MoveSpeed = ToTarget.Size() / MoveDuration;

		MantleComp.SetState(EPlayerLedgeMantleState::Exit);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);

		MantleComp.Data.Reset();

		UCameraSettings::GetSettings(Player).PivotLagMax.Clear(MantleComp, 1);
		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Clear(MantleComp, 1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector ToTarget = MantleComp.Data.ExitLocation - Player.ActorLocation;
			FVector DeltaMove = ToTarget.GetSafeNormal() * MoveSpeed * DeltaTime;

			if(ToTarget.Size() < DeltaMove.Size())
			{
				DeltaMove = ToTarget;
				bMoveCompleted = true;
				Movement.OverrideFinalGroundResult(MantleComp.Data.ExitFloorHit);
			}

			Movement.AddDeltaWithCustomVelocity(DeltaMove, MantleComp.Data.Direction * MantleComp.Data.EnterSpeed);
			Movement.SetRotation(ToTarget.Rotation());
			MoveComp.ApplyMove(Movement);
		}
		// Remote update
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		Player.Mesh.RequestLocomotion(n"LedgeMantle", this);
	}
}