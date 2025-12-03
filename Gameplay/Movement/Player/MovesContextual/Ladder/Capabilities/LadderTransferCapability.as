struct FPlayerLadderTransferActivationParams
{
	FLadderRung TargetRung;
}

struct FPlayerLadderDeactivationParams
{
	bool bMoveCompleted = false;
}

class ULadderTransferCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;

	FDashMovementCalculator DashCalculator;

	ALadder TargetLadder;
	FVector TargetRelativeEndLocation;

	/**
	 * Dashing into transfer can cause the animation timing to be off, cooldown isnt respected here, we arent blending out into MH or movement and our dash cant reset.
	 */

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLadderTransferActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;	

		if (LadderComp.Data.ActiveLadder.LinkedLadder == nullptr)
			return false;

		if (LadderComp.bDisableClimbingUpUntilReInput)
			return false;

		if (LadderComp.GetState() != EPlayerLadderState::MH && LadderComp.GetState() != EPlayerLadderState::ClimbDown)
			return false;

		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y < 0.25)
			return false;

		// If there is still a rung above the player, don't exit
		FLadderRung RungAbovePlayer = LadderComp.Data.ActiveLadder.GetClosestRungAboveWorldLocation(Player.ActorLocation);
		if (RungAbovePlayer.IsValid())
			return false;
		
		FLadderRung TargetRung = LadderComp.Data.ActiveLadder.LinkedLadder.GetClosestRungToWorldLocation(Player.ActorLocation);
		if (!ToTargetDeltaWithinReach(TargetRung))
			return false;

		//here we could branch later depending on if we can transfer other directions then upwards
		if (LadderComp.Data.ActiveLadder.LadderType != ELadderType::BottomSegmented)
			return false;
		
		if (LadderComp.Data.ActiveLadder.LinkedLadder.LadderType != ELadderType::TopSegmented)
			return false;

		if (!LadderComp.Data.ActiveLadder.LinkedLadder.bAllowTransfer)
			return false;
		
		Params.TargetRung = TargetRung;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerLadderDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= DashCalculator.GetTotalDashDuration())
		{
			Params.bMoveCompleted = true;
			return true;
		}

		if (TargetLadder == nullptr)
			return true;

		if (!TargetLadder.bAllowTransfer)
			return true;

		return false;
	}

	bool ToTargetDeltaWithinReach(FLadderRung TargetRung) const
	{
		float ToTargetDelta = (LadderComp.Data.ActiveLadder.LinkedLadder.GetRungWorldLocation(TargetRung) - (Player.ActorLocation)).ConstrainToDirection(MoveComp.WorldUp).Size();

		if(ToTargetDelta > LadderComp.Settings.TransferMaxDistance + 5)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLadderTransferActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		ALadder Ladder = LadderComp.Data.ActiveLadder;
		TargetLadder = Ladder.LinkedLadder;
		
		LadderComp.DeactivateLadderClimb();
		MoveComp.FollowComponentMovement(TargetLadder.RootComp,this, EMovementFollowComponentType::ReferenceFrame);
		LadderComp.SetState(EPlayerLadderState::TransferUp);
		LadderComp.AnimData.bTransferUpInitiated = true;

		//Get our endlocation based on targetladder
		FVector TargetRungLocation = (Ladder.LinkedLadder.GetRungWorldLocation(Params.TargetRung));
		TargetRelativeEndLocation = TargetLadder.ActorTransform.InverseTransformPosition(TargetRungLocation);

		float CurrentSpeed = Ladder.ActorUpVector.DotProduct(MoveComp.Velocity);
		float RealDistance = Math::Abs((TargetRungLocation - Player.ActorLocation).Size());
		LadderComp.Data.bMoving = true;

		DashCalculator = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			RealDistance,
			LadderComp.Settings.TransferUpDuration,
			LadderComp.Settings.TransferUpAccelerationDuration,
			LadderComp.Settings.TransferUpDecelerationDuration,
			CurrentSpeed, 0.0
		);

		Player.ApplyCameraSettings(Ladder.CameraSetting, 0, this, SubPriority = 25);

		Player.SetActorVelocity(FVector::ZeroVector);

		Player.PlayForceFeedback(LadderComp.DashFF, false, true, this);

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Dash_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerLadderDeactivationParams Params)
	{		
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		Player.ClearCameraSettingsByInstigator(this, 3);

		if(Params.bMoveCompleted)
		{
			Player.SetActorLocation(TargetLadder.ActorTransform.TransformPosition(TargetRelativeEndLocation));
			LadderComp.ActivateLadderClimb(TargetLadder);
			LadderComp.Data.bMoving = false;
			UPlayerCoreMovementEffectHandler::Trigger_Ladder_Dash_Finished(Player);
		}
		else
		{
			LadderComp.Data.ResetData();
			LadderComp.AnimData.ResetData();
			LadderComp.SetState(EPlayerLadderState::Inactive);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{	
				Movement.SetRotation(LadderComp.CalculatePlayerCapsuleRotation(TargetLadder));

				float FrameMovement;
				float FrameSpeed;

				DashCalculator.CalculateMovement(
					ActiveDuration, DeltaTime,
					FrameMovement, FrameSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					(TargetLadder.ActorTransform.TransformPosition(TargetRelativeEndLocation) - Player.ActorLocation).GetSafeNormal() * FrameMovement,
					(TargetLadder.ActorTransform.TransformPosition(TargetRelativeEndLocation) - Player.ActorLocation).GetSafeNormal() * FrameSpeed,
					EMovementDeltaType::Native
				);
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