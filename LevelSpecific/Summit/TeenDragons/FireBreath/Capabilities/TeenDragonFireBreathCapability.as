class UTeenDragonFireBreathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonFireBreath);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;
	UTeenDragonFireBreathComponent FireBreathComp;
	UPlayerAimingComponent AimComp;
	UTeenDragonFireBreathSettings Settings;

	FVector StartLocation;
	FVector AimDirection;

	bool bFireBreathStarted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		FireBreathComp = UTeenDragonFireBreathComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		Settings = UTeenDragonFireBreathSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DeactiveDuration < Settings.FireBreathCooldown)
			return false;

		if(RollComp.IsRolling())
			return false;

		if(WasActionStartedDuringTime(Settings.InputActionName, Settings.InputBufferDuration))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Settings.FireBreathDuration + Settings.FireBreathDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireBreathComp.bIsBreathingFire = true;
		bFireBreathStarted = false;

		Player.ApplySettings(Settings.ShootingMovementSettings, this, EHazeSettingsPriority::Override);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FireBreathComp.bIsBreathingFire = false;

		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > Settings.FireBreathDelay
		&& !bFireBreathStarted)
			StartFireBreath();
		
		if(bFireBreathStarted)
		{
			float BreathAlpha = (ActiveDuration - Settings.FireBreathDelay) / Settings.FireBreathDuration;
			BreathAlpha = Settings.TravelCurve.GetFloatValue(BreathAlpha);
			float BreathRadius = Settings.FireBreathRadius.Lerp(BreathAlpha);
			FVector BreathLocation = StartLocation + AimDirection * Settings.FireBreathRange * BreathAlpha;

			FHazeTraceSettings BreathTrace;
			BreathTrace.TraceWithChannel(ECollisionChannel::WeaponTraceZoe);
			BreathTrace.UseSphereShape(BreathRadius);
			auto BreathOverlaps = BreathTrace.QueryOverlaps(BreathLocation);
			TEMPORAL_LOG(Player, "Fire Breath")
				.Sphere("Breath Trace Sphere", BreathLocation, BreathRadius, FLinearColor::Red, 10)
			;

			// Debug::DrawDebugSphere(BreathLocation, BreathRadius, 24, FLinearColor::Red, 20, 0.1);
			for(auto Overlap : BreathOverlaps)
			{
				auto ResponseComp = USummitFireBreathResponseComponent::Get(Overlap.Actor);
				if(ResponseComp == nullptr)
					continue;
				
				FSummitFireBreathHitParams HitParams;
				ResponseComp.OnHit.Broadcast(HitParams);
			}
		}

	}

	void StartFireBreath()
	{
		FTransform ShootTransform = DragonComp.DragonMesh.GetSocketTransform(Settings.SocketName);
		Player.ConsumeButtonInputsRelatedTo(Settings.InputActionName);

		StartLocation = ShootTransform.Location;
		auto AimResult = AimComp.GetAimingTarget(FireBreathComp);

		if(AimResult.AimDirection.DotProduct(Player.ActorForwardVector) < -0.2
		|| DragonComp.bTopDownMode)
			AimDirection = Player.ActorForwardVector;
		else
			AimDirection = (Player.ActorForwardVector + (AimResult.AimDirection * 2.0));

		AimDirection = AimDirection.ConstrainToPlane(Player.ActorUpVector).GetSafeNormal();

		FVector Forward = FRotator::MakeFromX(AimDirection).Vector();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(Settings.FireBreath, StartLocation, FRotator::MakeFromX(AimDirection));
		Niagara::SpawnOneShotNiagaraSystemAtLocation(Settings.FireBreathMuzzle, StartLocation + Forward * 200.0, FRotator::MakeFromX(AimDirection));
		Player.PlayCameraShake(Settings.CameraShake, this, 1.0);

		bFireBreathStarted = true;
	}
};