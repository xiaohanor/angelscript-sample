class UPlayerLedgeMantleEnter : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 10;

	UPlayerLedgeMantleComponent MantleComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	float MoveSpeed;
	FVector RelativeEndLocation;
	FVector RemainingDelta;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLedgeMantleData& ActivationParams) const
	{
		if(PlayerLedgeMantle::CVar_EnableLedgeMantle.GetInt() == 0)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (MantleComp.Data.bEnterCompleted)
			return false;

		//Dont activate if we arent giving directional input
		if (MoveComp.MovementInput.IsNearlyZero())
			return false;

		FVector MantleDirection;
		if (!MoveComp.HorizontalVelocity.IsNearlyZero())
		{
			//We want to verify that we are giving input in roughly the direction of the wall, No input = no mantle
			if (CheckInputAndVelocityAlignment(MoveComp.MovementInput, MoveComp.HorizontalVelocity.GetSafeNormal()))
				MantleDirection = MoveComp.HorizontalVelocity.GetSafeNormal();
			else
				return false;
		}
		else if (!MoveComp.MovementInput.IsNearlyZero())
			MantleDirection = MoveComp.MovementInput;

		FPlayerLedgeMantleData MantleData;
		if (!MantleComp.TraceForGroundedMantle(Player, MantleDirection, MantleData, IsDebugActive()))
			return false;

		ActivationParams = MantleData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (MantleComp.Data.bEnterCompleted)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLedgeMantleData ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);

		MantleComp.Data = ActivationParams;
		
		FVector EndLocation = ActivationParams.LedgePlayerLocation;
		RelativeEndLocation = ActivationParams.TopHitComponent.WorldTransform.InverseTransformPosition(EndLocation);
		RemainingDelta = EndLocation - Player.ActorLocation;

		MoveSpeed = RemainingDelta.Size() / MantleComp.Data.EnterDuration;

		PrintToScreen("Duration: " + ActivationParams.EnterDuration, 5);
		PrintToScreen("Distance: " + ActivationParams.EnterDistance, 5);

		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Apply(FVector(0.5, 0.5, 1.5), MantleComp);
		UCameraSettings::GetSettings(Player).PivotLagMax.Apply(FVector(UCameraSettings::GetSettings(Player).PivotLagMax.Value.X,UCameraSettings::GetSettings(Player).PivotLagMax.Value.Y, 750), MantleComp);

		//Set States/AnimData
		MantleComp.SetState(ActivationParams.MantleType);
		MantleComp.AnimData.EnterDistanceSpeed = FVector2D(MantleComp.Data.EnterDistance, MantleComp.Data.EnterSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);

		//State completed check and reset
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector TargetLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeEndLocation);
			FVector ToTarget = TargetLocation - Player.ActorLocation;
			FVector DeltaMove = ToTarget.GetSafeNormal() * MoveSpeed * DeltaTime;

			if (ToTarget.Size() < DeltaMove.Size())
			{
				DeltaMove = ToTarget;
				MantleComp.Data.bEnterCompleted = true;
			}

			Movement.AddDeltaWithCustomVelocity(DeltaMove, MantleComp.Data.Direction * MantleComp.Data.EnterSpeed);
			Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, FRotator::MakeFromXZ(MantleComp.Data.Direction, MoveComp.WorldUp), DeltaTime, 900));
			MoveComp.ApplyMove(Movement);
		}
		// Remote update
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		Player.Mesh.RequestLocomotion(n"LedgeMantle", this);
	}

	bool CheckInputAndVelocityAlignment(FVector MoveInput, FVector MantleDirection) const
	{
		float Angle = Math::RadiansToDegrees(MoveInput.DotProduct(MantleDirection));
		Angle = Math::Acos(Angle);

		if (Angle > MantleComp.Settings.InputToWallAngleCutoff)
			return false;

		return true;
	}
};