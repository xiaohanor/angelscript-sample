class UBattlefieldHoverboardGroundMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardLevelRubberbandingComponent LevelRubberbandingComp;
	UPlayerMovementComponent MoveComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;

	const float SlopinessThreshold = 0.2;
	const float BaseMovementSpeedInterpSpeed = 200.0;

	float Speed;
	float InputSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		LevelRubberbandingComp = UBattlefieldHoverboardLevelRubberbandingComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!HoverboardComp.IsOn())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BattlefieldDevToggles::FreezeMovement.MakeVisible();
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		
		Speed = HorizontalVelocity.Size();
		InputSpeed = 0.0;

		float SpeedAlignedWithGround = MoveComp.PreviousVelocity.DotProduct(-MoveComp.CurrentGroundNormal);
		float RumbleAlpha = Math::GetPercentageBetweenClamped(0, GroundMovementSettings.LandingSpeedForFullRumble, SpeedAlignedWithGround);
		float RumbleMultiplier = GroundMovementSettings.LandingRumbleCurve.GetFloatValue(RumbleAlpha);
		Player.PlayForceFeedback(GroundMovementSettings.LandingRumble, false, false, this, RumbleMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;

				UpdateRotation(DeltaTime, MovementInput);
				Movement.SetRotation(HoverboardComp.AccNudgeRotation.Value + HoverboardComp.AccRotation.Value);

				Speed = UpdateSpeed(DeltaTime);
				InputSpeed = UpdateInputSpeed(DeltaTime, MovementInput);
				float TotalSpeed = (Speed + InputSpeed + LevelRubberbandingComp.RubberbandingSpeed + HoverboardComp.TrickBoostSpeed) * MoveComp.GetMovementSpeedMultiplier();
				
				if(!BattlefieldDevToggles::FreezeMovement.IsEnabled())
					Movement.AddHorizontalVelocity(Player.ActorForwardVector * TotalSpeed);

				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.5), EMovementEdgeNormalRedirectType::Soft);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = BattlefieldHoverboardLocomotionTags::Hoverboard;
			if(MoveComp.WasInAir())
			{
				float LandingSpeedTowardsNormal = MoveComp.PreviousVelocity.DotProduct(MoveComp.CurrentGroundImpactNormal);
				HoverboardComp.AnimParams.LastLandingSpeed = LandingSpeedTowardsNormal;
				AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardLanding;
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}

	private float UpdateSpeed(float DeltaTime)
	{	
		FVector HorizontalDirection = MoveComp.HorizontalVelocity.GetSafeNormal();
		float DirAlignmentWithGravity = MoveComp.GravityDirection.DotProduct(HorizontalDirection);

		// Area is not slopy enough
		if(Math::Abs(DirAlignmentWithGravity) < SlopinessThreshold)
		{
			Speed = Math::FInterpConstantTo(Speed, GroundMovementSettings.BaseSpeed, DeltaTime, BaseMovementSpeedInterpSpeed);
		}
		else
		{
			float SlopeMultiplier = DirAlignmentWithGravity > 0.0 ?
			GroundMovementSettings.DownSlopeAccelerationMultiplier :
			GroundMovementSettings.UpSlopeDecelerationMultiplier;

			float SlopeSpeedChange = DirAlignmentWithGravity * SlopeMultiplier * MoveComp.GravityForce * DeltaTime;
			Speed += SlopeSpeedChange;
		}


		if(Speed <= GroundMovementSettings.MinSpeed)
			Speed = Math::FInterpConstantTo(Speed, GroundMovementSettings.MinSpeed, DeltaTime, GroundMovementSettings.UnderSpeedAcceleration);

		Speed = Math::Clamp(Speed, 0, GroundMovementSettings.MaxSpeed);
		TEMPORAL_LOG(HoverboardComp)
			.Value("Speed", Speed)
		;

		return Speed;
	}

	private float UpdateInputSpeed(float DeltaTime, FVector MovementInput)
	{
		InputSpeed = Math::FInterpTo(InputSpeed, GroundMovementSettings.InputSpeedMax * MovementInput.X, DeltaTime, 
			GroundMovementSettings.InputSpeedAcceleration);
		return InputSpeed;
	}

	private void UpdateRotation(float DeltaTime, FVector MovementInput)
	{
		// Disable turning in slopes if it has this component
		auto NoTurningSlopeComponent = UBattlefieldHoverboardNoTurningSlopeComponent::Get(MoveComp.GroundContact.Actor);
		if(NoTurningSlopeComponent == nullptr)
			HoverboardComp.WantedRotation += GetSlopeTurnAmount(DeltaTime);

		HoverboardComp.AddWantedRotation(GroundMovementSettings.WantedRotationSpeed, MovementInput, DeltaTime);
		HoverboardComp.SetCameraWantedRotationToWantedRotation();
		float TargetRotationDuration = MovementInput.IsNearlyZero() 
			? GroundMovementSettings.RotationDuration 
			: GroundMovementSettings.RotationDurationDuringInput;
		HoverboardComp.RotateTowardsWantedRotation(TargetRotationDuration, DeltaTime);
	}

	private FRotator GetSlopeTurnAmount(float DeltaTime)
	{
		FRotator TurnAmount = FRotator::ZeroRotator;

		FVector VelocityDir = Player.ActorVelocity.GetSafeNormal();
		FVector SlopeUp = VelocityDir.CrossProduct(Player.ActorRightVector);
		float GroundAngle = MoveComp.CurrentGroundNormal.GetAngleDegreesTo(SlopeUp);

		float FractionOfMaxAngle = Math::GetPercentageBetweenClamped(0, GroundMovementSettings.SlopeTurnAngleMax, GroundAngle);
		float SlopeTurnMultiplier =  GroundMovementSettings.SlopeTurnCurve.GetFloatValue(FractionOfMaxAngle);

		float DotCheck = Player.ActorRightVector.DotProduct(MoveComp.CurrentGroundNormal);
		TurnAmount.Yaw = Math::Sign(DotCheck) * GroundMovementSettings.SlopeTurnSpeed * DeltaTime * SlopeTurnMultiplier;

		TEMPORAL_LOG(Player, "Ground Movement")
			.DirectionalArrow("Compare Ground Turn Vector", Player.ActorLocation, SlopeUp * 500, 10, 40, FLinearColor::Blue)
		;
		
		return TurnAmount;
	}
};