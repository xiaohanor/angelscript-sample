
// note(Ylva) DEPRECATED / UNUSED! Might be recycled onto grimbeast later tho
class USanctuaryLavamoleBoulderBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USanctuaryLavamoleSettings Settings;
	USanctuaryLavamoleMultiBoulderLauncherComponent ProjectileLauncher;
	UBasicAIHealthComponent HealthComp;

	bool bLaunched;
	FBasicAIAnimationActionDurations Durations;
	UBasicAIProjectileComponent Projectile;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ProjectileLauncher = USanctuaryLavamoleMultiBoulderLauncherComponent::Get(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnDie");

		TArray<UCentipedeBiteResponseComponent> Bites;
		Owner.GetComponentsByClass(Bites);
		for(UCentipedeBiteResponseComponent Bite: Bites)
		{
			Bite.OnCentipedeBiteStarted.AddUFunction(this, n"BiteStarted");
		}
	}

	UFUNCTION()
	private void BiteStarted(FCentipedeBiteEventParams BiteParams)
	{		
		if(Projectile != nullptr && !Projectile.bIsLaunched)
			Projectile.Expire();
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		if(Projectile != nullptr && !Projectile.bIsLaunched)
			Projectile.Expire();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bLaunched = false;

		Durations.Telegraph = Settings.BoulderTelegraphDuration;
		Durations.Anticipation = Settings.BoulderAnticipationDuration;
		Durations.Action = Settings.BoulderAttackDuration;
		Durations.Recovery = Settings.BoulderRecoveryDuration;

		Projectile = ProjectileLauncher.Prime();
		Cast<ASanctuaryLavamoleBoulderProjectile>(Projectile.Owner).Owner = Owner;
		Projectile.Owner.SetActorScale3D(FVector::ZeroVector);

		USanctuaryLavamoleEventHandler::Trigger_OnBoulderTelegraph(Owner, FSanctuaryLavamoleOnBoulderTelegraphEventData(ProjectileLauncher.LaunchLocation));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(ProjectileLauncher, Durations.GetPreActionDuration()));	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Durations.IsInTelegraphRange(ActiveDuration))
		{
			float ScalingInterpolation = Math::Clamp(ActiveDuration / Durations.Telegraph, 0.0, 1.0);
			Projectile.Owner.SetActorScale3D(FVector::OneVector * ScalingInterpolation);
			DestinationComp.RotateTowards(TargetComp.Target);
		}

		if(!bLaunched && Durations.IsInActionRange(ActiveDuration))
		{
			bLaunched = true;

			TArray<FVector> Locations = GetTailLocations();
			FVector AttackLocation;
			for(FVector Location: Locations)
				AttackLocation += Location;
			AttackLocation = AttackLocation / Locations.Num();

			Cast<ASanctuaryLavamoleBoulderProjectile>(Projectile.Owner).AttackLocation = AttackLocation;
			FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ProjectileLauncher.LaunchLocation, AttackLocation, Settings.BoulderProjectileGravity, Settings.BoulderProjectileSpeed, Owner.ActorRightVector);
			ProjectileLauncher.Launch(Velocity);
			Projectile.Friction = 0;
			Projectile.UpVector = Owner.ActorRightVector;
			Projectile.Gravity = Settings.BoulderProjectileGravity;
			Projectile.Owner.SetActorScale3D(FVector::OneVector);

			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(ProjectileLauncher, 1, 1));			
		}
	}

	private TArray<FVector> GetTailLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(TargetComp.Target);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}
}