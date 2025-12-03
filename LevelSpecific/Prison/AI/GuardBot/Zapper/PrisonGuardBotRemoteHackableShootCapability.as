struct FPrisonGuardBotRemoteHackableShootActivationParams 
{
	AHazeActor Target;
}

class UPrisonGuardBotRemoteHackableShootCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 20;

	UBasicBehaviourComponent BehaviourComp;
	UPrisonGuardBotSettings Settings;
	UBasicAIHealthComponent TargetHealthComp = nullptr;
	float DamageTime;
	float LastShotAtGuardTime = -BIG_NUMBER;
	float LastValidHitTime = -BIG_NUMBER;

	AAIPrisonGuardBotZapper Zapper;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UPrisonGuardBotSettings::GetSettings(Owner);
		BehaviourComp = UBasicBehaviourComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Player);
		Zapper = Cast<AAIPrisonGuardBotZapper>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonGuardBotRemoteHackableShootActivationParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!AimComp.IsAiming(Owner))
			return false;
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!AimComp.IsAiming(Owner))
			return true;
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false; 
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonGuardBotRemoteHackableShootActivationParams Params)
	{
		Super::OnActivated();

		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);

		// TargetHealthComp = (Target == nullptr) ? nullptr : UBasicAIHealthComponent::Get(Target);
		// UPrisonGuardBotEffectHandler::Trigger_OnZapStart(Owner, FPrisonGuardBotZapParams(Params.Target));

		DamageTime = Time::GameTimeSeconds;

		Zapper.AnimComp.RequestFeature(PrisonZapperAnimTags::Shooting, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);

		Zapper.AnimComp.ClearFeature(this);

		// UPrisonGuardBotEffectHandler::Trigger_OnZapStop(Owner, FPrisonGuardBotZapParams(Target));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		AHazeActor Target = FindTarget();
		if (Target != nullptr)
		{
			Zapper.ShootingTargetLocation = AimComp.GetAimingTarget(Owner).AutoAimTarget.WorldLocation;
		}
		else
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnorePlayers();
			Trace.IgnoreActor(Owner);
			Trace.UseLine();

			FHitResult Hit = Trace.QueryTraceSingle(Player.ViewLocation, Player.ViewLocation + (Player.ViewRotation.ForwardVector * 5000.0));
			Zapper.ShootingTargetLocation = Hit.bBlockingHit ? Hit.ImpactPoint : Hit.TraceEnd;

			if (Settings.bZapAttackCanHitRegularGuards && (Hit.Actor != nullptr))
			{
				auto GuardComp = UPrisonGuardComponent::Get(Hit.Actor);
				if (GuardComp != nullptr)
					GuardComp.HitByDrone();
			}

			// Trigger VO event once in a while if we shoot at a ground guard robot
			if (Player.HasControl() && (Hit.Actor != nullptr) && 
				(Time::GetGameTimeSince(LastShotAtGuardTime) > 2.0) && 
				(Time::GetGameTimeSince(LastValidHitTime) > 3.0))
			{
				auto GuardComp = UPrisonGuardComponent::Get(Hit.Actor);
				if ((GuardComp != nullptr) && !IsAimingAtValidTarget(Player.ViewLocation.Distance(Hit.Actor.ActorLocation) + 1000.0))
					CrumbShotAtBadTarget();
			}	
		}

		if (Time::GameTimeSeconds > DamageTime)
		{
			if (Target != nullptr)
			{
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(FindTarget());
				if (HealthComp != nullptr)
				{
					HealthComp.TakeDamage(Settings.ZapAttackAIDamagePerSecond * Settings.ZapAttackDamageInterval, EDamageType::Energy, Player);
					LastValidHitTime = Time::GameTimeSeconds;
				}
			}

			FPrisonGuardBotShootParams ShootParams;
			ShootParams.TargetLoc = Zapper.ShootingTargetLocation;
			UPrisonGuardBotEffectHandler::Trigger_OnShoot(Owner, ShootParams);

			DamageTime += Settings.ZapAttackDamageInterval;
		}

		float FFStrength = Target == nullptr ? 0.1 : 1.0;
		float LeftFF = Math::Sin(ActiveDuration * 60.0) * FFStrength;
		float RightFF = Math::Sin(-ActiveDuration * 60.0) * FFStrength;
		float TriggerFF = Math::Sin((ActiveDuration + 0.8) * 90.0) * FFStrength;
		Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, TriggerFF);
	}

	AHazeActor FindTarget() const
	{
		if(!AimComp.IsAiming(Owner))
			return nullptr;

		FAimingResult AimResult = AimComp.GetAimingTarget(Owner);
		if (AimResult.AutoAimTarget == nullptr)
			return nullptr;
		AHazeActor Target = Cast<AHazeActor>(AimResult.AutoAimTarget.Owner);
		if (Target == Zapper)
			return nullptr;
		if (Target == Game::Mio)
			return nullptr;	
		return Target;
	}

	/*AHazeActor FindTarget() const
	{
		// Keep current target until dead 
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector ViewDir = Player.ViewRotation.Vector();
		if ((TargetHealthComp != nullptr) && TargetHealthComp.IsAlive())
		{
			// Target should still be in front of us to be reused
			if (ViewDir.DotProduct(Target.ActorCenterLocation - OwnLoc) > 0.0)
				return Target;
		}

		if (BehaviourComp.Team == nullptr)
			return nullptr;

		// Find closest target within a minimum angle
		float BestDistSqr = Math::Square(Settings.ZapAttackHackedRange);
		AHazeActor BestTarget = nullptr;
		float CosAngle = Math::Cos(Math::DegreesToRadians(Settings.ZapAttackHackedHitAngle));
		for (AHazeActor PotentialTarget : BehaviourComp.Team.GetMembers())		
		{
			if (PotentialTarget == nullptr)
				continue;
			FVector ToTarget = PotentialTarget.ActorCenterLocation - OwnLoc;
			float DistSqr = ToTarget.SizeSquared();
			if (DistSqr > BestDistSqr)
				continue;
			if (ViewDir.DotProduct(ToTarget.GetSafeNormal()) < CosAngle)
				continue;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(Owner);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(Owner.ActorCenterLocation, PotentialTarget.ActorCenterLocation);
			if (Hit.bBlockingHit)
			{
				if (Hit.Actor == PotentialTarget)
				{
					BestTarget = PotentialTarget;
					BestDistSqr = DistSqr;
				}
			}
		}

		return BestTarget;
	}*/

	bool IsAimingAtValidTarget(float Range)
	{
		FVector AimOrigin = Player.ViewLocation + Player.ViewRotation.ForwardVector * 100.0;
		FVector AimEnd = AimOrigin + Player.ViewRotation.ForwardVector * (Range - 100.0);

		for (AAIPrisonGuardBotZapper Drone : TListedActors<AAIPrisonGuardBotZapper>())
		{
			if (Drone == Owner)
				continue;			
			// Count as being aimed at if within teardrop spreading out to ~30 degree arc
			if (!Drone.ActorCenterLocation.IsInsideTeardrop(AimOrigin, AimEnd, 100.0, Range * 0.25)) 
				continue;
			return true;
		}
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbShotAtBadTarget()
	{
		LastShotAtGuardTime = Time::GameTimeSeconds;
		UPrisonGuardBotEffectHandler::Trigger_OnShootAtBadTarget(Owner);
	}
}
