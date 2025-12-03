
class UPlayer2DPerchOnPointCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointPerch);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 44;
	default TickGroupSubPlacement = 9;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerPerchComponent PerchComp;
	UPlayerSplineLockComponent SplineLockComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveComp;
	UTeleportingMovementData Movement;

	float TurnaroundTimer = 0.0;

	FVector InitialFacingDirection;
	FVector CurrentFacingDirection;
	FVector TargetFacingDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		SplineLockComp = UPlayerSplineLockComponent::GetOrCreate(Player);
		PerspectiveComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPerchOnPointActivationParams& ActivationParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if (!SplineLockComp.HasActiveSplineLock())
			return false;

		if (!PerspectiveComp.IsIn2DPerspective())
			return false;

		if(PerchComp.Data.ActivePerchPoint == nullptr)
			return false;

        if(PerchComp.Data.ActivePerchPoint.bHasConnectedSpline)
            return false;

		ActivationParams.ActivatedOnData = PerchComp.Data;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPerchOnPointDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
		{
			if(PerchComp.Data.State == EPlayerPerchState::JumpTo)
				Params.DeactivationType = EPerchOnPointDeactivationTypes::JumpTo;
			else if(PerchComp.Data.bJumpingOff)
				Params.DeactivationType = EPerchOnPointDeactivationTypes::JumpOff;
			else
				Params.DeactivationType = EPerchOnPointDeactivationTypes::Interrupted;

			return true;
		}

		if (!PerspectiveComp.IsIn2DPerspective() || !SplineLockComp.HasActiveSplineLock())
		{
			Params.DeactivationType = EPerchOnPointDeactivationTypes::Interrupted;
			return true;
		}

		if(PerchComp.Data.ActivePerchPoint == nullptr || PerchComp.Data.ActivePerchPoint.IsDisabled() || PerchComp.Data.ActivePerchPoint.IsDisabledForPlayer(Player))
		{
			Params.DeactivationType = EPerchOnPointDeactivationTypes::Disabled;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPerchOnPointActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::Perch, this);
		PerchComp.SetState(EPlayerPerchState::PerchingOnPoint);

		//Make sure our data is replicated
		FPerchData PerchData = ActivationParams.ActivatedOnData;

		if(PerchData.ActivePerchPoint.PerchSettings != nullptr)
			Player.ApplySettings(PerchData.ActivePerchPoint.PerchSettings, this);

		InitialFacingDirection = Player.ActorForwardVector;
		CurrentFacingDirection = InitialFacingDirection;
		TargetFacingDirection = InitialFacingDirection;

		PerchData.ActivePerchPoint.OnPlayerStartedPerchingEvent.Broadcast(Player, PerchData.ActivePerchPoint);

		PerchData.PerchLandingVerticalVelocity = MoveComp.VerticalVelocity;
		PerchData.PerchLandingHorizontalVelocity = MoveComp.HorizontalVelocity;

		TurnaroundTimer = 0;

		//Reset Move Usage
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPerchOnPointDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Perch, this);

		switch(Params.DeactivationType)
		{
			case EPerchOnPointDeactivationTypes::Disabled:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;

			//[AL] - StoppedPerchingEvent is fired in jumpoff capability as it should already have stopped perching = our Current perchPoint has been cleared.
			case EPerchOnPointDeactivationTypes::JumpOff:
				PerchComp.StopPerching();
				break;

			case EPerchOnPointDeactivationTypes::Interrupted:

				if(IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;

			case EPerchOnPointDeactivationTypes::JumpTo:
				PerchComp.StopPerching();
				break;

			default:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;
		}

		//Reset some AnimData incase we interupted a turnaround with jumpoff/cancel/etc
		PerchComp.Data.bPerformingPerchTurnaround = false;
		PerchComp.AnimData.bPerformingTurnaroundLeft = false;
		PerchComp.AnimData.bPerformingTurnaroundRight = false;

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

				if(RawInput.X > -PerchComp.Settings.HorizontalDeadZone && RawInput.X < PerchComp.Settings.HorizontalDeadZone)
					RawInput.X = 0.0;

				CalculateRotation(DeltaTime, RawInput);
				Movement.SetRotation(CurrentFacingDirection.Rotation());
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				//Remote Update
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement ,n"Perch");
		}
	}

	bool bAnimDataSet = false;

	void CalculateRotation(float DeltaTime, FVector2D Input)
	{
		if(!PerchComp.Data.bPerformingPerchTurnaround)
		{
			if(Input.X == 0.0)
				return;
				
			TargetFacingDirection = Player.ViewRotation.RightVector * Input.X;
			float CurrentToTargetDot = CurrentFacingDirection.DotProduct(TargetFacingDirection);

			if(CurrentToTargetDot >= 0.0)
				return;

			float CurrentSplineDistance = SplineLockComp.CurrentSpline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
			FVector SplineLocationFordwardVector = SplineLockComp.CurrentSpline.GetWorldForwardVectorAtSplineDistance(CurrentSplineDistance);
			float PlayerSplineForwardDot = Player.ActorForwardVector.DotProduct(SplineLocationFordwardVector);
			int SplineDirectionSign = PlayerSplineForwardDot <= 0 ? 1 : -1;

			TargetFacingDirection = SplineLocationFordwardVector * SplineDirectionSign;
			InitialFacingDirection = CurrentFacingDirection;

			if(InitialFacingDirection.DotProduct(TargetFacingDirection) < 0.999)
				InitialFacingDirection += Player.ActorRightVector * 0.01;
			
			//Assign Data
			PerchComp.Data.bPerformingPerchTurnaround = true;
			TurnaroundTimer = 0;
			bAnimDataSet = false;
		}
		else
		{
			TurnaroundTimer += DeltaTime;
			float TurnAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, PerchComp.Settings.TurnaroundDuration), FVector2D(0, 1), TurnaroundTimer);

			CurrentFacingDirection = InitialFacingDirection.SlerpVectorTowardsAroundAxis(TargetFacingDirection, MoveComp.WorldUp, TurnAlpha);

			if(!bAnimDataSet)
			{
				if(CurrentFacingDirection.DotProduct(Player.ActorRightVector) > 0)
				{
					PerchComp.AnimData.bPerformingTurnaroundRight = true;
				}
				else
				{
					PerchComp.AnimData.bPerformingTurnaroundLeft = true;
				}

				bAnimDataSet = true;
			}

			if(TurnAlpha == 1)
			{
				PerchComp.Data.bPerformingPerchTurnaround = false;
				PerchComp.AnimData.bPerformingTurnaroundLeft = false;
				PerchComp.AnimData.bPerformingTurnaroundRight = false;
			}
		}
	}
}