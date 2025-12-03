
class USnowMonkeyLedgeGrabClimbIntoMovementCapability : UHazePlayerCapability
{
	/*
	 *	This capability performs a climb up from ledge grab onto ledge/platform and exits with velocity
	 */

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabClimb);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 9;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	USnowMonkeyLedgeGrabComponent LedgeGrabComp;
	UPlayerCrouchComponent CrouchComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData TeleportMovement;
	USteppingMovementData StepdownMovement;

	bool bReachedTarget;
	float MoveSpeed = 0.0;
	FVector RelativeTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		StepdownMovement = MoveComp.SetupSteppingMovementData();
		TeleportMovement = MoveComp.SetupTeleportingMovementData();
	
		LedgeGrabComp = USnowMonkeyLedgeGrabComponent::GetOrCreate(Player);
		CrouchComp = UPlayerCrouchComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSnowMonkeyLedgeGrabClimbActivationParams& ActivationParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(LedgeGrabComp.State != ESnowMonkeyLedgeGrabState::LedgeGrab)
			return false;

		if(!VerifyInputSizeAndDirection())
			return false;

		if(!IsActioning(ActionNames::MovementJump))
			return false;
		
		FSnowMonkeyLedgeGrabClimbData ClimbData;
		ClimbData.bClimbIntoMotion = true;
		if(!LedgeGrabComp.TraceClimbUp(Player, ClimbData, IsDebugActive()))
			return false;

		if(!ClimbData.HitComponent.HasTag(ComponentTags::LedgeClimbable))
			return false;
		
		ActivationParams.ClimbData = ClimbData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		
		if(bReachedTarget)
			return true;

		if(ActiveDuration >= LedgeGrabComp.ClimbSettings.ClimbUpDuration)
			return true;

		if (LedgeGrabComp.State != ESnowMonkeyLedgeGrabState::Climb)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSnowMonkeyLedgeGrabClimbActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeGrab, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		LedgeGrabComp.State = ESnowMonkeyLedgeGrabState::Climb;
		LedgeGrabComp.ClimbUpState = ActivationParams.ClimbData.bClimbIntoCrouch ? ESnowMonkeyLedgeGrabClimbState::ClimbToMovingCrouch : ESnowMonkeyLedgeGrabClimbState::ClimbToMoving;
		LedgeGrabComp.ClimbData = ActivationParams.ClimbData;

		//Make sure we follow the component we are grabbings movement (if we want to resolve collision we have to assign the movecomp to ignore the actor, which would cause issues with the stepdown on the final tick)
		MoveComp.FollowComponentMovement(LedgeGrabComp.ClimbData.HitComponent, this, EMovementFollowComponentType::Teleport);

		RelativeTargetLocation = LedgeGrabComp.ClimbData.HitComponent.WorldTransform.InverseTransformPosition(LedgeGrabComp.ClimbData.TargetLocation);

		bReachedTarget = false;
		MoveSpeed = (LedgeGrabComp.ClimbData.TargetLocation - Player.ActorLocation).Size() / LedgeGrabComp.ClimbSettings.ClimbUpDuration;

		if(LedgeGrabComp.GetClimbState() == ESnowMonkeyLedgeGrabClimbState::ClimbToMovingCrouch)
			Player.CapsuleComponent.OverrideCapsuleHalfHeight(CrouchComp.Settings.CapsuleHalfHeight, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeGrab, this);

		if(LedgeGrabComp.GetClimbState() == ESnowMonkeyLedgeGrabClimbState::ClimbToMovingCrouch)
			Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		MoveComp.TransitionCrumbSyncedPosition(this);
		MoveComp.UnFollowComponentMovement(this);

		MoveComp.OverridePreviousGroundContactWithCurrent();

		LedgeGrabComp.ResetLedgeGrab();

		//Clear eventual settings pushed in LedgeGrabCapability as SnowMonkey
		UCameraSettings::GetSettings(Player).PivotLagMax.Clear(LedgeGrabComp, 0.5);
		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Clear(LedgeGrabComp, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TransformedTargetLocation = LedgeGrabComp.ClimbData.HitComponent.WorldTransform.TransformPosition(RelativeTargetLocation);
		FVector ToTarget = TransformedTargetLocation - Owner.ActorLocation;
		
		const float Delta = MoveSpeed * DeltaTime;

		if (!bReachedTarget && ToTarget.Size() < Delta + KINDA_SMALL_NUMBER)
			bReachedTarget = true;

		if(bReachedTarget)
		{
			//Final Translation frame, handle stepdown/Impact and exit velocity
			if(MoveComp.PrepareMove(StepdownMovement))
			{
				StepdownMovement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, LedgeGrabComp.Data.PlayerRotation, DeltaTime, 360.0));		
				StepdownMovement.OverrideFinalGroundResult(LedgeGrabComp.ClimbData.Hit);
				StepdownMovement.AddDeltaWithCustomVelocity(ToTarget, MoveComp.GetLastRequestedVelocityWithoutImpulse().ConstrainToPlane(MoveComp.WorldUp));
				MoveComp.ApplyMoveAndRequestLocomotion(StepdownMovement, n"LedgeGrab");
			}
		}
		else
		{
			//Teleport to ground location
			if(MoveComp.PrepareMove(TeleportMovement))
			{
				TeleportMovement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, LedgeGrabComp.Data.PlayerRotation, DeltaTime, 360.0));
				for(UPrimitiveComponent Primitive : LedgeGrabComp.Data.HitComponents)
					TeleportMovement.IgnorePrimitiveForThisFrame(Primitive);
				
				TeleportMovement.AddDelta(ToTarget.GetSafeNormal() * Delta);

				MoveComp.ApplyMoveAndRequestLocomotion(TeleportMovement, n"LedgeGrab");
			}
		}
	}

	//Verify if we are giving input, and if so are we giving input in the direction of the ledge we want to climb up?
	bool VerifyInputSizeAndDirection() const
	{
		FVector ConstrainedPlayerToLedgeDirection = (LedgeGrabComp.Data.LedgeLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		float Dot = ConstrainedPlayerToLedgeDirection.DotProduct(MoveComp.MovementInput);

		float Deg = Math::Acos(Dot);
		Deg = Math::RadiansToDegrees(Deg);

		if(Deg < 30)
			return true;
		else
			return false;
	}
}