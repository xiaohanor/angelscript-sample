
class USnowMonkeyLedgeGrabClimbCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabClimb);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 10;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	USnowMonkeyLedgeGrabComponent LedgeGrabComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData TeleportMovement;
	USteppingMovementData StepdownMovement;

	bool bReachedTarget = false;
	float MoveSpeed = 0.0;
	FVector RelativeTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		TeleportMovement = MoveComp.SetupTeleportingMovementData();
		StepdownMovement = MoveComp.SetupSteppingMovementData();

		LedgeGrabComp = USnowMonkeyLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSnowMonkeyLedgeGrabClimbActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (LedgeGrabComp.State != ESnowMonkeyLedgeGrabState::LedgeGrab)
			return false;
		
		FSnowMonkeyLedgeGrabClimbData ClimbData;
		if (!LedgeGrabComp.TraceClimbUp(Player, ClimbData, IsDebugActive()))
			return false;
		
		if (!ClimbData.HitComponent.HasTag(ComponentTags::LedgeClimbable))
			return false;
		
		ActivationParams.ClimbData = ClimbData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (bReachedTarget)
			return true;

		if (ActiveDuration >= LedgeGrabComp.ClimbSettings.ClimbUpDuration)
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
		LedgeGrabComp.ClimbUpState = ActivationParams.ClimbData.bClimbIntoCrouch ? ESnowMonkeyLedgeGrabClimbState::ClimbToIdleCrouch : ESnowMonkeyLedgeGrabClimbState::ClimbToIdle;
		LedgeGrabComp.ClimbData = ActivationParams.ClimbData;

		//Assign a component relative target location to make sure we climb up correctly on moving targets
		RelativeTargetLocation = LedgeGrabComp.ClimbData.HitComponent.WorldTransform.InverseTransformPosition(LedgeGrabComp.ClimbData.TargetLocation);

		//Make sure we follow the component we are grabbings movement
		MoveComp.FollowComponentMovement(LedgeGrabComp.ClimbData.HitComponent, this, EMovementFollowComponentType::Teleport);

		bReachedTarget = false;
		MoveSpeed = (LedgeGrabComp.ClimbData.TargetLocation - Owner.ActorLocation).Size() / LedgeGrabComp.ClimbSettings.ClimbUpDuration;

		if (LedgeGrabComp.GetClimbState() == ESnowMonkeyLedgeGrabClimbState::ClimbToIdleCrouch)
			Player.CapsuleComponent.OverrideCapsuleHalfHeight(LedgeGrabComp.CrouchSettings.CapsuleHalfHeight, this);


	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeGrab, this);

		if (LedgeGrabComp.GetClimbState() == ESnowMonkeyLedgeGrabClimbState::ClimbToIdleCrouch)
			Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
		
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.TransitionCrumbSyncedPosition(this);

		// Since we used to be in air, but are now grounded,
		// we dont want to play the landing animations
		MoveComp.OverridePreviousGroundContactWithCurrent();

		LedgeGrabComp.ResetLedgeGrab();

		//Clear eventual settings pushed in LedgeGrabCapability as SnowMonkey
		UCameraSettings::GetSettings(Player).PivotLagMax.Clear(LedgeGrabComp, 0.5);
		UCameraSettings::GetSettings(Player).PivotLagAccelerationDuration.Clear(LedgeGrabComp, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		// TODO [AL/TC]: The first 0.2 seconds should go to the flat ledge location. The rest should go to the actual target location to ensure the hands are planted.
		FVector TransformedRelativeTargetLocation = LedgeGrabComp.ClimbData.HitComponent.WorldTransform.TransformPosition(RelativeTargetLocation);
		FVector ToTarget = TransformedRelativeTargetLocation - Owner.ActorLocation;

		const float Delta = MoveSpeed * DeltaTime;

		if (!bReachedTarget && ToTarget.Size() < Delta + KINDA_SMALL_NUMBER)
			bReachedTarget = true;

		// Stepdown
		if (bReachedTarget)
		{
			if (MoveComp.PrepareMove(StepdownMovement))
			{
				StepdownMovement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, LedgeGrabComp.Data.PlayerRotation, DeltaTime, 360.0));		
				StepdownMovement.OverrideFinalGroundResult(LedgeGrabComp.ClimbData.Hit);
				StepdownMovement.AddDeltaWithCustomVelocity(ToTarget, FVector::ZeroVector);
	
				MoveComp.ApplyMoveAndRequestLocomotion(StepdownMovement, n"LedgeGrab");
			}
		}
		// Teleport move up to the ground location
		else
		{
			if (MoveComp.PrepareMove(TeleportMovement))
			{
				TeleportMovement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, LedgeGrabComp.Data.PlayerRotation, DeltaTime, 360.0));
				for (UPrimitiveComponent Primitive : LedgeGrabComp.Data.HitComponents)
					TeleportMovement.IgnorePrimitiveForThisFrame(Primitive);
			
				TeleportMovement.AddDelta(ToTarget.GetSafeNormal() * Delta);
	
				MoveComp.ApplyMoveAndRequestLocomotion(TeleportMovement, n"LedgeGrab");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		
	}
}

struct FSnowMonkeyLedgeGrabClimbActivationParams
{
	FSnowMonkeyLedgeGrabClimbData ClimbData;
}