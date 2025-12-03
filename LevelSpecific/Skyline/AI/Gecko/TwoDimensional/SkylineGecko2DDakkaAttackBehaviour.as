
class USkylineGecko2DDakkaAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"GeckoDakkaAttack");

	USkylineGeckoDakkaLauncherComponent DakkaLauncher;
	USkylineGeckoComponent GeckoComp;
	UGentlemanCostComponent GentCostComp;

	float EndTime;
	float PrimeTime;
	
	float DakkaTime = BIG_NUMBER;
	int NumShotsFired = 0;
	int NumShotsPerBurst = 0;
	int NumShotsFiredInBurst = 0;

	UTargetTrailComponent TrailComp;

	USkylineGeckoSettings Settings;
	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		DakkaLauncher = USkylineGeckoDakkaLauncherComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		AnimComp.bIsAiming = true;
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (DakkaLauncher == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		
		// Need to be at perch to use this attack
		if (!GeckoComp.IsAtPerch(120.0))
			return false; 

		// Zoe is the only valid target for dakka attack
		AHazeActor CurrentTarget = TargetComp.Target;
		if (CurrentTarget != Game::Zoe)
			return false;

		if (!GentCostComp.IsTokenAvailable(Settings.DakkaGentlemanCost))	
			return false;

		//if(!PerceptionComp.Sight.VisibilityExists(Owner, CurrentTarget, CollisionChannel = ECollisionChannel::WorldGeometry))
		//	return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(CurrentTarget.ActorCenterLocation, Settings.DakkaAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(CurrentTarget.ActorCenterLocation, Settings.DakkaMinimumAttackRange))
			return false;

		// Use dakka only if latest perch attack was a blob (or this is first attack)
		float LastBlobTime = TargetComp.GentlemanComponent.GetLastActionTime(GeckoTag::BlobAttack);
		float LastDakkaTime = TargetComp.GentlemanComponent.GetLastActionTime(GeckoTag::DakkaAttack);
		if (LastDakkaTime > LastBlobTime + SMALL_NUMBER)
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.DakkaTelegraphDuration + Settings.DakkaAttackDuration + Settings.DakkaRecoveryDuration)
			return true;
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		GentCostComp.ClaimToken(this, Settings.DakkaGentlemanCost);
		
		TrailComp = UTargetTrailComponent::GetOrCreate(Target); 

		AnimComp.RequestFeature(FeatureTagGecko::RangedAttack, SubTagGeckoRangedAttack::RangedAttackTelegraph, EBasicBehaviourPriority::Medium, this, Settings.DakkaTelegraphDuration);
		USkylineGeckoEffectHandler::Trigger_OnDakkaAttackTelegraph(Owner, FGeckoDakkaProjectileLaunch(DakkaLauncher));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(DakkaLauncher, Settings.DakkaTelegraphDuration));	

		// Set up burst parameters (note that exact total duration is less important than exact intervals, for audio)
		NumShotsFired = 0;
		NumShotsFiredInBurst = 0;
		DakkaTime = Settings.DakkaTelegraphDuration;
		float LaunchInterval = Math::Max(Settings.DakkaLaunchInterval, 0.01);
		float BurstInterval = Settings.DakkaBurstInterval;
		int NumBursts = Math::Max(Settings.DakkaBurstNumber, 1);

		// Since AttackDuration = (ShotsPerBurst * LaunchInterval + BurstInterval) * NumBursts - BurstInterval: 
		NumShotsPerBurst = Math::RoundToInt((((Settings.DakkaAttackDuration + BurstInterval) / float(NumBursts)) - BurstInterval) / LaunchInterval);

		if (Settings.bAllowBladeHitsWhenPerching)
			GeckoComp.bAllowBladeHits.Apply(true, this);

		TargetComp.GentlemanComponent.ReportAction(GeckoTag::PerchAttack);		
		TargetComp.GentlemanComponent.ReportAction(GeckoTag::DakkaAttack);		
		TargetComp.GentlemanComponent.ClaimToken(GeckoToken::Perching, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		GentCostComp.ReleaseToken(this, Settings.DakkaAttackTokenCooldown);

		if (TargetComp.GentlemanComponent != nullptr) // If null, token will have already been released
			TargetComp.GentlemanComponent.ReleaseToken(GeckoToken::Perching, Owner);

		GeckoComp.bAllowBladeHits.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Target);
		
		if (ActiveDuration > DakkaTime)
		{
			int NumShotsTotal = NumShotsPerBurst * Settings.DakkaBurstNumber;
			NumShotsFired++;
			NumShotsFiredInBurst++;

			// Replace with start/mh/end for each burst
			AnimComp.RequestFeature(FeatureTagGecko::RangedAttack, SubTagGeckoRangedAttack::RangedAttack, EBasicBehaviourPriority::Medium, this);

			// Launch projectile at where target was a while ago
			FVector WeaponLoc = DakkaLauncher.GetLaunchLocation();
			FVector TargetLoc = TrailComp.GetTrailLocation(Settings.DakkaAttackAimLocationAge) + Target.ActorUpVector * 20.0;
			FVector AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();

			// Dakka dakka dakka!
			UBasicAIProjectileComponent Projectile = DakkaLauncher.Launch(AimDir * Settings.DakkaProjectileSpeed, FRotator::MakeFromX(AimDir));
			Projectile.Damage = Settings.DakkaDamagePerSecond * Settings.DakkaLaunchInterval; // Ignore burst intervals for this
			USkylineGeckoEffectHandler::Trigger_OnDakkaAttackLaunchProjectile(Owner, FGeckoDakkaProjectileLaunch(DakkaLauncher));
			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(DakkaLauncher, NumShotsFired, NumShotsTotal));

			if (NumShotsFiredInBurst == 1)
				USkylineGeckoEffectHandler::Trigger_OnDakkaAttackBurstStart(Owner, FGeckoDakkaProjectileLaunch(DakkaLauncher));

			if (NumShotsFired >= NumShotsTotal)
			{
				DakkaTime = BIG_NUMBER; 
				USkylineGeckoEffectHandler::Trigger_OnDakkaAttackDone(Owner, FGeckoDakkaProjectileLaunch(DakkaLauncher));
			}
			else if (NumShotsFiredInBurst >= NumShotsPerBurst)
			{
				NumShotsFiredInBurst = 0;
				DakkaTime += Settings.DakkaBurstInterval;							
				USkylineGeckoEffectHandler::Trigger_OnDakkaAttackBurstEnd(Owner, FGeckoDakkaProjectileLaunch(DakkaLauncher));
			}
			else
			{
				DakkaTime += Settings.DakkaLaunchInterval;
			}

		}
	}
}
