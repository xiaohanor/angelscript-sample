struct FBattlefieldHoverboardGrindJumpActivationParams
{
	UBattlefieldHoverboardGrindSplineComponent CurrentGrindSplineComp;
	FSplinePosition CurrentSplinePos;
	float SpeedAtActivation = 0.0;
}

class UBattlefieldHoverboardGrindJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardComponent HoverboardComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardGrindingSettings GrindSettings;
	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;

	UBattlefieldHoverboardGrindSplineComponent GrindCurrentlyOn;

	const float WantedRotationInterpSpeed = 50.0;

	bool bTargetHasReachedEnd = false;
	float CurrentSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Movement = MoveComp.SetupSteppingMovementData();

		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardGrindJumpActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!GrindComp.IsGrinding())
			return false;

		if(!GrindComp.CurrentGrindSplineComp.bAllowJumpWhileOnGrind)
			return false;

		if(!JumpComp.bWantToJump)
			return false;
		
		Params.CurrentGrindSplineComp = GrindComp.CurrentGrindSplineComp;
		Params.CurrentSplinePos = GrindComp.CurrentSplinePos;

		FVector SplineForward = Params.CurrentSplinePos.WorldForwardVector;

		Params.SpeedAtActivation = Player.ActorVelocity.DotProduct(SplineForward);
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!GrindComp.IsGrinding())
			return true;

		if(MoveComp.HasWallContact())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		if(bTargetHasReachedEnd)
		{
			float DistToSplineLocSqrd = Player.ActorLocation.DistSquared(GrindComp.CurrentSplinePos.WorldLocation);
			float TotalSpeed = CurrentSpeed + GrindComp.AccGrindRubberbandingSpeed.Value;

			if(DistToSplineLocSqrd < Math::Square(TotalSpeed))
				return true;
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardGrindJumpActivationParams Params)
	{
		JumpComp.ConsumeJumpInput();

		GrindComp.CurrentSplinePos = Params.CurrentSplinePos;
		GrindComp.CurrentGrindSplineComp = Params.CurrentGrindSplineComp;
		GrindCurrentlyOn = Params.CurrentGrindSplineComp;
		CurrentSpeed = Params.SpeedAtActivation;	

		bTargetHasReachedEnd = false;

		Player.ActorVerticalVelocity += FVector::UpVector * GrindSettings.GrindJumpImpulse;

		if(GrindComp.CurrentGrindSplineComp.OverridingCameraSettings != nullptr)
			Player.ApplySettings(GrindComp.CurrentGrindSplineComp.OverridingCameraSettings, this);
		else
			Player.ApplySettings(BattlefieldHoverboardDefaultGrindCameraSettings, this);
		Player.ApplyCameraSettings(GrindSettings.CameraSettings, GrindSettings.CameraBlendTime, this, EHazeCameraPriority::High, 1);

		HoverboardComp.AnimParams.bIsJumpingWhileGrinding = true;

		GrindComp.bIsJumpingWhileGrinding = true;
		JumpComp.bAirborneFromJump = true;

		GrindCurrentlyOn.AddOnGrindInstigator(Player, this);
		GrindComp.GrindingInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HoverboardComp.AnimParams.bIsJumpingWhileGrinding = false;
		if (bTargetHasReachedEnd)
			HoverboardComp.AnimParams.bIsJumpingOffGrind = true;

		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);

		GrindCurrentlyOn.RemoveOnGrindInstigator(Player, this);
		GrindComp.GrindingInstigators.RemoveSingleSwap(this);

		GrindComp.bIsJumpingWhileGrinding = false;
		JumpComp.bAirborneFromJump = false;

		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.AccRotation.SnapTo(HoverboardComp.WantedRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				CurrentSpeed = Math::Clamp(CurrentSpeed, GrindSettings.MinGrindingSpeed, GrindSettings.MaxGrindingSpeed);

				float TotalSpeed = CurrentSpeed + GrindComp.AccGrindRubberbandingSpeed.Value;

				float RemainingDistance = 0.0;
				bTargetHasReachedEnd = !GrindComp.CurrentSplinePos.Move(TotalSpeed * DeltaTime, RemainingDistance);
				FVector SplineWorldLocation = GrindComp.CurrentSplinePos.WorldLocation;

				float DistanceToEndOfGrind = GrindComp.CurrentSplinePos.IsForwardOnSpline() 
					? GrindComp.CurrentGrindSplineComp.SplineComp.SplineLength - GrindComp.CurrentSplinePos.CurrentSplineDistance
					: GrindComp.CurrentSplinePos.CurrentSplineDistance;

				FVector HorizontalDelta = SplineWorldLocation - Player.ActorLocation;
				HorizontalDelta.Z = 0;

				if(DistanceToEndOfGrind <= TotalSpeed * DeltaTime)
					Movement.AddDelta(GrindComp.CurrentSplinePos.WorldForwardVector.VectorPlaneProject(MoveComp.WorldUp) * TotalSpeed * DeltaTime);
				else
					Movement.AddDelta(HorizontalDelta);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				FRotator TargetRotation = GrindComp.CurrentSplinePos.WorldRotation.Rotator();
				TargetRotation.Pitch = 0;
				TargetRotation.Roll = 0;
				FRotator NewRotation = Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, GrindSettings.RotationInterpSpeed);
				Movement.SetRotation(NewRotation);

				FRotator CameraLookAheadRotation = GrindComp.GetCameraLookAheadRotation(GrindComp.CurrentSplinePos, TotalSpeed);
				HoverboardComp.CameraWantedRotation = Math::RInterpTo(HoverboardComp.CameraWantedRotation, CameraLookAheadRotation, DeltaTime, WantedRotationInterpSpeed);
			
				TEMPORAL_LOG(GrindComp)
					.Value("Remaining Distance", RemainingDistance)
					.Value("Distance to end of grind", DistanceToEndOfGrind)
				;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, BattlefieldHoverboardLocomotionTags::HoverboardGrinding);
		}
	}
};