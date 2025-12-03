
class UPlayerLadderExitOnBottomCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderExit);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 22;
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;
	UHazeCameraUserComponent CameraUserComp;
	ALadder Ladder;

	FVector InitialForwardVector;
	FVector TargetDirection;
	FRotator ExitRotation;

	const float DISTANCE_TRACE_GROUND = 100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
		CameraUserComp = UHazeCameraUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;

		if (LadderComp.Data.ActiveLadder.bBlockBottomExit)
			return false;

		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y > -0.25)
			return false;

		if (LadderComp.bDisableClimbingDownUntilReInput)
			return false;

		// If there is still a rung below the player, don't exit
		FLadderRung RungBelowPlayer = LadderComp.Data.ActiveLadder.GetClosestRungBelowWorldLocation(Player.ActorLocation);
		if (RungBelowPlayer.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration > LadderComp.Settings.BottomExitDuration)
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

		//Clear our Camera Clamps assigned by LadderClimbCapability
		CameraUserComp.CameraSettings.Clamps.Clear(LadderComp);

		//Slightly offset our initial rotation to make sure we rotate clockwise
		Player.RootOffsetComponent.SnapToRotation(this, FRotator::MakeFromXZ(InitialForwardVector, MoveComp.WorldUp).Quaternion());
		Player.RootOffsetComponent.FreezeRotationAndLerpBackToParent(this, LadderComp.Settings.BottomExitDuration);
		LadderComp.SetState(EPlayerLadderState::ExitOnBottom);
		LadderComp.DeactivateLadderClimb();

		//Trace for ground to decide if we perform let go or grounded exit
		FHazeTraceSettings GroundTrace = Trace::InitFromMovementComponent(MoveComp);
		FHitResult GroundHit = GroundTrace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation + (-MoveComp.WorldUp * DISTANCE_TRACE_GROUND));
		if(GroundHit.bBlockingHit && GroundHit.Component.HasTag(ComponentTags::Walkable))
			LadderComp.AnimData.bValidGroundExitFound = true;

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Exit_Bottom_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);

		Ladder.PlayerExitedLadderEvent.Broadcast(Player, Ladder, ELadderExitEventStates::ExitOnBottom);
		Player.MeshOffsetComponent.ClearOffset(this);

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Exit_Bottom_Finished(Player);	
		FLadderPlayerEventParams EventParams(Player);
		ULadderEventHandler::Trigger_OnPlayerExitedFromBottom(Ladder, EventParams);

		Ladder = nullptr;

		LadderComp.VerifyExitStateCompleted(EPlayerLadderState::ExitOnBottom);
		Player.PlayForceFeedback(LadderComp.EnterFF, this , 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddVelocity(TargetDirection * 60.0);
				Movement.SetRotation(ExitRotation);
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
				Movement.ApplyCrumbSyncedAirMovement();

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}
};

