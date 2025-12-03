class UBattlefieldHoverboardJumpBetweenGrindsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 83;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardTrickComponent TrickComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UBattlefieldHoverboardJumpSettings JumpSettings;
	UBattlefieldHoverboardGrindingSettings GrindSettings;
	UBattlefieldHoverboardTrickSettings TrickSettings;

	bool bIsFirstFrame = false;

	UBattlefieldHoverboardGrindSplineComponent GrindSplineCompJumpingTo;
	
	const float InputOffsetDistance = 500;
	const float LookAheadDirToMovementInputAngleThreshold = 30.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		JumpSettings = UBattlefieldHoverboardJumpSettings::GetSettings(Player);
		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
		TrickSettings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardJumpBetweenGrindsActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(!GrindComp.IsGrinding())
			return false;

		if(!JumpComp.bWantToJump)
			return false;

		if(!GrindComp.CurrentGrindSplineComp.bAllowJumpWhileOnGrind)
			return false;

		if(!GrindComp.CurrentGrindSplineComp.bAllowedToJumpToOtherGrind)
			return false;

		FVector MovementInput = HoverboardComp.GetMovementInputCameraSpace();
		
		if(MovementInput.IsNearlyZero())
			return false;
		
		FVector ClampedActorVelocity = Player.ActorVelocity.GetClampedToSize(GrindSettings.JumpToGrindMinSpeed, BIG_NUMBER);

		FVector LocationAheadToCheck = Player.ActorLocation 
			+ (ClampedActorVelocity * GrindSettings.VelocityDurationForJumpToGrindPointSampling);
		FVector MovementInputOffset = MovementInput * InputOffsetDistance;
		FVector LocationToCheckAgainst = LocationAheadToCheck + MovementInputOffset; 

		TEMPORAL_LOG(GrindComp)
			.Sphere("Jump between grinds: location ahead", LocationAheadToCheck, 50, FLinearColor::Red, 5)
			.DirectionalArrow("Jump between grinds: Input offset", LocationAheadToCheck, MovementInputOffset, 5, 40, FLinearColor::Purple)
			.Sphere("Jump between grinds: Location to check against", LocationToCheckAgainst, 50, FLinearColor::Blue, 5)
		;
		
		TOptional<FSplinePosition> ClosestSplinePos	= GrindComp.GetClosestGrindSplinePositionToWorldLocation(LocationToCheckAgainst, GrindSettings.MaxDistanceToGrindForJump, true);

		if(!ClosestSplinePos.IsSet())
			return false;

		TEMPORAL_LOG(GrindComp)
			.Sphere("Jump between grinds: jump to location", ClosestSplinePos.Value.WorldLocation, 50, FLinearColor::Green, 5)
		;

		FVector SplinePosToLocationAheadDir = (ClosestSplinePos.Value.WorldLocation - LocationAheadToCheck).GetSafeNormal();
		float AngleBetweenDirToSplinePosAndInput = SplinePosToLocationAheadDir.GetAngleDegreesTo(MovementInput);

		if(AngleBetweenDirToSplinePosAndInput > LookAheadDirToMovementInputAngleThreshold)
			return false;

		Params.SplinePosToJumpTo = ClosestSplinePos.Value;
		Params.GrindToLandOn = UBattlefieldHoverboardGrindSplineComponent::Get(ClosestSplinePos.Value.CurrentSpline.Owner);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!HoverboardComp.IsOn())
			return true;

		if(GrindComp.IsGrinding())
			return true;

		if(MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardJumpBetweenGrindsActivationParams Params)
	{
		JumpComp.ConsumeJumpInput();

		GrindSplineCompJumpingTo = Params.GrindToLandOn;
		GrindSplineCompJumpingTo.JumpingToGrind[Player] = true;

		float Speed = Math::Max(Player.ActorHorizontalVelocity.Size(), GrindSettings.JumpToGrindMinSpeed);
		FVector ActivationVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Player.ActorLocation, Params.SplinePosToJumpTo.WorldLocation, 
			MoveComp.GravityForce, Speed, MoveComp.WorldUp);

		Player.SetActorVelocity(ActivationVelocity);

		HoverboardComp.AnimParams.bIsJumpingBetweenGrinds = true;
		JumpComp.bJumped = true;
		JumpComp.bAirborneFromJump = true;

		bIsFirstFrame = true;
		GrindComp.bIsJumpingBetweenGrinds = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrindSplineCompJumpingTo.JumpingToGrind[Player] = false;
		HoverboardComp.AnimParams.bIsJumpingBetweenGrinds = false;
		JumpComp.bAirborneFromJump = false;
		GrindComp.bIsJumpingBetweenGrinds = false;

		if(TrickComp.CurrentTrickCombo.IsSet())
			TrickComp.IncreaseTrickMultiplier(TrickSettings.TrickMultiplierIncreasePerDifferentTrick);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FName AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardJumping;
			if(!bIsFirstFrame)
				AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardAirMovement;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);

			bIsFirstFrame = false;
		}
	}
};

struct FBattlefieldHoverboardJumpBetweenGrindsActivationParams
{
	FSplinePosition SplinePosToJumpTo;
	UBattlefieldHoverboardGrindSplineComponent GrindToLandOn;
}