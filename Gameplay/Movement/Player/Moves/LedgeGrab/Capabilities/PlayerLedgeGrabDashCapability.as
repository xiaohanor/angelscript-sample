
class UPlayerLedgeGrabDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabDash);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 11;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerLedgeGrabComponent LedgeGrabComp;

	const float TestTraceDistance = 200;
	float MoveDurationTotal = 0.5;
	//Incase we want to hold before "TakeOff" for animation and anticipation
	// float AnticipationDuration = 0.15;
	float DashDirectionScale = 1.0;

	float StartSpeed;
	float AccelerationDuration;
	float FinalSpeed;

	FPlayerLedgeGrabData ProjectedEndLocationData;
	FVector StartLocation;
	FVector EndLocation;
	FRotator StartRotation;

	//Test trace at the endLocation as well as inbetween making sure we dont cross any gaps onto other ledges?
		//Trace forward in iteration steps and confirm OR continous traces during the move (this could be weird since if the dash is a "Leap" we cant cancel mid move easily)
	//We need to confirm a new rotation based on the impacted normal like ledgegrab does on tick

	//Confirm our data for endlocation so we can assign a correct / valid ledge grab on move transition out

	//LedgeGrab Deactivation needs to confirm why we are deactivating to only reset specific data (as we arent dropping out of ledge grab)

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLedgeGrabDashActivationParams& ActivationParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(LedgeGrabComp.State != EPlayerLedgeGrabState::LedgeGrab)
			return false;

		if(!WasActionStarted(ActionNames::MovementDash))
			return false;

		if(!LedgeGrabComp.Data.bFeetPlanted)
			return false;

		FVector MoveDirection = LedgeGrabComp.Data.LedgeRightVector * GetAttributeFloat(AttributeNames::MoveRight);
		MoveDirection = MoveDirection.GetSafeNormal();
		if(MoveDirection.IsNearlyZero())
			return false;		

		FVector TestLocation = Player.ActorLocation + MoveDirection * TestTraceDistance;
		FPlayerLedgeGrabData LedgeGrabData;
		if(!LedgeGrabComp.TraceForLedgeGrabAtLocation(Player, Player.ActorForwardVector, TestLocation, LedgeGrabData, this, IsDebugActive()))
			return false;

		ActivationParams.DashDirectionScale = Math::Sign(LedgeGrabComp.Data.LedgeRightVector.DotProduct(MoveDirection));
		ActivationParams.EndLocationData = LedgeGrabData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= LedgeGrabComp.Settings.ShimmyDashDuration + AccelerationDuration)
			return true;

		if (MoveComp.HasWallContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLedgeGrabDashActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeGrab, this);

		ProjectedEndLocationData = Params.EndLocationData;
		DashDirectionScale = Params.DashDirectionScale;
		LedgeGrabComp.AnimData.DashDirectionSign = DashDirectionScale;

		LedgeGrabComp.DashDirectionSign = DashDirectionScale;

		StartLocation = Player.ActorLocation;
		StartRotation = Player.ActorRotation;

		float BaseSpeed = LedgeGrabComp.Settings.ShimmyDashDistance / LedgeGrabComp.Settings.ShimmyDashDuration;
		StartSpeed = MoveComp.GetHorizontalVelocity().Size();

		if(LedgeGrabComp.Settings.ShimmyDashAccelerationDuration > 0.0)
		{
			if(StartSpeed >= BaseSpeed * 0.9)
			{
				//We are already at or above the dash speed so no need for acceleration
				AccelerationDuration = 0.0;
				FinalSpeed = BaseSpeed;
				StartSpeed = 0.0;
			}
			else
			{
				AccelerationDuration = LedgeGrabComp.Settings.ShimmyDashAccelerationDuration;

				//We need to adapt our speed to get the correct distance
				FinalSpeed = (2.0 * LedgeGrabComp.Settings.ShimmyDashDistance - (AccelerationDuration * StartSpeed)) / (AccelerationDuration + 2.0 * LedgeGrabComp.Settings.ShimmyDashDuration);
			}
		}
		else
		{
			//AccelerationDuration set to 0
			AccelerationDuration = 0.0;
			FinalSpeed = BaseSpeed;
			StartSpeed = 0.0;
		}

		LedgeGrabComp.SetState(EPlayerLedgeGrabState::Dash);
		// Player.TriggerEffectEvent(n"PlayerLedgeGrab.DashActivated"); // UNKNOWN EFFECT EVENT NAMESPACE
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeGrab, this);
		LedgeGrabComp.Data = ProjectedEndLocationData;
		LedgeGrabComp.AnimData.DashDirectionSign = 0.0;

		Player.SetActorHorizontalVelocity(Player.ActorHorizontalVelocity.GetClampedToMaxSize(LedgeGrabComp.Settings.ShimmySpeedMax) * GetAttributeFloat(AttributeNames::MoveRight));

		if(IsDebugActive())
		{
			Print(f"Actually covered {Player.ActorLocation.Distance(StartLocation)}");
			PrintToScreen("ActiveDuration: " + ActiveDuration, 3.f);
		}
		//If we activated ledge grab post dash then dont use accelerated offset to lerp into position OR look into reworking the accelerated offset to not need a settle in time.
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			float Speed = FinalSpeed;
			if(ActiveDuration < AccelerationDuration)
				Speed = Math::Lerp(StartSpeed, FinalSpeed, ActiveDuration / AccelerationDuration);

			FVector HorizontalVelocity;
			FVector MoveDirection = LedgeGrabComp.Data.LedgeRightVector * DashDirectionScale;
			HorizontalVelocity = MoveDirection * Speed;

			Movement.AddHorizontalVelocity(HorizontalVelocity);
			Movement.SetRotation(StartRotation);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeGrab");
		}
	}
}

struct FLedgeGrabDashActivationParams
{
	FPlayerLedgeGrabData EndLocationData;

	float DashDirectionScale = 1.0;
}

