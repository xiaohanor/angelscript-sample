class UTundraGnatapultReloadBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UTundraGnatapultProjectileLauncherComponent Launcher;
	UTundraGnatapultSettings Settings;
	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Launcher = UTundraGnatapultProjectileLauncherComponent::Get(Owner);
		TargetPlayer = Game::Mio;
		Settings = UTundraGnatapultSettings::GetSettings(Owner);
	}

	// Always reload when there is nothing more important afoot

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(TundraGnatTags::GnatapultReload, EBasicBehaviourPriority::Medium, this);
		UBasicAIProjectileComponent Projectile = Launcher.Launch(FVector::ZeroVector);
		Launcher.Projectile = Cast<ATundraGnatapultProjectile>(Projectile.Owner);
		Launcher.Projectile.StartMaking(Launcher, TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > Settings.ReloadMinDuration)
			Launcher.bLoaded = true;

		if (TargetComp.IsValidTarget(TargetPlayer))
			DestinationComp.RotateTowards(TargetPlayer);
		else 
			DestinationComp.RotateInDirection(Owner.ActorForwardVector);
	}
}
