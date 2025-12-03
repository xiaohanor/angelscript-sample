class UTeenDragonAcidSprayFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSpray);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSprayFire);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	UTeenDragonAcidSprayComponent SprayComp;
	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;

	float SprayTimer = 0.0;

	bool bRanOutOfAcid;
	bool bSprayActivated = false;

	FHazeAcceleratedQuat ToTargetLocationQuat;

	UTeenDragonAcidSpraySettings SpraySettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		SprayComp = UTeenDragonAcidSprayComponent::Get(Player);

		SpraySettings = UTeenDragonAcidSpraySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && bRanOutOfAcid)
			bRanOutOfAcid = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		if (DeactiveDuration < SpraySettings.SprayRechargeCooldown)
			return false;
		if (bRanOutOfAcid && SprayComp.RemainingAcidAlpha < SpraySettings.SprayShootRechargeThreshold)
			return false;
		if(!AimComp.IsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if (SprayComp.RemainingAcidAlpha <= 0.0)
			return true;

		if(!AimComp.IsAiming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.bIsFiringAcid = true;

		if(!DragonComp.bTopDownMode)
			Player.PlayCameraShake(SprayComp.AcidSprayCameraShake, this);
		Player.EnableStrafe(this);

		AimComp.ApplyAimingSensitivity(this);
	
		FAimingResult AimTarget = AimComp.GetAimingTarget(DragonComp);
		ToTargetLocationQuat.SnapTo(AimTarget.AimDirection.ToOrientationQuat());

		Player.ApplySettings(SprayComp.SprayMovementSettings, this, EHazeSettingsPriority::Gameplay);

		UTeenDragonAcidSprayEventHandler::Trigger_AcidProjectileStartFiring(Player);
		Player.BlockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAcidSpray, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (SprayComp.RemainingAcidAlpha <= 0.0)
			bRanOutOfAcid = true;

		AimComp.ClearAimingSensitivity(this);

		DragonComp.bIsFiringAcid = false;
		Player.StopCameraShakeByInstigator(this, false);
		Player.DisableStrafe(this);

		SprayComp.ToggleSpray(false);
		bSprayActivated = false;

		Player.ClearSettingsByInstigator(this);

		UTeenDragonAcidSprayEventHandler::Trigger_AcidProjectileStopFiring(Player);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAcidSpray, this);
	}

	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto TemporalLog = TEMPORAL_LOG(Player, "AcidSpray");

		if(DragonComp.DragonMesh.CanRequestOverrideFeature())
			DragonComp.DragonMesh.RequestOverrideFeature(TeenDragonLocomotionTags::AcidTeenShoot, SprayComp);
		FTransform TargetSocket = SprayComp.AcidSprayTransform;
		FVector TargetSocketOrigin = TargetSocket.TransformPosition(SprayComp.bNewSpray ? FVector(-20, 0, 0) : SpraySettings.ShootSocketOffset);

		FAimingResult AimTarget = AimComp.GetAimingTarget(DragonComp);

		
		FVector AimDirTarget = AimTarget.AimDirection;
		// Set new target location for params
		TOptional<FVector> AutoAimTargetLocation;
		if(AimTarget.AutoAimTarget != nullptr)
		{	
			auto AutoAimTargetComp = Cast<UAutoAimTargetComponent>(AimTarget.AutoAimTarget);
			auto TargetPoint = AutoAimTargetComp.GetAutoAimTargetPointForRay(AimTarget.Ray, false);
			if(AimTarget.AutoAimTarget.Owner.ActorVelocity.IsNearlyZero())
			{
				AimDirTarget = (TargetPoint - AimTarget.AimOrigin).GetSafeNormal();
				AutoAimTargetLocation.Set(TargetPoint);
			}
			else
			{
				const FVector TargetLocation = TargetPoint;
				const FVector TargetVelocity = AimTarget.AutoAimTarget.Owner.ActorVelocity;

				float TimeToHit = 0;
				for(TimeToHit = 0.1 ; TimeToHit < 1.0 ; TimeToHit += 0.025)
				{
					const FVector EstimatedTargetLocation = TargetLocation + (TargetVelocity * TimeToHit);
					const FVector DirToTarget = (EstimatedTargetLocation - TargetSocketOrigin).GetSafeNormal();
					const FVector EstimatedProjLocation = TargetSocketOrigin + (DirToTarget * SpraySettings.ProjectileSpeed * TimeToHit);

					float ProjSize = 0.0;
					if(SpraySettings.ProjectileTraceRadius > 0)
					{
						float ProjScale = 0.0;
						if(SpraySettings.ProjectileScaleUpDuration == 0)
							ProjScale = SpraySettings.ProjectileEndScale.Y;
						else
						{
							const float ScaleUpAlpha = Math::Max(TimeToHit, SpraySettings.ProjectileScaleUpDuration) / SpraySettings.ProjectileScaleUpDuration;
							ProjScale = Math::Lerp(SpraySettings.ProjectileStartScale.Y, SpraySettings.ProjectileEndScale.Y, ScaleUpAlpha);
						}
						ProjSize = SpraySettings.ProjectileTraceRadius * ProjScale;
					}
					
					auto TargetBounds = AimTarget.AutoAimTarget.Owner.GetActorLocalBoundingBox(true, false);
					const float EstimatedColliderSize = TargetBounds.Extent.Size() * 0.5;
					const float DistThreshold = EstimatedColliderSize + ProjSize;
					const float DistBetweenEstimationsSqrd = EstimatedProjLocation.DistSquared2D(EstimatedTargetLocation, FVector::UpVector);
					TemporalLog
						.Sphere(f"{TimeToHit}s : Estimated Target Location", EstimatedTargetLocation, EstimatedColliderSize, FLinearColor::Black, 10)
						.Sphere(f"{TimeToHit}s : Estimated Proj Location", EstimatedProjLocation, Math::Max(ProjSize, 20), FLinearColor::Red, 10);
					;
					// Will hit at this time
					if(DistBetweenEstimationsSqrd <= Math::Square(DistThreshold))
					{
						TemporalLog
							.Sphere(f"Successful Hit! : Estimated Proj Location", EstimatedProjLocation, Math::Max(ProjSize, 20), FLinearColor::Green, 10)
							.Sphere(f"Successful Hit! : Estimated Target Location", EstimatedTargetLocation, EstimatedColliderSize, FLinearColor::White, 10)
						;
						AimDirTarget = (EstimatedTargetLocation - AimTarget.AimOrigin).GetSafeNormal();
						AutoAimTargetLocation.Set(EstimatedTargetLocation);
						break;
					}
				}
			}
		}

		ToTargetLocationQuat.SpringTo(AimDirTarget.ToOrientationQuat(), 120, 0.6, DeltaTime);

		TemporalLog
			.DirectionalArrow("Aim Direction Target", Player.ActorLocation, AimDirTarget * 500, 20, 100, FLinearColor::Red)
			.DirectionalArrow("To Target Location Quat Forward", Player.ActorLocation, ToTargetLocationQuat.Value.ForwardVector * 500, 20, 40, FLinearColor::Green)
		;
		
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
			SprayTimer -= SprayInterval;

			FAcidProjectileParams Params;
			Params.Origin = TargetSocketOrigin;
			Params.ProjectileClass = SprayComp.ProjectileClass;

			Params.PuddleClass = PuddleClass;

			Params.PuddleRadius = SpraySettings.PuddleRadius;
			Params.PuddleDuration = SpraySettings.PuddleDuration;

			Params.Speed = SpraySettings.ProjectileSpeed;
			Params.Range = SpraySettings.AcidSprayRange * SprayComp.AcidSprayRangeMultiplier.Get();

			Params.Target = AimTarget.AimOrigin + ToTargetLocationQuat.Value.Vector() * SpraySettings.AcidSprayRange * SprayComp.AcidSprayRangeMultiplier.Get();

			Params.StartScale = SpraySettings.ProjectileStartScale;
			Params.EndScale = SpraySettings.ProjectileEndScale;
			Params.ScaleUpDuration = SpraySettings.ProjectileScaleUpDuration;
			Params.TraceRadius = SpraySettings.ProjectileTraceRadius;
			Params.SplashRadius = SpraySettings.ProjectileSplashRadius;
			Params.Gravity = SpraySettings.ProjectileGravity;
			Params.LifeTime = SpraySettings.ProjectileLiftTime;
			Params.FiringPlayer = Player;
			Params.Damage = (SpraySettings.FullSprayDamagePerSecond * SprayInterval);

			// Make a trace to see if we should hit sooner than the maximum distance
			FHazeTraceSettings Trace;
			Trace.UseLine();
			Trace.TraceWithChannel(ECollisionChannel::WeaponTraceMio);
			Trace.IgnorePlayers();
			Trace.IgnoreActor(Owner);

			// Inherit Dragon Velocity
			FVector DirToTarget = (Params.Target - Params.Origin).GetSafeNormal();
			float SpeedTowardsTarget = MoveComp.Velocity.DotProduct(DirToTarget);
			Params.Speed += SpeedTowardsTarget;

			FHitResult AimHit;
			AimHit = Trace.QueryTraceSingle(AimTarget.AimOrigin, Params.Target);
			
			if(AutoAimTargetLocation.IsSet())
			{
				Params.Target = AutoAimTargetLocation.Value;
			}
			else if (AimHit.bBlockingHit)
			{
				FVector DirToHit = (AimHit.Location - Params.Origin).GetSafeNormal();
				if(DirToHit.DotProduct(AimTarget.AimDirection) > 0.5)
				{
					float SqrdDistToHit = AimHit.Location.DistSquared(Params.Origin);
					if(SqrdDistToHit >= Math::Square(SpraySettings.AimTraceHitDistanceThreshold))
						Params.Target = AimHit.Location;
				}
			}
			
			Acid::FireAcidProjectile(Params);

			FTeenDragonAcidProjectileEventParams EventParams;
			EventParams.LaunchLocation = Params.Origin;
			EventParams.LaunchDirection = (Params.Target - Params.Origin).GetSafeNormal();
			EventParams.LaunchTarget = Params.Target;
			EventParams.bStreamBlockingHit = AimHit.bBlockingHit;

			UTeenDragonAcidSprayEventHandler::Trigger_AcidProjectileFired(Player, EventParams);
		}

		SprayComp.AlterAcidAlpha(-SpraySettings.AcidReductionAmount * DeltaTime / SprayComp.AcidSprayStaminaMultiplier.Get());

		ApplyTriggerHaptic();
	}

	void ApplyTriggerHaptic()
	{
		FHazeFrameForceFeedback ForceFeedBack;

		float BaseValue = 0.075;
		float NoiseBased = 0.2 * ((Math::Sin(Time::GameTimeSeconds * 10.5) + 1.0) * 0.5);

		float MotorStrength = BaseValue + NoiseBased;

		ForceFeedBack.RightTrigger = MotorStrength;
		ForceFeedBack.RightMotor = MotorStrength;
		
		Player.SetFrameForceFeedback(ForceFeedBack);
	}
}