asset BattlefieldHoverboardFreeFallingGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2000;
	TerminalVelocity = 10000.0;
}

class UBattlefieldHoverboardFreeFallingCapability : UHazePlayerCapability
{
	default DebugCategory = n"Hoverboard";
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardFreeFallingComponent FreeFallComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	FHazeAcceleratedVector AccHorizontalVelocity;

	float ForwardSpeed;
	const float ForwardSpeedStart = 1000.0;
	const float MaxSpeed = 1000.0;
	const float VelocityAccelerationDuration = 5.0; 
	const float GroundCheckDistance = 5000.0;
	const float RotationSpeed = 100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		FreeFallComp = UBattlefieldHoverboardFreeFallingComponent::GetOrCreate(Player);
		
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(HoverboardComp == nullptr
		|| !HoverboardComp.IsOn())
			return false;

		if(!FreeFallComp.bShouldFreeFall)
			return false;

		if(!MoveComp.IsInAir())
			return false;

		if(Player.ActorVelocity.Z > 0)
		 	return false;

		if(MoveComp.IsOnAnyGround())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(HoverboardComp == nullptr
		|| !HoverboardComp.IsOn())
			return true;

		if(ActiveDuration > 0.5
		&& (MoveComp.HasGroundContact() || MoveComp.HasWallContact()))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccHorizontalVelocity.SnapTo(Player.ActorHorizontalVelocity);
		FreeFallComp.bIsFreeFalling = true;
		ForwardSpeed = ForwardSpeedStart;
		Player.ApplySettings(BattlefieldHoverboardFreeFallingGravitySettings, this);
		Player.SetMovementFacingDirection(FQuat::MakeFromYZ(FreeFallComp.Volume.FreeFallOrientation.RightVector, FVector::UpVector));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FreeFallComp.bShouldFreeFall = false;
		FreeFallComp.bIsFreeFalling = false;
		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.AccRotation.SnapTo(HoverboardComp.WantedRotation);
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HoverboardComp == nullptr)
			HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;
				FVector TargetHorizontalVelocity = Player.ActorForwardVector * MovementInput.X * MaxSpeed
					+ Player.ActorRightVector * MovementInput.Y * MaxSpeed;

				ForwardSpeed = Math::FInterpConstantTo(ForwardSpeed, 500.0, DeltaTime, ForwardSpeedStart);
				FVector ForwardVelocity = Player.ActorForwardVector * ForwardSpeed;

				AccHorizontalVelocity.AccelerateTo(TargetHorizontalVelocity, VelocityAccelerationDuration, DeltaTime);

				if(!FreeFallComp.bIsApproachingGround && ActiveDuration > 1.0)
					CheckForApproachingGround();

				Movement.InterpRotationToTargetFacingRotation(RotationSpeed, false);

				Movement.AddVelocity(AccHorizontalVelocity.Value);
				Movement.AddVelocity(ForwardVelocity);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			if(!FreeFallComp.bIsApproachingGround)
				Player.SetAnimBoolParam(n"FreeFall", true);

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardAirMovement");
		}
	}

	void CheckForApproachingGround()
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		Trace.UseLine();

		FVector Start = Player.ActorLocation;
		FVector End = Player.ActorLocation + FVector::DownVector * GroundCheckDistance;

		FHitResult Hit = Trace.QueryTraceSingle(Start, End);
		if(Hit.bBlockingHit)
			FreeFallComp.bIsApproachingGround = true;
	}
};