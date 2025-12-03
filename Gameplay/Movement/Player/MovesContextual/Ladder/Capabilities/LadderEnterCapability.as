class UPlayerLadderEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderEnter);

	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FVector StartLocation;
	FVector RelativeStartLocation;
	FRotator StartRotation;

	float CurrentEnterTime;
	FLadderRung EnterRung;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);

		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLadderEnterParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!MoveComp.IsInAir())
			return false;

		if (LadderComp.State != EPlayerLadderState::Inactive && LadderComp.State != EPlayerLadderState::JumpOut)
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

		if (MoveComp.Velocity.GetSafeNormal().DotProduct(LadderComp.Data.TargetLadderData.Ladder.ActorForwardVector) < 0.1 && MoveComp.MovementInput.DotProduct(LadderComp.Data.TargetLadderData.Ladder.ActorForwardVector) < 0.1 && !Player.IsAnyCapabilityActive(PlayerMovementTags::WallRun) && !LadderComp.Data.TargetLadderData.bForceEntry)
			return false;

		if ((MoveComp.MovementInput.IsNearlyZero() && MoveComp.Velocity.IsNearlyZero() && !Player.IsAnyCapabilityActive(PlayerMovementTags::WallRun)) && !LadderComp.Data.TargetLadderData.bForceEntry)
			return false;

		if (LadderComp.OnLadderCooldown() && !LadderComp.Data.TargetLadderData.bForceEntry)
			return false;

		if (LadderComp.Data.TargetLadderData.Ladder.IsDisabled())
			return false;

		if (Player.IsAnyCapabilityActive(PlayerMovementTags::WallRun))
		{
			Params.bEnteredFromWallrun = true;
		} else
		{
			Params.bEnteredFromWallrun = false;
		}

		Params.EnteredLadder = LadderComp.Data.TargetLadderData;
		Params.EnterRung = LadderComp.Data.QueryClosestRung;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerLadderEnterDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (CurrentEnterTime >= LadderComp.Settings.EnterMidLadderTime)
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
		LadderComp.SetState(EPlayerLadderState::EnterFromAir);
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

		CurrentEnterTime = 0;

		if(MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < 0 && MoveComp.VerticalVelocity.Size() >= 150 && LadderComp.Data.ActiveLadder.GetRungBelow(Params.EnterRung).IsValid())
		{
			EnterRung = LadderComp.Data.ActiveLadder.GetRungBelow(Params.EnterRung);
		}
		else
			EnterRung = Params.EnterRung;

		StartLocation = Player.ActorLocation;
		RelativeStartLocation = LadderComp.Data.ActiveLadder.ActorTransform.InverseTransformPosition(StartLocation);
		StartRotation = Player.ActorRotation;
		LadderComp.bEnteredFromWallrun = Params.bEnteredFromWallrun;

		FVector TargetLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung);

		LadderComp.SetEnterAngle(StartLocation, TargetLocation);
		LadderComp.Data.ActiveLadder.PlayerAttachedToLadderEvent.Broadcast(Player, LadderComp.Data.ActiveLadder, Params.bEnteredFromWallrun? ELadderEnterEventStates::WallRun : ELadderEnterEventStates::MidAir);

		FLadderPlayerEventParams EventParams(Player);

		if (Params.bEnteredFromWallrun)
			ULadderEventHandler::Trigger_OnPlayerEnteredFromWallRun(LadderComp.Data.ActiveLadder, EventParams);
		else
		{
			ULadderEventHandler::Trigger_OnPlayerEnteredMidAir(LadderComp.Data.ActiveLadder, EventParams);
		}

		Player.PlayForceFeedback(LadderComp.EnterFF, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerLadderEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		
		LadderComp.bEnteredFromWallrun = false;

		if(Params.bMoveCompleted)
		{
			if (PerspectiveModeComp.IsCameraBehaviorEnabled())
			{
				FHazeCameraImpulse Impulse;
				Impulse.WorldSpaceImpulse = MoveComp.WorldUp * -25;
				Impulse.ExpirationForce = 50;
				Impulse.Dampening = 0.8;
				Player.ApplyCameraImpulse(Impulse, this);
			}

			LadderComp.Data.bMoving = false;
			UPlayerCoreMovementEffectHandler::Trigger_Ladder_Enter_Airborne_Finished(Player);
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
				CurrentEnterTime += DeltaTime;

				FVector TargetLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung);
				StartLocation = LadderComp.Data.ActiveLadder.ActorTransform.TransformPosition(RelativeStartLocation);

				float Alpha = Math::Clamp(CurrentEnterTime / LadderComp.Settings.EnterMidLadderTime, 0, 1);
				Alpha = Math::Clamp(Alpha, 0.0, 1.0);
				FVector NewLoc = Math::Lerp(StartLocation, TargetLocation, Alpha);
				FRotator NewRot = Math::LerpShortestPath(StartRotation, LadderComp.Data.ActiveLadder.ActorRotation, Alpha);

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

struct FLadderEnterParams
{
	bool bEnteredFromWallrun = false;
	FQueryLadderData EnteredLadder;
	FLadderRung EnterRung;
}