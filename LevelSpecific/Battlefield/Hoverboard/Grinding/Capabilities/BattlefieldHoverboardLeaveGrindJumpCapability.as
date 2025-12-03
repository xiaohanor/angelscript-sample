struct FBattlefieldHoverboardLeaveGrindJumpActivationParams
{
	FVector PlayerRelativeMovementInput;
}

class UBattlefieldHoverboardLeaveGrindJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 85;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UPlayerMovementComponent MoveComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardGrindingSettings GrindSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardLeaveGrindJumpActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!GrindComp.IsGrinding())
			return false;

		if(!GrindComp.CurrentGrindSplineComp.bAllowJumpWhileOnGrind)
			return false;

		if(!JumpComp.bWantToJump)
			return false;


		//Note: I made this capability also activate if you are close to the end of the spline, as animation was getting stuck in grind despite no longer grinding
		FSplinePosition SplinePos = GrindComp.CurrentSplinePos;
		float RemainingDistance = SplinePos.CurrentSpline.SplineLength - SplinePos.CurrentSplineDistance;
		if (RemainingDistance > GrindSettings.MaxGrindingSpeed * 0.8)
		{
			FVector MovementInput = MoveComp.GetMovementInput();
			if(MovementInput.IsNearlyZero())
				return false;
			
			FVector GrindDir = SplinePos.WorldForwardVector;
			GrindDir.Z = 0;

			FVector RelativeMoveInput = HoverboardComp.GetMovementInputCameraSpace();

			float AngleFromInputToGrindDir = RelativeMoveInput.GetAngleDegreesTo(GrindDir);

			TEMPORAL_LOG(GrindComp)
			.DirectionalArrow("Leave Input", Player.ActorLocation, RelativeMoveInput * 500, 5, 20, FLinearColor::Red)
			.DirectionalArrow("Grind Dir", Player.ActorLocation, GrindDir * 500, 5, 20, FLinearColor::Blue);

			if(AngleFromInputToGrindDir < GrindSettings.AngleThresholdToLeaveGrindJump)
				return false;

			Params.PlayerRelativeMovementInput = RelativeMoveInput;
		}
		else
		{
			FVector MovementInput = MoveComp.GetMovementInput();
			FVector RelativeMoveInput = Player.ViewRotation.ForwardVector;
			if(!MovementInput.IsNearlyZero())
				RelativeMoveInput = HoverboardComp.GetMovementInputCameraSpace();

			Params.PlayerRelativeMovementInput = RelativeMoveInput;
		}
		

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardLeaveGrindJumpActivationParams Params)
	{
		JumpComp.ConsumeJumpInput();

		HoverboardComp.AnimParams.bIsJumpingOffGrind = true;

		JumpComp.bAirborneFromJump = true;

		Player.ActorVerticalVelocity += FVector::UpVector * GrindSettings.GrindLeaveJumpUpwardsImpulse;
		Player.ActorHorizontalVelocity += Params.PlayerRelativeMovementInput * GrindSettings.GrindLeaveJumpInputImpulse;

		GrindComp.TimeLastLeftGrindWithJump = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HoverboardComp.AnimParams.bIsJumpingOffGrind = false;

		JumpComp.bAirborneFromJump = false;
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
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardGrinding");
		}
	}
};