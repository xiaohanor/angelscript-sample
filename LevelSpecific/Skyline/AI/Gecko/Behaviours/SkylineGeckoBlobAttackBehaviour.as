
class USkylineGeckoBlobAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"GeckoBlobAttack");

	USkylineGeckoBlobLauncherComponent BlobLauncher;
	USkylineGeckoBlobComponent BlobComp;
	USkylineGeckoComponent GeckoComp;

	const FName BlobAttackToken = n"BlobAttackToken";

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
		AnimComp.bIsAiming = true;

		// We spawn 2^Splits projectiles and there may be a second set around if the player grabs them
		BlobLauncher.PrepareProjectiles((1 << uint(Settings.BlobSplits)) * 2);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (BlobLauncher == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		
		// Zoe is the only valid target for blob attack
		AHazeActor CurrentTarget = TargetComp.Target;
		if (CurrentTarget != Game::Zoe)
			return false;

		// Only one can blob at a time
		if (!TargetComp.GentlemanComponent.CanClaimToken(BlobAttackToken, this))	
			return false;

		if (!Owner.ActorCenterLocation.IsWithinDist(CurrentTarget.ActorCenterLocation, Settings.BlobAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(CurrentTarget.ActorCenterLocation, Settings.BlobMinimumAttackRange))
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
		TargetComp.GentlemanComponent.ClaimToken(BlobAttackToken, this);
		
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

		if (TargetComp.GentlemanComponent != nullptr) // If null, token will have already been released
			TargetComp.GentlemanComponent.ReleaseToken(BlobAttackToken, this, Settings.BlobAttackGlobalCooldown);	
		BlobComp.CurrentTarget = nullptr;

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

		// Launch projectile in between us and target
		FVector WeaponLoc = BlobLauncher.GetLaunchLocation();
		FVector TargetLoc = BlobComp.CurrentTarget.ActorLocation * 0.2 + WeaponLoc * 0.8;
		TargetLoc.Z = BlobComp.CurrentTarget.ActorLocation.Z;
		float TrajectoryHeight = Math::Max(0.0, TargetLoc.Z + Settings.BlobLaunchHeight - WeaponLoc.Z);
		FVector LaunchVel = Trajectory::CalculateVelocityForPathWithHeight(WeaponLoc, TargetLoc, Settings.BlobGravity, TrajectoryHeight);
		LaunchVel = LaunchVel.GetClampedToSize2D(Settings.BlobLaunchSpeed, Settings.BlobLaunchSpeed * 1.5);

		UBasicAIProjectileComponent Projectile = BlobLauncher.Launch(LaunchVel, FRotator::MakeFromZ(BlobComp.CurrentTarget.ActorUpVector));
		Projectile.Target = BlobComp.CurrentTarget;
		Projectile.Gravity = Settings.BlobGravity;
		Cast<ASkylineGeckoBlob>(Projectile.Owner).Launch(BlobLauncher, Settings.BlobSplits, true);
	}
}
