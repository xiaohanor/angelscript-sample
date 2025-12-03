class UIslandAttackShipBeamAttackBehaviour : UBasicBehaviour
{
	UGentlemanCostComponent GentCostComp;
	UIslandAttackShipBeamLauncherComponent LauncherComp;
	UIslandAttackShipTrackingLaserComponent TrackingLaserComp;

	FVector InitialCannonLocalLocation;
	FVector KickbackOffset;

	UIslandAttackShipSettings Settings;

	private float FiredTime = 0.0;
	private int FiredProjectiles = 0;
	private float ActivationDelayTime = 1.0;
	private float TargetInvisibleTimer = 0.0;
	private const float TargetInvisibleTimeLimit = 1.0;

	AAIIslandAttackShip AttackShip;
	FHazeAcceleratedVector AccLaserEndLocation;
	FHazeAcceleratedRotator AccCannonRotator;

	AHazeActor CurrentTarget;

	FVector CurrentLaserAimDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		LauncherComp = UIslandAttackShipBeamLauncherComponent::Get(Owner);
		TrackingLaserComp = UIslandAttackShipTrackingLaserComponent::Get(Owner);

		Settings = UIslandAttackShipSettings::GetSettings(Owner);

		AttackShip = Cast<AAIIslandAttackShip>(Owner);
	}
	
	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;		
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MaxAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.MinAttackRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasGeometryVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.GentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (TargetInvisibleTimer > TargetInvisibleTimeLimit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		

		CurrentTarget = TargetComp.Target;

		FiredProjectiles = 0;

		GentCostComp.ClaimToken(this, Settings.GentlemanCost);
		TrackingLaserComp.TrackingLaserParams.LaserStartLocation = LauncherComp.WorldLocation;
		TrackingLaserComp.TrackingLaserParams.LaserEndLocation = LauncherComp.WorldLocation;
		CurrentLaserAimDir = LauncherComp.ForwardVector;

		AccLaserEndLocation.SnapTo(LauncherComp.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		bHasStartedTelegraphing = false;
		bHasStoppedTelegraphing = false;
		bHasStartedLaunchTelegraphing = false;
		TargetInvisibleTimer = 0.0;
		UIslandAttackShipEffectHandler::Trigger_OnBeamAttackStopTelegraphing(Owner);
		UIslandAttackShipEffectHandler::Trigger_OnStopTelegraphingTrackingLaser(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (AttackShip.bHasPilotDied)
			return;

		if (!AttackShip.bHasFinishedEntry)
			return;

		if (AttackShip.CannonMesh.IsHiddenInGame())
		{
			AttackShip.CannonMesh.SetHiddenInGame(false);
			AttackShip.BP_HideCutsceneCannon();
			AccCannonRotator.SnapTo(Owner.ActorForwardVector.Rotation());
		}

		FVector TargetDir;
		if (TargetComp.HasValidTarget())
		{
			float Deg = Math::RadiansToDegrees(Math::Acos(TargetDir.DotProduct(FVector::UpVector)));
			TargetDir = (TargetComp.Target.ActorCenterLocation - LauncherComp.WorldLocation).GetSafeNormal();
			if (Deg > 120 || TargetDir.DotProduct(AttackShip.CannonMesh.ForwardVector) < 0.5) // Clamp aim angle a bit
			{
				TargetDir = Owner.ActorForwardVector;
			}
		}
		else
		{
			TargetDir = Owner.ActorForwardVector;
		}
		
		AccCannonRotator.AccelerateTo(TargetDir.Rotation(), 0.5, DeltaTime);
		AttackShip.CannonMesh.SetWorldRotation(AccCannonRotator.Value);	
	}

	bool bHasStartedTelegraphing = false;
	bool bHasStoppedTelegraphing = false;
	bool bHasStartedLaunchTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < ActivationDelayTime)
		{
			return;
		}
		else if (!bHasStartedTelegraphing)
		{
			bHasStartedTelegraphing = true;
			UIslandAttackShipEffectHandler::Trigger_OnStartTelegraphingTrackingLaser(Owner, FIslandAttackShipLaserTrackingTelegraphingParams(TrackingLaserComp));
			UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(LauncherComp, Settings.TelegraphDuration));
		}

		// Check visibility
		if (!TargetComp.HasGeometryVisibleTarget())
			TargetInvisibleTimer += DeltaTime;
		else
			TargetInvisibleTimer = 0.0;

		if(ActiveDuration < ActivationDelayTime + Settings.TelegraphDuration)
		{	
			float TurnRate = 35;		
			FVector ToTargetDir = (CurrentTarget.ActorCenterLocation - LauncherComp.WorldLocation).GetSafeNormal(); //ConstrainToPlane(Owner.ActorRightVector);
			CurrentLaserAimDir = CurrentLaserAimDir.RotateTowards(ToTargetDir, TurnRate * DeltaTime); //.ConstrainToPlane(Owner.ActorRightVector);

			// LaserTrace
			TArray<EObjectTypeQuery> ObjectTypes;
			ObjectTypes.Add(EObjectTypeQuery::PhysicsBody); // Hit the player mesh
			ObjectTypes.Add(EObjectTypeQuery::WorldStatic); // Hit world geometry
			ObjectTypes.Add(EObjectTypeQuery::WorldDynamic); // Hit world geometry
			FHazeTraceSettings Trace = Trace::InitObjectTypes(ObjectTypes);
			Trace.UseLine();
			FHitResult Hit;
			Hit = Trace.QueryTraceSingle(LauncherComp.WorldLocation, LauncherComp.WorldLocation + CurrentLaserAimDir * Settings.TrackingLaserRange);
			if (Hit.bBlockingHit)
			{
				AccLaserEndLocation.SnapTo(Hit.ImpactPoint);
			}
			else
			{
				AccLaserEndLocation.AccelerateTo(LauncherComp.WorldLocation + CurrentLaserAimDir * Settings.TrackingLaserRange, 0.25, DeltaTime);
			}
			TrackingLaserComp.TrackingLaserParams.LaserEndLocation = AccLaserEndLocation.Value;
			TrackingLaserComp.TrackingLaserParams.LaserStartLocation = LauncherComp.WorldLocation;
			if (ActiveDuration > (ActivationDelayTime + Settings.TelegraphDuration - Settings.TelegraphLaunchDuration) && !bHasStartedLaunchTelegraphing)
			{
				UIslandAttackShipEffectHandler::Trigger_OnBeamAttackStartTelegraphing(Owner, FIslandAttackShipBeamTelegraphingParams(LauncherComp.WorldLocation, TrackingLaserComp));
				bHasStartedLaunchTelegraphing = true;
			}
			return;
		}
		if (!bHasStoppedTelegraphing)
		{
			bHasStoppedTelegraphing = true;
			UIslandAttackShipEffectHandler::Trigger_OnStopTelegraphingTrackingLaser(Owner);
		}


		// Fire projectile
		if(HasControl() && FiredProjectiles < Settings.ProjectileAmount && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > Settings.TimeBetweenBurstProjectiles))
		{
			if (Owner.IsAnyCapabilityActive(n"SwitchingWaypoint"))
			{
				// When switching waypoint view might get obstructed.
				if (HasClearTarget())
					CrumbFireProjectile();
				else
					FiredTime = Time::GetGameTimeSeconds(); // Postpone fire
			}
			else
			{
				CrumbFireProjectile();
			}
		}
		else if (FiredProjectiles == Settings.ProjectileAmount)
		{
			Cooldown.Set(Settings.LaunchInterval - ActiveDuration);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbFireProjectile()
	{		
		FVector AimDir = LauncherComp.ForwardVector;
		if (TargetComp.HasValidTarget())
			AimDir = (TargetComp.Target.ActorCenterLocation - LauncherComp.WorldLocation).GetSafeNormal();

		UBasicAIProjectileComponent ProjectileComp = LauncherComp.Launch(AimDir * Settings.LaunchSpeed);		
		
		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();

		UIslandAttackShipBeamProjectileEventHandler::Trigger_OnLaunch(ProjectileComp.HazeOwner);
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(LauncherComp, FiredProjectiles, Settings.ProjectileAmount));		
	}

	bool HasClearTarget()
	{
		if (!TargetComp.HasValidTarget())
			return false;
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(TargetComp.Target);
		FHitResult Obstruction = Trace.QueryTraceSingle(LauncherComp.WorldLocation, TargetComp.Target.ActorCenterLocation);

		// if (!Obstruction.bBlockingHit)
		// 	Debug::DrawDebugLine(LauncherComp.WorldLocation, TargetComp.Target.ActorCenterLocation, FLinearColor::Green, Duration = 1.0);
		// else
		// 	Debug::DrawDebugLine(LauncherComp.WorldLocation, Obstruction.ImpactPoint, FLinearColor::Red, Duration = 1.0);
		return !Obstruction.bBlockingHit;
	}
}

