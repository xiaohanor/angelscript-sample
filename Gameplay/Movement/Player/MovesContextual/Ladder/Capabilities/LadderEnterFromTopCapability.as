struct FPlayerLadderEnterDeactivationParams
{
	bool bMoveCompleted = false;
}

class UPlayerLadderEnterFromTopCapability : UHazePlayerCapability
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

	FVector StartLocation;
	FVector RelativeStartLocation;

	FRotator StartRot;
	FRotator TargetRot;
	FLadderRung EnterRung;

	bool bHasActiveEnterCameraSettings = false;

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

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if (LadderComp.State != EPlayerLadderState::Inactive)
			return false;

		if (LadderComp.Data.QueryTopEnterLadders.IsEmpty())
			return false;

		if (!LadderComp.TestForValidTopEnter())
			return false;

		if (LadderComp.Data.EnterFromTopLadder == nullptr)
			return false;

		if (LadderComp.Data.EnterFromTopTriggeredFrame != 0 && LadderComp.Data.EnterFromTopTriggeredFrame >= Time::FrameNumber - 1)
			return false;

		Params.EnteredLadder.Ladder = LadderComp.Data.EnterFromTopLadder;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerLadderEnterDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= LadderComp.Settings.EnterFromTopDuration)
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
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(PlayerLadderTags::LadderExit, this);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		LadderComp.ActivateLadderClimb(Params.EnteredLadder.Ladder);
		LadderComp.Data.EnterFromTopLadder = nullptr;

		EnterRung = LadderComp.Data.ActiveLadder.GetTopRung();

		LadderComp.Data.bMoving = true;
		LadderComp.SetState(EPlayerLadderState::EnterFromTop);

		// When entering from top, we disable climbing up until the input is dropped,
		// so we don't immediately exit again due to forwards input now being upwards input
		LadderComp.bDisableClimbingUpUntilReInput = true;

		//Check our Facing direction compared to target direction for animation purposes
		FVector TargetLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung);
		FVector ToLadderDirection = TargetLocation - Player.ActorLocation;
		FVector ToLadderConstrained = ToLadderDirection.ConstrainToPlane(MoveComp.WorldUp);
		FVector PlayerTargetOrientation = ToLadderConstrained * -1;

		float PlayerFacingToTargetDot = PlayerTargetOrientation.GetSafeNormal().DotProduct(Player.ActorForwardVector);
		float RadianDelta = Math::Acos(PlayerFacingToTargetDot);
		float DegreeDelta = Math::RadiansToDegrees(RadianDelta);
		float FacingDegreeDelta = DegreeDelta;

		//Check location and rotation to check if we should avoid the freezelocationLerp and just move capsule straight down from here
		float PlayerLocationToTargetDot = ToLadderConstrained.GetSafeNormal().DotProduct(-LadderComp.Data.ActiveLadder.ActorForwardVector);
		RadianDelta = Math::Acos(PlayerLocationToTargetDot);
		DegreeDelta = Math::RadiansToDegrees(RadianDelta);

		//Confirm our position / rotation towards ladder and select appropriate animation
		if(DegreeDelta < LadderComp.Settings.EnterFromTopForwardAngleCutoff)
		{
			StartLocation = LadderComp.Data.ActiveLadder.Interact.WorldLocation;

			Player.GetMeshOffsetComponent().FreezeRelativeTransformAndLerpBackToParent(this, LadderComp.Data.ActiveLadder.RootComp, LadderComp.Settings.EnterFromTopCapsuleOffsetDuration);
			Player.SetActorLocation(StartLocation);

			if(FacingDegreeDelta < LadderComp.Settings.EnterFromTopForwardAngleCutoff)
			{
				LadderComp.AnimData.bFacingLadderForward = true;
			}
			else
			{
				float PlayerToLadderRightDot = Player.ActorForwardVector.DotProduct(LadderComp.Data.ActiveLadder.ActorRightVector);

				if(PlayerToLadderRightDot > 0)
					LadderComp.AnimData.bEnterRotateCounterClockwise = true;				
				else
					LadderComp.AnimData.bEnterRotateClockwise = true;
			}
		}
		else
		{
			StartLocation = Player.ActorLocation;

			if(ToLadderConstrained.GetSafeNormal().DotProduct(LadderComp.Data.ActiveLadder.ActorRightVector) > 0)
			{
				if(Player.ActorForwardVector.DotProduct(LadderComp.Data.ActiveLadder.ActorRightVector) > 0.3)
					LadderComp.AnimData.bEnterRotateClockwise = true;
				else if(Player.ActorForwardVector.DotProduct(LadderComp.Data.ActiveLadder.ActorRightVector) < -0.3)
					LadderComp.AnimData.bEnterRotateClockwise = true;
				else
				{
					if(Player.ActorForwardVector.DotProduct(LadderComp.Data.ActiveLadder.ActorForwardVector) > 0)
						LadderComp.AnimData.bEnterRotateClockwise = true;
					else
						LadderComp.AnimData.bEnterRotateCounterClockwise = true;
				}
			}
			else
			{
				if(Player.ActorForwardVector.DotProduct(LadderComp.Data.ActiveLadder.ActorRightVector) > 0.3)
					LadderComp.AnimData.bEnterRotateCounterClockwise = true;
				else if(Player.ActorForwardVector.DotProduct(LadderComp.Data.ActiveLadder.ActorRightVector) < -0.3)
					LadderComp.AnimData.bEnterRotateCounterClockwise = true;
				else
				{
					if(Player.ActorForwardVector.DotProduct(LadderComp.Data.ActiveLadder.ActorForwardVector) > 0)
						LadderComp.AnimData.bEnterRotateCounterClockwise = true;
					else
						LadderComp.AnimData.bEnterRotateClockwise = true;
				}
			}
		}

		RelativeStartLocation = LadderComp.Data.ActiveLadder.ActorTransform.InverseTransformPosition(StartLocation);
		StartRot = Player.ActorRotation;
		TargetRot = LadderComp.Data.ActiveLadder.ActorRotation;

		if(Player.IsMovementCameraBehaviorEnabled())
		{
			bHasActiveEnterCameraSettings = true;
			UCameraSettings::GetSettings(Player).WorldPivotOffset.Apply(MoveComp.WorldUp * (Player.GetScaledCapsuleHalfHeight()), this, 0);
		}
		else
			bHasActiveEnterCameraSettings = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerLadderEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(PlayerLadderTags::LadderExit, this);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		LadderComp.Data.bMoving = false;
		LadderComp.AnimData.bEnterRotateClockwise = false;
		LadderComp.AnimData.bEnterRotateCounterClockwise = false;
		LadderComp.AnimData.bFacingLadderForward = false;

		if(LadderComp.Data.ActiveLadder != nullptr && Params.bMoveCompleted)
		{
			if (EnterRung.IsValid())
				Player.SetActorLocation(LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung));

			LadderComp.Data.ActiveLadder.PlayerAttachedToLadderEvent.Broadcast(Player, LadderComp.Data.ActiveLadder, ELadderEnterEventStates::EnterFromTop);

			UPlayerCoreMovementEffectHandler::Trigger_Ladder_Enter_Top_Finished(Player);
			FLadderPlayerEventParams EventParams(Player);
			ULadderEventHandler::Trigger_OnPlayerEnteredFromTop(LadderComp.Data.ActiveLadder, EventParams);

			Player.PlayForceFeedback(LadderComp.EnterFF, this);
		}
		else
		{
			LadderComp.SetState(EPlayerLadderState::Inactive);
			LadderComp.DeactivateLadderClimb();
			LadderComp.AnimData.ResetData();
		}

		UCameraSettings::GetSettings(Player).WorldPivotOffset.Clear(this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			float Alpha = Math::Clamp(ActiveDuration / LadderComp.Settings.EnterFromTopDuration, 0, 1);
			FRotator NewRot = Math::LerpShortestPath(StartRot, LadderComp.Data.ActiveLadder.ActorRotation, Alpha);

			if(HasControl())
			{	
				FVector TargetLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(EnterRung);
				StartLocation = LadderComp.Data.ActiveLadder.ActorTransform.TransformPosition(RelativeStartLocation);
				
				FVector NewLoc = Math::Lerp(StartLocation, TargetLocation, Alpha);
				FVector Delta = NewLoc - Player.ActorLocation;

				Movement.AddDelta(Delta);
				Movement.SetRotation(NewRot);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
				Movement.SetRotation(NewRot);
			}
			
			if(bHasActiveEnterCameraSettings)
			{
				float BlendInDuration = LadderComp.Settings.EnterFromTopDuration * 0.6;
				float CameraFraction = ActiveDuration <= BlendInDuration ?
										 LadderComp.TopEnterCameraOffsetBlendInCurve.GetFloatValue((ActiveDuration) / BlendInDuration) :
										 	 LadderComp.TopEnterCameraOffsetBlendOutCurve.GetFloatValue((ActiveDuration - BlendInDuration) / (LadderComp.Settings.EnterFromTopDuration - BlendInDuration));
											 
				UCameraSettings::GetSettings(Player).WorldPivotOffset.SetManualFraction(CameraFraction, this);
			}

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}
};

