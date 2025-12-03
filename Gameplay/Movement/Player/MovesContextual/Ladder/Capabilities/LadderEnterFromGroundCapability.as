

class UPlayerLadderEnterFromGroundCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderEnter);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;

	FVector StartLocation;
	FVector RelativeStartLocation;

	FRotator StartRot;
	FLadderRung EnterRung;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLadderEnterParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (MoveComp.IsInAir())
			return false;

		if (LadderComp.State != EPlayerLadderState::Inactive)
			return false;

		if (!LadderComp.TestForValidEnter())
			return false;

		if (LadderComp.Data.TargetLadderData.Ladder == nullptr)
			return false;

		if (LadderComp.Data.ActiveLadder != nullptr)
			return false;

		if (!LadderComp.Data.QueryClosestRung.IsValid())
			return false;

		if (!LadderComp.Data.TargetLadderData.Ladder.TestRungForValidCollision(LadderComp.Data.QueryClosestRung, Player))
			return false;

		if (!LadderComp.Data.TargetLadderData.bForceEntry && (MoveComp.Velocity.GetSafeNormal().DotProduct(LadderComp.Data.TargetLadderData.Ladder.ActorForwardVector) < 0.1 && MoveComp.MovementInput.DotProduct(LadderComp.Data.TargetLadderData.Ladder.ActorForwardVector) < 0.1))
			return false;

		if (!LadderComp.Data.TargetLadderData.bForceEntry && (MoveComp.MovementInput.IsNearlyZero() && MoveComp.Velocity.IsNearlyZero()))
			return false;

		if (!LadderComp.Data.TargetLadderData.bForceEntry && LadderComp.OnLadderCooldown())
			return false;

		if (!LadderComp.Data.TargetLadderData.bForceEntry && LadderComp.Data.TargetLadderData.Ladder.IsDisabled())
			return false;

		Params.EnteredLadder = LadderComp.Data.TargetLadderData;
		Params.EnterRung = LadderComp.Data.QueryClosestRung;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerLadderEnterDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= LadderComp.Settings.EnterFromGroundTotalTime)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLadderEnterParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		LadderComp.ActivateLadderClimb(Params.EnteredLadder.Ladder);
		LadderComp.SetState(EPlayerLadderState::EnterFromGround);
		LadderComp.Data.bMoving = true;

		if(Params.EnteredLadder.bForceEntry)
		{
			for (int i = 0; i < LadderComp.Data.QueryLadderData.Num(); i++)
			{
				if(LadderComp.Data.QueryLadderData[i].Ladder == Params.EnteredLadder.Ladder)
				{
					LadderComp.Data.QueryLadderData[i].bForceEntry = false;
				}
			}
		}

		StartLocation = Player.ActorLocation;
		RelativeStartLocation = LadderComp.Data.ActiveLadder.ActorTransform.InverseTransformPosition(StartLocation);

		StartRot = Player.ActorRotation;
		EnterRung = Params.EnterRung;

		FVector TargetLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung);
		LadderComp.SetEnterAngle(StartLocation, TargetLocation);

		// If we're entering at the bottom rung, don't allow climbing off it again until
		// we release the stick and re-input downward
		if (EnterRung == Params.EnteredLadder.Ladder.GetBottomRung())
			LadderComp.bDisableClimbingDownUntilReInput = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerLadderEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		LadderComp.Data.bMoving = false;

		if(LadderComp.Data.ActiveLadder != nullptr && Params.bMoveCompleted)
		{
			if (EnterRung.IsValid())
				Player.SetActorLocation(LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung));

			LadderComp.Data.ActiveLadder.PlayerAttachedToLadderEvent.Broadcast(Player,LadderComp.Data.ActiveLadder, ELadderEnterEventStates::EnterFromBottom);

			UPlayerCoreMovementEffectHandler::Trigger_Ladder_Enter_Bottom_Finished(Player);
			FLadderPlayerEventParams EventParams(Player);
			ULadderEventHandler::Trigger_OnPlayerEnteredFromBottom(LadderComp.Data.ActiveLadder, EventParams);

			Player.PlayForceFeedback(LadderComp.EnterFF, this);	
		}
		else
		{
			LadderComp.SetState(EPlayerLadderState::Inactive);
			LadderComp.DeactivateLadderClimb();
			LadderComp.AnimData.ResetData();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				FVector TargetLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung);

				StartLocation = LadderComp.Data.ActiveLadder.ActorTransform.TransformPosition(RelativeStartLocation);
				float Alpha = ActiveDuration / LadderComp.Settings.EnterFromGroundTranslationTime;
				Alpha = Math::Clamp(Alpha, 0.0, 1.0);
				FVector NewLoc = Math::Lerp(StartLocation, TargetLocation, Alpha);
				FRotator NewRot = Math::LerpShortestPath(StartRot, LadderComp.Data.ActiveLadder.ActorRotation, Alpha);

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, FVector::ZeroVector);
				Movement.SetRotation(NewRot);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}
};

