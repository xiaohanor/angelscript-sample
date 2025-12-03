class UBattlefieldHoverboardStrafeGroundMovementCapability : UHazePlayerCapability
{
	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 95;

	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUserComp;

	UBattlefieldHoverboardStrafeComponent StrafeComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardLevelRubberbandingComponent LevelRubberbandingComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;

	float ForwardSpeed;
	float SpeedToTheRight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StrafeComp = UBattlefieldHoverboardStrafeComponent::GetOrCreate(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		LevelRubberbandingComp = UBattlefieldHoverboardLevelRubberbandingComponent::GetOrCreate(Player);

		CameraUserComp = UCameraUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!StrafeComp.ShouldStrafe())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!StrafeComp.ShouldStrafe())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;

		ForwardSpeed = HorizontalVelocity.Size();
		ForwardSpeed = Math::Clamp(ForwardSpeed, GroundMovementSettings.BaseSpeed, GroundMovementSettings.MaxSpeed);
	
		SpeedToTheRight = HorizontalVelocity.DotProduct(CameraUserComp.ViewRotation.RightVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;

				float TotalForwardSpeed = ForwardSpeed + LevelRubberbandingComp.RubberbandingSpeed + HoverboardComp.TrickBoostSpeed;

				Movement.AddHorizontalVelocity(CameraUserComp.ViewRotation.ForwardVector * TotalForwardSpeed);

				SpeedToTheRight += MovementInput.Y * BattlefieldHoverboardBulletRun::SidewaysAcceleration * DeltaTime;
				SpeedToTheRight -= SpeedToTheRight * BattlefieldHoverboardBulletRun::SidewaysFriction * DeltaTime;
				SpeedToTheRight = Math::Clamp(SpeedToTheRight, -BattlefieldHoverboardBulletRun::SidewaysMaxSpeed, BattlefieldHoverboardBulletRun::SidewaysMaxSpeed);

				Movement.AddHorizontalVelocity(CameraUserComp.ViewRotation.RightVector * SpeedToTheRight);

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}	
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = n"Hoverboard";
			if(MoveComp.WasInAir())
			{
				float LandingSpeedTowardsNormal = MoveComp.PreviousVelocity.DotProduct(MoveComp.CurrentGroundImpactNormal);
				HoverboardComp.AnimParams.LastLandingSpeed = LandingSpeedTowardsNormal;
				AnimTag = n"HoverboardLanding";
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}
};