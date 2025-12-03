class USummitRollingLiftPassengerAcidSprayCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 110;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTeenDragonAcidSprayComponent SprayComp;
	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAcidSpraySettings SpraySettings;

	FHazeAcceleratedQuat ToTargetLocationQuat;
	float SprayTimer = 0.0;
	bool bRanOutOfAcid = false;
	bool bSprayActivated = false;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		SpraySettings = UTeenDragonAcidSpraySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AimComp.IsAiming())
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (DeactiveDuration < SpraySettings.SprayRechargeCooldown)
			return false;

		if (bRanOutOfAcid && SprayComp.RemainingAcidAlpha < SpraySettings.SprayShootRechargeThreshold)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AimComp.IsAiming())
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if (SprayComp.RemainingAcidAlpha <= 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SprayComp = UTeenDragonAcidSprayComponent::Get(Player);

		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		DragonComp.bIsFiringAcid = true;
		FAimingResult AimTarget = AimComp.GetAimingTarget(DragonComp);
		ToTargetLocationQuat.SnapTo(AimTarget.AimDirection.ToOrientationQuat());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bRanOutOfAcid = false;
		DragonComp.bIsFiringAcid = false;

		SprayComp.ToggleSpray(false);
		UTeenDragonAcidSprayEventHandler::Trigger_AcidProjectileStopFiring(Player);
		bSprayActivated = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform TargetSocket = DragonComp.DragonMesh.GetSocketTransform(SpraySettings.ShootSocket);
		FVector TargetSocketOrigin = TargetSocket.TransformPosition(SprayComp.bNewSpray ? FVector(-20, 0, 0) : SpraySettings.ShootSocketOffset);

		DragonComp.DragonMesh.RequestOverrideFeature(TeenDragonLocomotionTags::AcidTeenShoot, this);

		FAimingResult AimTarget = AimComp.GetAimingTarget(DragonComp);
		ToTargetLocationQuat.SpringTo(AimTarget.AimDirection.ToOrientationQuat(), 120, 0.6, DeltaTime);
		
		if(ActiveDuration < SpraySettings.SprayDelay)
		{
			return;
		}
		else if(SprayComp.bNewSpray && !bSprayActivated)
		{
			SprayComp.ToggleSpray(true);
			bSprayActivated = true;
		}

		SprayTimer += DeltaTime;

		float SprayInterval;

		SprayInterval = 1 / SprayComp.FireRatePerSec;

		auto PuddleClass = SprayComp.bNewSpray ? SprayComp.NewPuddleClass : SprayComp.PuddleClass; 

		if (SprayTimer > SprayInterval)
		{
			int CountMult = 3;
			if(SprayComp.bNewSpray)
				CountMult = 1;
			int Count = 0;

			while ( Count < CountMult)
			{
				Count++;
				SprayTimer -= SprayInterval;

				FAcidProjectileParams Params;
				Params.Origin = TargetSocketOrigin;
				Params.ProjectileClass = SprayComp.ProjectileClass;

				Params.PuddleClass = PuddleClass;

				Params.PuddleRadius = SpraySettings.PuddleRadius;
				Params.PuddleDuration = SpraySettings.PuddleDuration;

				Params.Speed = SpraySettings.ProjectileSpeed;
				Params.Range = SpraySettings.AcidSprayRange * SprayComp.AcidSprayRangeMultiplier.Get();

				// Params.Target = AimTarget.AimOrigin + AimTarget.AimDirection * SpraySettings.AcidSprayRange * SprayComp.AcidSprayRangeMultiplier.Get();
				Params.Target = AimTarget.AimOrigin + ToTargetLocationQuat.Value.Vector() * SpraySettings.AcidSprayRange * SprayComp.AcidSprayRangeMultiplier.Get();

				Params.StartScale = SpraySettings.ProjectileStartScale;
				Params.EndScale = SpraySettings.ProjectileEndScale;
				Params.ScaleUpDuration = SpraySettings.ProjectileScaleUpDuration;
				Params.TraceRadius = SpraySettings.ProjectileTraceRadius;
				Params.SplashRadius = SpraySettings.ProjectileSplashRadius;
				Params.Gravity = SpraySettings.ProjectileGravity;
				Params.LifeTime = SpraySettings.ProjectileLiftTime;
				Params.FiringPlayer = Player;
				Params.Damage = (SpraySettings.FullSprayDamagePerSecond * SprayInterval)/CountMult;

				// Make a trace to see if we should hit sooner than the maximum distance
				FHazeTraceSettings Trace;
				Trace.UseLine();
				Trace.TraceWithChannel(ECollisionChannel::WeaponTraceMio);
				Trace.IgnorePlayers();
				Trace.IgnoreActor(Owner);

				// Inherit Dragon Velocity
				FVector DirToTarget = (Params.Target - Params.Origin).GetSafeNormal();
				float SpeedTowardsTarget = Player.OtherPlayer.ActorVelocity.DotProduct(DirToTarget);
				Params.Speed += SpeedTowardsTarget;

				// Debug::DrawDebugArrow(Params.Origin, Params.Target, 500,FLinearColor::Blue,50 );

				FHitResult AimHit;
				AimHit = Trace.QueryTraceSingle(AimTarget.AimOrigin, Params.Target);

				
				if (AimHit.bBlockingHit)
				{
					Params.Target = AimHit.Location;
					// Debug::DrawDebugSphere(AimHit.Location, 100.0, 12, FLinearColor::Red, 5);
				}

				Acid::FireAcidProjectile(Params);

				FTeenDragonAcidProjectileEventParams EventParams;
				EventParams.LaunchLocation = Params.Origin;
				EventParams.LaunchDirection = (Params.Target - Params.Origin).GetSafeNormal();
				EventParams.LaunchTarget = Params.Target;
				EventParams.bStreamBlockingHit = AimHit.bBlockingHit;

				UTeenDragonAcidSprayEventHandler::Trigger_AcidProjectileFired(Player, EventParams);
			}
		}

		SprayComp.AlterAcidAlpha(-SpraySettings.AcidReductionAmount * DeltaTime / SprayComp.AcidSprayStaminaMultiplier.Get());

	}
};