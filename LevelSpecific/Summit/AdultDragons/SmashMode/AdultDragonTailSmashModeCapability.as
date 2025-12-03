class UAdultDragonTailSmashModeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonSmashMode);

	default DebugCategory = n"AdultDragon";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UAdultDragonTailSmashModeSettings SmashSettings;
	UAdultDragonFlightSettings FlightSettings;

	UPlayerTailAdultDragonComponent DragonComp;
	UAdultDragonTailSmashModeComponent SmashModeComp;
	UAdultDragonFlyingComponent FlyingComp;
	UPlayerMovementComponent MoveComp;
	UCameraSettings CameraSettings;
	UCameraShakeBase ActiveCameraShake;

	UPlayerAimingComponent AimComp;
	USceneComponent AutoAimTarget;
	UPlayerTargetablesComponent PlayerTargetables;

	USimpleMovementData Movement;

	bool bHasHitStoppingImpact = false;
	bool bStartedThisFrame = false;
	float CameraSettingsScale = 0;

	UCameraShakeBase LoopingCameraShake;

	FHazeFrameForceFeedback ForceFeedback;
	float RumbleAmount;
	float RumbleStart = 0.3;
	float RumbleMax = 0.8;

	FVector StartRumbleLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmashSettings = UAdultDragonTailSmashModeSettings::GetSettings(Player);
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);

		DragonComp = UPlayerTailAdultDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SmashModeComp = UAdultDragonTailSmashModeComponent::Get(Player);
		FlyingComp = UAdultDragonFlyingComponent::Get(Player);
		PlayerTargetables = UPlayerTargetablesComponent::Get(Owner);

		AimComp = UPlayerAimingComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);

		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if(DeactiveDuration <= SmashSettings.SmashModeCooldown)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		// if(SmashModeComp.SmashModeStamina / SmashSettings.SmashModeStaminaMax <= SmashSettings.SmashModeStaminaActivationThreshold)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bHasHitStoppingImpact)
			return true;
		
		// If we have a auto aim target, we stay locked against that
		if(AimComp.GetAimingTarget(Player).AutoAimTarget == nullptr)
		{
			if(SmashSettings.SmashModeStaminaMax > 0 && ActiveDuration > SmashSettings.SmashModeStaminaMax)
				return true;
				
			float MinInputTime = SmashSettings.SmashModeAutoStamina;
			if(MinInputTime < 0)
				MinInputTime = SmashSettings.SmashModeStaminaMax;

			if(ActiveDuration > MinInputTime)
			{
				return true;
			}
		}

		// if(SmashModeComp.SmashModeStamina <= 0)
		// 	return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AutoAimTarget = AimComp.GetAimingTarget(Player).AutoAimTarget;
		DragonComp.AimingInstigators.Add(this);
		bHasHitStoppingImpact = false;
		SmashModeComp.bSmashModeActive = true;
		CameraSettingsScale = 0;

		DragonComp.Speed = Math::Max(DragonComp.Speed, SmashSettings.MinSpeed);

		Player.ApplyBlendToCurrentView(SmashSettings.CameraBlendInTime);
		Player.ApplyCameraSettings(SmashModeComp.CameraSettings, 0, this, SubPriority = 65);
	
		ActiveCameraShake = Player.PlayCameraShake(SmashModeComp.SmashLoopingCameraShake, this, KINDA_SMALL_NUMBER * 4); // Need a small starting value. 0 and it will not start
		bStartedThisFrame = true;
		
		RumbleAmount = RumbleStart;

		Player.BlockCapabilities(n"AirBreak", this);
		Player.BlockCapabilities(AdultDragonCapabilityTags::AdultDragonAirDash, this);
		IgnoreAllPassthroughActors();

		if(AimComp.GetAimingTarget(Player).AutoAimTarget != nullptr)
			StartRumbleLoc = Player.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AimingInstigators.RemoveSingleSwap(this);
		DragonComp.BonusSpeed.Remove(this);
		SmashModeComp.bSmashModeActive = false; 

		Player.ClearCameraSettingsByInstigator(this, SmashSettings.CameraBlendOutTime);
		Player.StopCameraShakeInstance(ActiveCameraShake);

		// SpeedEffect::ClearSpeedEffect(Player, this);

		Player.UnblockCapabilities(n"AirBreak", this);
		Player.UnblockCapabilities(AdultDragonCapabilityTags::AdultDragonAirDash, this);

		UnignoreAllPassthroughActors();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// TODO (FL): Fix some more robust solution 
		if(Player.IsPlayerDead())
			DragonComp.AnimParams.AnimAirSmashRoll.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(FlyingComp == nullptr)
			FlyingComp = UAdultDragonFlyingComponent::Get(Player);

		CameraSettingsScale = Math::FInterpConstantTo(CameraSettingsScale, 1, DeltaTime, 1 / 1.5);
		
		if(AutoAimTarget != nullptr)
		{
			float MaxDist = (AutoAimTarget.WorldLocation - StartRumbleLoc).Size(); 
			float CurrentDist = MaxDist - (AutoAimTarget.WorldLocation - Player.ActorLocation).Size(); 
			float Alpha = CurrentDist / MaxDist;
			RumbleAmount = Math::Lerp(RumbleStart, RumbleMax, Alpha);
		}

		ForceFeedback.LeftMotor = RumbleAmount;
		ForceFeedback.RightMotor = RumbleAmount;
		Player.SetFrameForceFeedback(ForceFeedback);

		// Blend in the camera shake with the same duration as the camera settings
		if (ActiveCameraShake != nullptr)
			ActiveCameraShake.ShakeScale = Math::Lerp(KINDA_SMALL_NUMBER * 4, 1, CameraSettingsScale);

		if(HasControl())
		{
			UpdateMovement(DeltaTime);
			HandleImpacts();
			HandleOverlaps();
		}

		UpdateSpeedEffects();
		DragonComp.RequestLocomotionDragonAndPlayer(n"AdultDragonAirSmash");

		bStartedThisFrame = false;
	}

	void UpdateMovement(float DeltaTime)
	{
		auto AimResult = AimComp.GetAimingTarget(Player);
		AutoAimTarget = AimResult.AutoAimTarget;

		// While we have a auto aim target,
		// we take control over the movement
		if(AutoAimTarget != nullptr)
		{
			DragonComp.BonusSpeed.FindOrAdd(this) = SmashSettings.SmashModeSpeedBoost;
			if(MoveComp.PrepareMove(Movement))
			{
				float MoveSpeed = DragonComp.GetMovementSpeed();
				FVector Delta = AimResult.AimDirection * MoveSpeed * DeltaTime;
				Movement.InterpRotationTo(Delta.ToOrientationQuat(), 10, false);
				Movement.AddDelta(Delta);
				MoveComp.ApplyMove(Movement);
			}
		}
	}

	// Accelerates going downwards and decelerates going upwards
	void HandleAngleSpeedChange(float DeltaTime)
	{
		if(Player.ActorRotation.Pitch > 0)
			DragonComp.Speed -= SmashSettings.SpeedLostGoingUp * DeltaTime;
		else if(Player.ActorRotation.Pitch < 0)
			DragonComp.Speed += SmashSettings.SpeedGainedGoingDown * DeltaTime;
	}
	
	void UpdateWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		DragonComp.WantedRotation.Yaw += MovementInput.Y * SmashSettings.WantedYawSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch += MovementInput.X * SmashSettings.WantedPitchSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch = Math::Clamp(DragonComp.WantedRotation.Pitch, -SmashSettings.PitchMaxAmount, SmashSettings.PitchMaxAmount);
	}

	void RotateTowardsWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		float RotationDuration = MovementInput.IsNearlyZero() ?  SmashSettings.RotationDuration : SmashSettings.RotationDurationDuringInput;
		DragonComp.RotationAccelerationDuration.AccelerateTo(RotationDuration,
													  1, 
													  DeltaTime);

		DragonComp.AccRotation.AccelerateTo(DragonComp.WantedRotation, DragonComp.RotationAccelerationDuration.Value, DeltaTime);
		// Movement.SetRotation(DragonComp.AccRotation.Value);
	}

	void UpdateSpeedEffects()
	{
		float SpeedFraction = Math::NormalizeToRange(Player.ActorVelocity.Size(), FlightSettings.MinSpeed, FlightSettings.MaxSpeed);

		// This makes the camera very un-smooth / Tyko
		{
			//SpeedFraction = 4.0; //REMOVE LATER 
			// Player.ApplyManualFractionToCameraSettings(FlightSettings.FOVSpeedScale.GetFloatValue(SpeedFraction), this);
			// Player.PlayCameraShake(FlyingComp.SpeedShake, this, FlightSettings.CameraShakeAmount.GetFloatValue(SpeedFraction));
		}

		// SpeedEffect::RequestSpeedEffect(Player, FlightSettings.SpeedEffectValue.GetFloatValue(SpeedFraction * 4), this, EInstigatePriority::High);
	}

	void IgnoreAllPassthroughActors()
	{
		auto SmashResponseCompContainer = UAdultDragonTailSmashModeResponseComponentContainer::GetOrCreate(Player);
		for(auto ResponseComp : SmashResponseCompContainer.ResponseComps)
		{
			if(ResponseComp == nullptr)
				continue;
			
			if(!ResponseComp.bShouldStopPlayer)
				MoveComp.AddMovementIgnoresActor(this, ResponseComp.Owner);
		}
	}

	void UnignoreAllPassthroughActors()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
	}
	
	void HandleOverlaps()
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceZoe);
		auto PlayerCapsule = Player.CapsuleComponent;
		TraceSettings.UseCapsuleShape(PlayerCapsule.CapsuleRadius, PlayerCapsule.CapsuleHalfHeight, PlayerCapsule.ComponentQuat);

		auto HitResults = TraceSettings.QueryOverlaps(Player.ActorLocation);

		for(auto Hit : HitResults)
		{
			auto ResponseComp = UAdultDragonTailSmashModeResponseComponent::Get(Hit.Actor);
			
			if(ResponseComp == nullptr)
				continue;

			// ResponseComps that should stop player is handled by wall collision
			if(ResponseComp.bShouldStopPlayer)
				continue;

			FTailSmashModeHitParams Params;
			Params.HitComponent = Hit.Component;
			Params.ImpactLocation = Player.ActorLocation;
			Params.PlayerInstigator = Game::Zoe;
			Params.DamageDealt = SmashSettings.ImpactDamage;

			CrumbSendHit(Params, ResponseComp);
		}
	}
	void HandleImpacts()
	{
		if(!MoveComp.HasAnyValidBlockingContacts())
			return;

		if(bStartedThisFrame)
			return;

		FHitResult Hit;
		if(MoveComp.HasWallContact())
			Hit = MoveComp.GetWallContact().ConvertToHitResult();
		else if(MoveComp.HasCeilingContact())
			Hit = MoveComp.GetCeilingContact().ConvertToHitResult();
		else if(MoveComp.HasGroundContact())
			Hit = MoveComp.GetGroundContact().ConvertToHitResult();

		bHasHitStoppingImpact = true;

		FTailSmashModeHitParams HitParams;
		HitParams.HitComponent = Hit.Component;
		HitParams.ImpactLocation = Hit.ImpactPoint;
		HitParams.FlyingDirection = Player.ActorForwardVector;
		HitParams.DamageDealt = SmashSettings.ImpactDamage;

		if(HitParams.HitComponent == nullptr)
			return;
		
		//Use response comp if smash ends up being officially used
		auto ResponseComp = UAdultDragonTailSmashModeResponseComponent::Get(HitParams.HitComponent.Owner);
		
		if(ResponseComp == nullptr)
		{
			FRotator Rotation = Player.ActorRotation;
			float HitDotForward = Hit.Normal.DotProduct(Rotation.ForwardVector);

			// Slow down
			float SpeedLoss = HitDotForward * DragonComp.Speed * SmashSettings.CollisionSpeedLossMultiplier;
			// So you can't get speed when going backwards into something
			SpeedLoss = Math::Min(SpeedLoss, 0);
			DragonComp.Speed += SpeedLoss;

			FVector NewForward = Rotation.ForwardVector - Hit.Normal * HitDotForward;
			FRotator NewRotation = FRotator::MakeFromXZ(NewForward, Rotation.UpVector);
			NewRotation.Roll = 0;

			// Rotate along wall
			DragonComp.AccRotation.SnapTo(NewRotation);
			DragonComp.WantedRotation = NewRotation;

			// Movement.SetRotation(NewRotation);
		}
		else
		{
			CrumbSendHit(HitParams, ResponseComp);
		}
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbSendHit(FTailSmashModeHitParams Params, UAdultDragonTailSmashModeResponseComponent HitComp)
	{
		HitComp.ActivateSmashModeHit(Params);
		Player.PlayCameraShake(SmashModeComp.SmashImpactCameraShake, this);
		Player.PlayForceFeedback(SmashModeComp.SmashRumbleImpact, false, true, this);
	}

	//testing but with spike comp temporarily
	// void SendHit(FTailSmashModeHitParams Params, UAdultDragonSpikeResponseComponent HitComp)
	// {
	// 	HitComp.CrumbActivateSpikeHit();
	// 	Player.PlayCameraShake(SmashModeComp.SmashImpactCameraShake, this);
	// 	Player.PlayForceFeedback(SmashModeComp.SmashRumbleImpact, false, true, this);
	// }
};