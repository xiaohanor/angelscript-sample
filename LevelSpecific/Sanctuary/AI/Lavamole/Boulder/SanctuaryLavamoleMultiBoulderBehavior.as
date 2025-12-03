struct FSanctuaryLavamoleMultiProjectileBoulderData
{
	FSanctuaryLavamoleBoulderCreationData SpawnData;
	bool bPrimed = false;
	bool bLaunched = false;
	float PrimeTimeStamp = 0.0;
	float LaunchTimeStamp = 0.0;
	UBasicAIProjectileComponent Projectile = nullptr;
}

class USanctuaryLavamoleMultiBoulderBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	AAISanctuaryLavamole Mole;
	USanctuaryLavamoleSettings Settings;
	USanctuaryLavamoleMultiBoulderLauncherComponent ProjectileLauncher;
	UBasicAIHealthComponent HealthComp;
	USanctuaryLavamoleMultiBoulderComponent ShootComp;

	TArray<FSanctuaryLavamoleMultiProjectileBoulderData> Projectiles;
	FBasicAIAnimationActionDurations Durations;
	float LastActiveDuration = 0.0;
	FVector ActivatedTowardsCentipedeDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		ProjectileLauncher = USanctuaryLavamoleMultiBoulderLauncherComponent::Get(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		ShootComp = USanctuaryLavamoleMultiBoulderComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnDie");

		Durations.Telegraph = Settings.BoulderTelegraphDuration;
		Durations.Anticipation = Settings.BoulderAnticipationDuration;
		Durations.Action = Settings.BoulderAttackDuration;
		Durations.Recovery = Settings.BoulderRecoveryDuration;

		TArray<UCentipedeBiteResponseComponent> Bites;
		Owner.GetComponentsByClass(Bites);
		for(UCentipedeBiteResponseComponent Bite: Bites)
		{
			Bite.OnCentipedeBiteStarted.AddUFunction(this, n"BiteStarted");
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if (TargetComp.Target == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if (Projectiles.Num() == 0)
			return true;

		// stay in behavior until all durations are done
		if (HasLaunchedAllProjectiles() && ActiveDuration > Projectiles.Last().PrimeTimeStamp + Durations.GetTotal()) 
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (ShootComp == nullptr)
			return;

		TArray<FSanctuaryLavamoleBoulderCreationData> TempSpawnData;
		ShootComp.GetNextShootPattern(TempSpawnData);
		for (const FSanctuaryLavamoleBoulderCreationData& SpawnData : TempSpawnData) 
		{
			FSanctuaryLavamoleMultiProjectileBoulderData ProjectileData;
			ProjectileData.SpawnData = SpawnData;
			Projectiles.Add(ProjectileData);
		}

		TArray<FVector> Locations = GetTailLocations();
		FVector AttackLocation;
		for(FVector Location: Locations)
			AttackLocation += Location;
		AttackLocation = AttackLocation / Locations.Num();
		ActivatedTowardsCentipedeDirection = (AttackLocation - ProjectileLauncher.LaunchLocation).GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ExpireUnlaunchedProjectiles();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector TinyScale = FVector::OneVector * 0.001;
		for (int i = 0; i < Projectiles.Num(); ++i) 
		{
			FSanctuaryLavamoleMultiProjectileBoulderData& ProjectileData = Projectiles[i];
			if (!ProjectileData.bPrimed && ProjectileData.SpawnData.SpawnDelay >= LastActiveDuration && ProjectileData.SpawnData.SpawnDelay <= ActiveDuration)
				PrimeProjectile(i);

			if (!ProjectileData.bPrimed)
				continue;

			float ProjectileActiveDuration = ActiveDuration - ProjectileData.PrimeTimeStamp;

			// snowball
			if (Settings.BoulderSnowballDuration > KINDA_SMALL_NUMBER)
			{
				float InterpolationValue = Math::Clamp(ProjectileActiveDuration / Settings.BoulderSnowballDuration, 0.0, 1.0);
				ProjectileData.Projectile.Owner.SetActorScale3D(Math::EaseInOut(TinyScale, FVector::OneVector, InterpolationValue, 2));
			}
			else
				ProjectileData.Projectile.Owner.SetActorScale3D(FVector::OneVector);

			if(!ProjectileData.bLaunched && Durations.IsInActionRange(ProjectileActiveDuration))
				Launch(i, ProjectileData);
		}

		LastActiveDuration = ActiveDuration;
	}

	// ---------------

	private void PrimeProjectile(int Index)
	{
		if (!HasControl())
			return;

		CrumbPrimeProjectile(Index);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPrimeProjectile(int Index)
	{
		FSanctuaryLavamoleMultiProjectileBoulderData& ProjectileData = Projectiles[Index];
		ProjectileData.bPrimed = true;
		ProjectileData.PrimeTimeStamp = ActiveDuration;
		ProjectileData.Projectile = ProjectileLauncher.Prime();
		Cast<ASanctuaryLavamoleBoulderProjectile>(ProjectileData.Projectile.Owner).Owner = Owner;
		const FVector TinyScale = FVector::OneVector * 0.001;
		ProjectileData.Projectile.Owner.SetActorScale3D(TinyScale);

		USanctuaryLavamoleEventHandler::Trigger_OnBoulderTelegraph(Owner, FSanctuaryLavamoleOnBoulderTelegraphEventData(ProjectileLauncher.LaunchLocation));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(ProjectileLauncher, Durations.GetPreActionDuration()));	
	}

	private void Launch(int Index, FSanctuaryLavamoleMultiProjectileBoulderData& ProjectileData)
	{
		if (!HasControl())
			return;

		FVector StartDirection = ProjectileLauncher.ForwardVector;
		if (ProjectileData.SpawnData.AngleSpace == ESanctuaryLavamoleBoulderAngleSpace::TowardsCentipedeMiddle)
			StartDirection = ActivatedTowardsCentipedeDirection;
		else if (ProjectileData.SpawnData.AngleSpace == ESanctuaryLavamoleBoulderAngleSpace::WorldSpace)
			StartDirection = FVector::ForwardVector;

		if (!Math::IsNearlyEqual(ProjectileData.SpawnData.Angle, 0.0))
			StartDirection = FRotator::MakeFromEuler(FVector(0.0, 0.0, ProjectileData.SpawnData.Angle)).RotateVector(StartDirection);

		CrumbLaunch(Index, StartDirection);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunch(int Index, FVector StartDirection)
	{
		FSanctuaryLavamoleMultiProjectileBoulderData& ProjectileData = Projectiles[Index];
		ProjectileData.bLaunched = true;
		FVector TargetLocation = ProjectileLauncher.LaunchLocation + StartDirection * 300.0;
		Cast<ASanctuaryLavamoleBoulderProjectile>(ProjectileData.Projectile.Owner).AttackLocation = TargetLocation;
		ProjectileLauncher.Launch(StartDirection * Settings.BoulderProjectileSpeed);
		ProjectileData.Projectile.Friction = 0;
		ProjectileData.Projectile.UpVector = -Owner.ActorRightVector;
		ProjectileData.Projectile.Gravity = ProjectileData.SpawnData.CurveToRight;
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(ProjectileLauncher, 1, 1));
	}

	private TArray<FVector> GetTailLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(TargetComp.Target);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}

	UFUNCTION()
	private void BiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		ExpireUnlaunchedProjectiles();
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		ExpireUnlaunchedProjectiles();
	}

	private void ExpireUnlaunchedProjectiles()
	{
		for (FSanctuaryLavamoleMultiProjectileBoulderData& ProjectileData : Projectiles) 
		{
			if(ProjectileData.Projectile != nullptr && !ProjectileData.Projectile.bIsLaunched)
				ProjectileData.Projectile.Expire();
		}
		Projectiles.Empty();
	}

	private bool HasLaunchedAllProjectiles() const
	{
		for (const FSanctuaryLavamoleMultiProjectileBoulderData& ProjectileData : Projectiles) 
		{
			if (!ProjectileData.bLaunched)
				return false;
		}
		return true;
	}

}