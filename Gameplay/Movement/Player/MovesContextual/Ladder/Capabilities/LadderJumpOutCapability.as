
class UPlayerLadderJumpOutCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderExit);
	default CapabilityTags.Add(PlayerLadderTags::LadderJumpOut);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;	
	default TickGroupSubPlacement = 3;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 20, 3);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USteppingMovementData Movement;
	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerLadderComponent LadderComp;
	UHazeCameraUserComponent CameraComp;

	ALadder Ladder;
	float ExitTimer = 0;
	float JumpOutBlockTimer;
	
	FVector JumpDir;
	FVector InitialDirection = FVector::ZeroVector;

	bool bUnblockedCapabilities = false;
	bool bHasTriggeredJumpOut = false;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (LadderComp.IsClimbing())
		{
			if (JumpOutBlockTimer < LadderComp.Settings.JumpOutInitialBlockedDuration)
			{
				JumpOutBlockTimer += DeltaTime;
			}
		}
		else
			JumpOutBlockTimer = 0;	
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		CameraComp = UHazeCameraUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (JumpOutBlockTimer < LadderComp.Settings.JumpOutInitialBlockedDuration)
			return false;

		// if (MoveComp.MovementInput.DotProduct(LadderComp.Data.ActiveLadder.ActorForwardVector) > -0.1)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if(ExitTimer >= LadderComp.Settings.JumpExitNoInputTime + LadderComp.Settings.ExitInputBlendInTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

        JumpDir = (Player.ActorForwardVector * -1.0).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		Ladder = LadderComp.Data.ActiveLadder;
		LadderComp.SetState(EPlayerLadderState::JumpOut);

		InitialDirection = -Player.ActorRotation.ForwardVector;

		// Snap our Camera Clamps (Set by LadderClimbCapability but will be 1 frame late if we leave it to be cleared there)
		CameraComp.CameraSettings.Clamps.Clear(LadderComp);	

		LadderComp.Data.ActiveLadder.PlayerExitedLadderEvent.Broadcast(Player, Ladder ,ELadderExitEventStates::JumpOut);
		
		UPlayerCoreMovementEffectHandler::Trigger_Ladder_JumpOut(Player);
		FLadderPlayerEventParams EventParams(Player);
		ULadderEventHandler::Trigger_OnPlayerExitedByJumpingOut(Ladder, EventParams);

        LadderComp.DeactivateLadderClimb();
		Player.PlayForceFeedback(LadderComp.JumpOutFF, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bUnblockedCapabilities)
			Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);

		Ladder = nullptr;
		bHasTriggeredJumpOut = false;
		bUnblockedCapabilities = false;
		ExitTimer = 0;

		LadderComp.VerifyExitStateCompleted(EPlayerLadderState::JumpOut);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			ExitTimer += DeltaTime;
			if(HasControl())
			{
				if(!bHasTriggeredJumpOut)
				{
					//Check if we have delayed enough for anticipation
					if(ExitTimer >= LadderComp.Settings.JumpOutAnticipationDelay)
					{
						//Set our initial velocity
						bHasTriggeredJumpOut = true;
						Movement.AddHorizontalVelocity(JumpDir * 550);
						Movement.AddVerticalVelocity(MoveComp.WorldUp * 900);

						//Clear our constraint to snap the capsule to align with worldup again
						MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
						Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(n"LadderResetLocation", LadderComp.Settings.JumpExitNoInputTime / 2);
						Player.RootOffsetComponent.FreezeRotationAndLerpBackToParent(n"LadderResetRotation", LadderComp.Settings.JumpExitNoInputTime);
					}

					FRotator NewRot = FRotator::MakeFromXZ(-Ladder.ActorForwardVector, Ladder.ActorUpVector);
					Movement.SetRotation(NewRot);
				}
				else
				{
					//Handle our air motion if we are past the anticipation duration and have handled initial velocity change
					const float InputScale = (ExitTimer - LadderComp.Settings.JumpExitNoInputTime) / LadderComp.Settings.ExitInputBlendInTime;

					FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();
					FVector VerticalVelocity = MoveComp.GetVerticalVelocity();

					HorizontalVelocity = AirMotionComp.CalculateStandardAirControlVelocity(MoveComp.MovementInput, HorizontalVelocity, DeltaTime, InputScale);

					const float GravityLerpTime = LadderComp.Settings.JumpGravityBlendInTime;
					const float GravityScale = Math::Min(ActiveDuration / GravityLerpTime, 1.0);
					VerticalVelocity -= MoveComp.WorldUp * MoveComp.GravityForce * GravityScale * DeltaTime;

					Movement.AddHorizontalVelocity(HorizontalVelocity);
					Movement.AddVerticalVelocity(VerticalVelocity);

					//If we are within the no input time then rotate up the capsule
					if(ExitTimer <= (LadderComp.Settings.JumpExitNoInputTime + LadderComp.Settings.JumpOutAnticipationDelay))
					{
						float Alpha = Math::Clamp((ExitTimer - LadderComp.Settings.JumpOutAnticipationDelay) / LadderComp.Settings.JumpExitNoInputTime, 0, 1);
						FQuat InitialQuat = FQuat::MakeFromXZ(-Ladder.ActorForwardVector, Ladder.ActorUpVector);
						FQuat TargetQuat = FQuat::MakeFromXZ(-Ladder.ActorForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal(), MoveComp.WorldUp);
						FQuat NewRotQuat = FQuat::Slerp(InitialQuat, TargetQuat, Alpha);
						Movement.SetRotation(NewRotQuat.Rotator());
					}
					else
					{
						//Else rotate based on velocity direction
						FRotator TargetRotation = FRotator::MakeFromXZ(HorizontalVelocity.GetSafeNormal(), MoveComp.WorldUp);
						Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 340.0));
					}
				}
				Movement.OverrideStepDownAmountForThisFrame(0.0);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();

				//Override the crumb lerped rotation here and just snap if its the first frame
				if(ActiveDuration == 0)
					Movement.SetRotation(FRotator::MakeFromXZ(-Ladder.ActorForwardVector, Ladder.ActorUpVector));
			}

			if(!bUnblockedCapabilities && ExitTimer > LadderComp.Settings.JumpExitNoInputTime)
			{
				Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
				bUnblockedCapabilities = true;
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}
};

