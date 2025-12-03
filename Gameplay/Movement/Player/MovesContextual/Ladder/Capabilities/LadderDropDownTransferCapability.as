
class ULadderDropDownTransferCapability : UHazePlayerCapability
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
	UPlayerAirMotionComponent AirMotionComp;

	ALadder TargetLadder;
	FVector TargetRelativeStartLocation;
	FVector TargetRelativeEndLocation;
	FLadderRung TargetRung;

	/**
	 * This capability needs to inherit the velocity in a way the dash doesnt need to = we probably dont want to use the dash calculator for this
	 * Rather we would probably simulate gravity for the fall with a harsh stop based on our current speed when we start the capability
	 * we also want to maintain velocity to blend out into sliding down again
	 * 
	 */

	bool bMoveCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;	

		if (LadderComp.bDisableClimbingUpUntilReInput)
			return false;

		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y > -0.25)
			return false;

		// If there is still a rung above the player, don't exit
		FLadderRung RungBelowPlayer = LadderComp.Data.ActiveLadder.GetClosestRungBelowWorldLocation(Player.ActorLocation);
		if (RungBelowPlayer.IsValid())
			return false;	

		//here we could branch later depending on if we can transfer other directions then upwards
		if (LadderComp.Data.ActiveLadder.LadderType == ELadderType::BottomSegmented && LadderComp.Data.ActiveLadder.LadderType == ELadderType::Default)
			return false;
		
		if (LadderComp.Data.ActiveLadder.LinkedLadder == nullptr)
			return false;

		if (LadderComp.Data.ActiveLadder.LinkedLadder.LadderType != ELadderType::BottomSegmented)
			return false;

		if (!LadderComp.Data.ActiveLadder.LinkedLadder.bAllowTransfer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerLadderDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnAnyGround())
			return true;

		if (bMoveCompleted)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		if (TargetLadder == nullptr)
			return true;

		if (!TargetLadder.bAllowTransfer)
			return true;
		
		FVector WorldLocation = TargetLadder.ActorRelativeTransform.InverseTransformPosition(TargetRelativeEndLocation);
		if ((WorldLocation - Player.ActorLocation).GetSafeNormal().DotProduct(MoveComp.WorldUp) >= 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);
		ALadder Ladder = LadderComp.Data.ActiveLadder;
		TargetLadder = Ladder.LinkedLadder;
		MoveComp.FollowComponentMovement(TargetLadder.RootComp,this, EMovementFollowComponentType::ReferenceFrame);

		bMoveCompleted = false;

		Player.ApplyCameraSettings(Ladder.CameraSetting, 0, this, SubPriority = 25);

		LadderComp.DeactivateLadderClimb();
		LadderComp.SetState(EPlayerLadderState::TransferDown);
		LadderComp.Data.bMoving = true;

		//Get our endlocation based on targetladder
		TargetRung = Ladder.LinkedLadder.GetClosestRungToWorldLocation(Player.ActorLocation);

		FVector TargetRungLocation = (Ladder.LinkedLadder.GetRungWorldLocation(TargetRung));
		TargetRelativeStartLocation = TargetLadder.ActorRelativeTransform.TransformPosition(Player.ActorLocation);
		TargetRelativeEndLocation = TargetLadder.ActorRelativeTransform.TransformPosition(TargetRungLocation);
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
			Player.SetActorLocation(TargetLadder.ActorRelativeTransform.InverseTransformPosition(TargetRelativeEndLocation));

			LadderComp.ActivateLadderClimb(TargetLadder);
			LadderComp.Data.bMoving = false;
			Player.PlayForceFeedback(LadderComp.DashFF, false, true, this);

			if(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y > -0.25)
				Player.SetActorVerticalVelocity(-MoveComp.WorldUp * Math::Min(Player.ActorVerticalVelocity.DotProduct(-MoveComp.WorldUp), 800));
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

				FVector ToTarget = TargetLadder.ActorRelativeTransform.InverseTransformPosition(TargetRelativeEndLocation) - Player.ActorLocation;
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(ToTarget.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal(), MoveComp.HorizontalVelocity, DeltaTime, 0.3);

				if((AirControlVelocity.Size() * DeltaTime) > ToTarget.ConstrainToPlane(MoveComp.WorldUp).Size())
				{	
					FVector HorizontalDelta = ToTarget.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * ToTarget.ConstrainToPlane(MoveComp.WorldUp).Size();
					
					//Move us the final distance required and cancel our velocity
					// This will however make it so that if we are moving towards a moving ladder, if we reach it before we finish our vertical translation then it would speed away from us again
					Movement.AddDeltaWithCustomVelocity(HorizontalDelta, -MoveComp.HorizontalVelocity);
				}
				else
					Movement.AddHorizontalVelocity(AirControlVelocity);

				//If we would go past our current rung vertically with our current move
				if(ToTarget.ConstrainToDirection(-MoveComp.WorldUp).Size() <= (MoveComp.VerticalVelocity.Size() * DeltaTime))
				{
					//check if we are within horizontal reach
					if(ToTarget.ConstrainToPlane(MoveComp.WorldUp).Size() <= 5)
					{
						FVector VerticalDelta = ToTarget.ConstrainToDirection(-MoveComp.WorldUp).GetSafeNormal() * ToTarget.ConstrainToDirection(MoveComp.WorldUp).Size();
						Movement.AddDeltaWithCustomVelocity(VerticalDelta, IsLastRung() ? -MoveComp.VerticalVelocity : MoveComp.VerticalVelocity);
						bMoveCompleted = true;
					}
					else
					{
						//If not we check if we have a rung below the current target and make it our new target
						GetNextRung();

						//since we have a new target we keep adding gravity
						Movement.AddOwnerVerticalVelocity();
						Movement.AddGravityAcceleration();
					}
				}
				else
				{
					//Only add gravity if we couldnt reach our target this frame
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"AirMovement", this);
		}
	}

	void GetNextRung()
	{
		FLadderRung NewTargetRung = TargetLadder.GetRungBelow(TargetRung);
		
		if(!NewTargetRung.IsValid())
			return;
		
		TargetRung = NewTargetRung;

		FVector TargetRungLocation = (TargetLadder.GetRungWorldLocation(TargetRung));
		TargetRelativeEndLocation = TargetLadder.ActorRelativeTransform.TransformPosition(TargetRungLocation);
	}

	bool IsLastRung()
	{
		FLadderRung NewTargetRung = TargetLadder.GetRungBelow(TargetRung);
		return !NewTargetRung.IsValid();
	}
};