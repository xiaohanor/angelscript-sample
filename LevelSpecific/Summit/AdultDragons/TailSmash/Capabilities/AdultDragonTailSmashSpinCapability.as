class UAdultDragonTailSmashSpinCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonTailSmash::Tags::AdultDragonTailSmash);

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = AdultDragonTailSmash::DefaultTickGroupOrder;
	default TickGroupSubPlacement = 2;

	UAdultDragonTailSmashComponent SmashComp;
	UPlayerMovementComponent MoveComp;
	UPlayerTailAdultDragonComponent DragonComp;
	UPlayerAimingComponent AimComp;

	USimpleMovementData Movement;

	bool bHasHitStoppingImpact = false;
	bool bStartedThisFrame = false;
	UAdultDragonTailSmashModeSettings SmashSettings;
	UAdultDragonFlightSettings FlightSettings;

	const float MinSpinDuration = 1;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);

		SmashSettings = UAdultDragonTailSmashModeSettings::GetSettings(Player);

		DragonComp = UPlayerTailAdultDragonComponent::Get(Player);
		SmashComp = UAdultDragonTailSmashComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);

		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStopped(ActionNames::PrimaryLevelAbility))
			return false;

		if (SmashComp.SpinChargeTime < AdultDragonTailSmash::SpinChargeTime)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > MinSpinDuration && !(AimComp.IsAiming() && AimComp.HasAimingTargetOverride()))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.Speed = Math::Max(DragonComp.Speed, SmashSettings.MinSpeed);

		DragonComp.AimingInstigators.Add(this);
		bHasHitStoppingImpact = false;
		Player.PlayForceFeedback(SmashComp.SmashStartedForceFeedback, false, true, this);
		Player.PlayCameraShake(SmashComp.SmashImpactCameraShake, this);
		
		//Player.BlockCapabilities(AdultDragonTailSmash::Tags::AdultDragonTailSmashWait, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AimingInstigators.RemoveSingleSwap(this);
		DragonComp.BonusSpeed.Remove(this);
		// SpeedEffect::ClearSpeedEffect(Player, this);
		DragonComp.AnimParams.AnimAirSmashRoll.SnapTo(0.0);
		//Player.UnblockCapabilities(AdultDragonTailSmash::Tags::AdultDragonTailSmashWait, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleMovement(DeltaTime);
		HandleImpacts();

		UpdateSpeedEffects();

		DragonComp.RequestLocomotionDragonAndPlayer(AdultDragonTailSmash::Locomotion::AirSmash);
	}

	void HandleMovement(float DeltaTime)
	{
		float Speed = SmashComp.SpinSpeedCurve.GetFloatValue(ActiveDuration);
		if(MoveComp.PrepareMove(Movement))
		{
			FVector Delta = AimComp.GetPlayerAimingRay().Direction * Speed * DeltaTime;
			Movement.InterpRotationTo(Delta.ToOrientationQuat(), AdultDragonTailSmash::SpinRotationInterpSpeed, false);
			Movement.AddDelta(Delta);
			MoveComp.ApplyMove(Movement);
		}
	}

	void UpdateSpeedEffects()
	{
		//camera postprocessing
		float SpeedFraction = Math::NormalizeToRange(Player.ActorVelocity.Size(), FlightSettings.MinSpeed, FlightSettings.MaxSpeed);
		// SpeedEffect::RequestSpeedEffect(Player, FlightSettings.SpeedEffectValue.GetFloatValue(SpeedFraction * 4), this, EInstigatePriority::High);
	}
	
	void HandleImpacts()
	{
		if(!MoveComp.HasAnyValidBlockingContacts())
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
		Player.PlayCameraShake(SmashComp.SmashImpactCameraShake, this);
		Player.PlayForceFeedback(SmashComp.SmashImpactForceFeedback, false, true, this);
	}
};