
class USkylineGecko2DBlobAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"GeckoBlobAttack");

	USkylineGeckoBlobLauncherComponent BlobLauncher;
	USkylineGeckoBlobComponent BlobComp;
	USkylineGeckoComponent GeckoComp;
	UGentlemanCostComponent GentCostComp;

	float EndTime;
	float PrimeTime;
	
	bool bLaunched;
	UTargetTrailComponent TrailComp;

	USkylineGeckoSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BlobLauncher = USkylineGeckoBlobLauncherComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		BlobComp = USkylineGeckoBlobComponent::GetOrCreate(Owner);
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
		if (BlobLauncher == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		
		// Need to be at perch to use this attack
		if (!GeckoComp.IsAtPerch(120.0))
			return false; 

		// Zoe is the only valid target for blob attack
		AHazeActor CurrentTarget = TargetComp.Target;
		if (CurrentTarget != Game::Zoe)
			return false;

		if (!GentCostComp.IsTokenAvailable(Settings.BlobGentlemanCost))	
			return false;

		//if(!PerceptionComp.Sight.VisibilityExists(Owner, CurrentTarget, CollisionChannel = ECollisionChannel::WorldGeometry))
		//	return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(CurrentTarget.ActorCenterLocation, Settings.BlobAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(CurrentTarget.ActorCenterLocation, Settings.BlobMinimumAttackRange))
			return false;

		// Use blob only if latest perch attack was dakka (blob is never used as first attack)
		float LastBlobTime = TargetComp.GentlemanComponent.GetLastActionTime(GeckoTag::BlobAttack);
		float LastDakkaTime = TargetComp.GentlemanComponent.GetLastActionTime(GeckoTag::DakkaAttack);
		if (LastBlobTime > LastDakkaTime - SMALL_NUMBER)
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
		if(ActiveDuration > Settings.BlobTelegraphDuration + Settings.BlobAttackDuration)
			return true;
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		BlobComp.CurrentTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		GentCostComp.ClaimToken(this, Settings.BlobGentlemanCost);
		
		TrailComp = UTargetTrailComponent::GetOrCreate(BlobComp.CurrentTarget); 

		bLaunched = false;

		AnimComp.RequestFeature(FeatureTagGecko::RangedAttack, SubTagGeckoRangedAttack::RangedAttackTelegraph, EBasicBehaviourPriority::Medium, this, Settings.BlobTelegraphDuration);
		USkylineGeckoEffectHandler::Trigger_OnBlobAttackTelegraph(Owner, FGeckoBlobProjectileLaunch(BlobLauncher));

		if (Settings.bAllowBladeHitsWhenPerching)
			GeckoComp.bAllowBladeHits.Apply(true, this);

		TargetComp.GentlemanComponent.ReportAction(GeckoTag::PerchAttack);		
		TargetComp.GentlemanComponent.ReportAction(GeckoTag::BlobAttack);		
		TargetComp.GentlemanComponent.ClaimToken(GeckoToken::Perching, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		UBasicAIAnimationFeatureAdditiveShooting ShootingFeature = Cast<UBasicAIAnimationFeatureAdditiveShooting>(AnimComp.GetFeatureByClass(UBasicAIAnimationFeatureAdditiveShooting));
		if ((ShootingFeature != nullptr) && (ShootingFeature.SingleShot != nullptr))
			Owner.StopSlotAnimationByAsset(Animation = ShootingFeature.SingleShot);

		GentCostComp.ReleaseToken(this, Settings.BlobAttackGlobalCooldown);
		BlobComp.CurrentTarget = nullptr;

		if (TargetComp.GentlemanComponent != nullptr) // If null, token will have already been released
			TargetComp.GentlemanComponent.ReleaseToken(GeckoToken::Perching, Owner);

		// Check for new target after completed attack
		if (bLaunched)
			TargetComp.Target = nullptr;

		GeckoComp.bAllowBladeHits.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(BlobComp.CurrentTarget);

		if(ActiveDuration < Settings.BlobTelegraphDuration)
			return;
		
		if (!bLaunched && (ActiveDuration > Settings.BlobTelegraphDuration + Settings.BlobAttackLaunchDelay))
			Launch();
	}

	private void Launch()
	{
		bLaunched = true;
		AnimComp.RequestFeature(FeatureTagGecko::RangedAttack, SubTagGeckoRangedAttack::RangedAttack, EBasicBehaviourPriority::Medium, this, Settings.BlobAttackDuration);
		USkylineGeckoEffectHandler::Trigger_OnBlobAttackLaunchProjectile(Owner, FGeckoBlobProjectileLaunch(BlobLauncher));

		// Launch projectile at predicted location
		FVector WeaponLoc = BlobLauncher.GetLaunchLocation();
		FVector TargetLoc = BlobComp.CurrentTarget.ActorLocation;
		float PredictionTime = WeaponLoc.Distance(TargetLoc) / Math::Max(100.0, 1600.0);
		FVector PredictionOffset = (TrailComp.GetAverageVelocity(0.5) * PredictionTime);
		FVector PredictedTargetLoc = TargetLoc + PredictionOffset + (BlobComp.CurrentTarget.ActorForwardVector * 300);
		FVector AimDir = (PredictedTargetLoc - WeaponLoc).GetSafeNormal();

		// We don't want to shoot the orb into the abyss
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		FHitResult Hit = Trace.QueryTraceSingle(PredictedTargetLoc, PredictedTargetLoc + AimDir * 1000);
		if(Hit.bBlockingHit && Hit.Normal != BlobComp.CurrentTarget.ActorUpVector)
			AimDir = (TargetLoc - WeaponLoc).GetSafeNormal();

		UBasicAIProjectileComponent Projectile = BlobLauncher.Launch(AimDir * 1600.0, FRotator::MakeFromZ(BlobComp.CurrentTarget.ActorUpVector));
		Projectile.Target = BlobComp.CurrentTarget;
		Projectile.Gravity = 0;
		auto Blob = Cast<ASkylineGecko2DBlob>(Projectile.Owner);
		Blob.Owner = Owner;
	}
}
