class UTundraPlayerTreeGuardianFloorMotionTurnaroundCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionTurnAround);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 149;

	UPlayerMovementComponent MoveComp;
	UPlayerSprintComponent SprintComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	USteppingMovementData Movement;
	UTundraPlayerTreeGuardianSettings Settings;
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPlayerFloorMotionComponent FloorMotionComp;

	float InactiveTimer = 0.0;

	bool bTurnAroundDetected = false;

	FQuat WantedRotation;
	FQuat StartRotation;
	FVector CurrentVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		FloorMotionSettings = UPlayerFloorMotionSettings::GetSettings(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);

		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive())
			InactiveTimer += DeltaTime;

		bTurnAroundDetected = false;

		FVector Input = MoveComp.MovementInput.GetSafeNormal();
		if((Math::DotToDegrees(Player.ActorForwardVector.DotProduct(Input)) > 120.0))
		{
			if(InactiveTimer < 0.4)
				InactiveTimer = 0.0;
			else
				bTurnAroundDetected = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerTreeGuardianFloorMotionTurnaroundActivatedParams& Params) const
	{
		if(TreeGuardianComp.bInLifeGivingAnimation || (TreeGuardianComp.TimeOfExitLifeGiveAnimation.IsSet() && Time::GetGameTimeSince(TreeGuardianComp.TimeOfExitLifeGiveAnimation.Value) < 0.4))
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;

		if(!bTurnAroundDetected)
			return false;

		float Dot = Player.ActorRightVector.DotProduct(MoveComp.MovementInput.GetSafeNormal());
		Params.bClockwise = Dot > 0.0;
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		//Hard Coded value, should this be part of floor motion settings?
		if(ActiveDuration >= Settings.TurnAroundDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerTreeGuardianFloorMotionTurnaroundActivatedParams Params)
	{
		//Assign inactive timer to 0.
		InactiveTimer = 0.0;

		FloorMotionComp.AnimData.bTurnaroundTriggered = true;
		TreeGuardianComp.TurnAroundAnimData.bTurnaroundIsClockwise = Params.bClockwise;

		//Snap character rotation to match Input Direction if we detected a successful turnaround.
		FVector MovementDirection = MoveComp.MovementInput.GetSafeNormal();
		WantedRotation = (MovementDirection.ToOrientationQuat());

		StartRotation = Player.ActorQuat;
		CurrentVelocity = MoveComp.HorizontalVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FloorMotionComp.AnimData.bTurnaroundTriggered = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = ActiveDuration / Settings.TurnAroundDuration;

				FVector TargetVelocity = WantedRotation.ForwardVector * TargetSpeed;
				CurrentVelocity = Math::Lerp(CurrentVelocity, TargetVelocity, Alpha);
				Movement.AddHorizontalVelocity(CurrentVelocity);
				Movement.SetRotation(WantedRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}

	float GetTargetSpeed() const property
	{
		float InputSize = MoveComp.MovementInput.Size();
		float SpeedAlpha = Math::Clamp((InputSize - FloorMotionSettings.MinimumInput) / (1.0 - FloorMotionSettings.MinimumInput), 0.0, 1.0);
		return Math::Lerp(FloorMotionSettings.MinimumSpeed, FloorMotionSettings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;
	}
}

struct FTundraPlayerTreeGuardianFloorMotionTurnaroundActivatedParams
{
	bool bClockwise;
}