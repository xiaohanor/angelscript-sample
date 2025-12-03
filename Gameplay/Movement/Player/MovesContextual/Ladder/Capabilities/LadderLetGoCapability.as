
class UPlayerLadderLetGoCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderExit);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;
	default TickGroupSubPlacement = 2;	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerLadderComponent LadderComp;
	UHazeCameraUserComponent CameraUserComp;
	ALadder Ladder;

	FVector InitialForwardVector;
	FVector TargetDirection;
	FRotator ExitRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
		CameraUserComp = UHazeCameraUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;
		
		if(!LadderComp.IsClimbing())
			return false;

		if (LadderComp.State == EPlayerLadderState::TransferUp || LadderComp.State == EPlayerLadderState::TransferDown)
			return false;

		//Force Let Go
		if (LadderComp.Data.ActiveLadder == nullptr)
			return true;
		
		//Force Let Go
		if (LadderComp.Data.ActiveLadder.IsDisabled())
			return true;
		
		//Dont allow cancel if we are currently entering ladder
		if(LadderComp.State == EPlayerLadderState::EnterFromTop
			 || LadderComp.State == EPlayerLadderState::EnterFromAir
			 	 || LadderComp.State == EPlayerLadderState::EnterFromGround)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::Cancel, 0.2))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration > LadderComp.Settings.LetGoDuration)
			return true;

		if (MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);

		Ladder = LadderComp.Data.ActiveLadder;
		ExitRotation = FRotator::MakeFromXZ((Player.ActorForwardVector * -1).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal(), MoveComp.WorldUp);
		InitialForwardVector = Player.ActorForwardVector;
		TargetDirection = ExitRotation.ForwardVector;

		//Slerping completely opposite directions wont work so slightly offset it to our right (wanted rotation direction) if detected
		if(TargetDirection.DotProduct(InitialForwardVector) < -0.999)
			InitialForwardVector += Player.ActorRightVector * 0.01;

		LadderComp.SetState(EPlayerLadderState::LetGo);

		//Slightly offset our initial rotation to make sure we rotate clockwise
		Player.RootOffsetComponent.SnapToRotation(this, FRotator::MakeFromXZ(InitialForwardVector, MoveComp.WorldUp).Quaternion());
		Player.RootOffsetComponent.FreezeRotationAndLerpBackToParent(this, LadderComp.Settings.BottomExitDuration);

		//Clear our Camera Clamps assigned by LadderClimbCapability
		CameraUserComp.CameraSettings.Clamps.Clear(LadderComp);

		Ladder.PlayerExitedLadderEvent.Broadcast(Player, LadderComp.Data.ActiveLadder ,ELadderExitEventStates::Cancel);
		
		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Cancel(Player);
		FLadderPlayerEventParams EventParams(Player);
		ULadderEventHandler::Trigger_OnPlayerExitedByCancelling(LadderComp.Data.ActiveLadder, EventParams);

		LadderComp.DeactivateLadderClimb();
		Ladder = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		LadderComp.VerifyExitStateCompleted(EPlayerLadderState::LetGo);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddVelocity(TargetDirection * 100.0);
				Movement.SetRotation(ExitRotation);

				FTemporalLog Log = TEMPORAL_LOG(this);
				Log.Rotation("VelocityDir:", ExitRotation, Player.ActorCenterLocation);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
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

