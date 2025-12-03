class USummitMageCritterSlugBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AAISummitMage SummitMage;
	USummitMageSettings MageSettings;

	// ASummitMetalSpawner TargetMetalSpawner;
	UGentlemanComponent GentComp;
	UBasicAIHealthComponent HealthComp;
	USummitMageCritterSlugLauncherComponent LauncherComp;
	USummitMageModeComponent ModeComp;	

	private FName Token = n"CritterSlug";
	AHazeActor TargetPlate;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SummitMage = Cast<AAISummitMage>(Owner);
		MageSettings = USummitMageSettings::GetSettings(Owner);
		ModeComp = USummitMageModeComponent::GetOrCreate(Owner);
		LauncherComp = USummitMageCritterSlugLauncherComponent::GetOrCreate(Owner);
		GentComp = UGentlemanComponent::GetOrCreate(Game::Zoe);
		GentComp.SetMaxAllowedClaimants(Token, int(MageSettings.CritterSlugGentlemanCost));
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		// if(ModeComp.Mode != ESummitMageMode::Ranged)
		// 	return false;
		UHazeTeam CritterTeam = HazeTeam::GetTeam(SummitMageTags::SummitMageCritterTeam);
		if(CritterTeam != nullptr)
		{
			if(CritterTeam.GetMembers().Num() >= MageSettings.MaxCritters)
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		if(!GentComp.IsTokenAvailable(Token, int(MageSettings.CritterSlugGentlemanCost)))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > MageSettings.SummonCritterTelegraphDuration + MageSettings.SummonCritterDuration + MageSettings.SummonCritterRecoveryDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentComp.ClaimToken(Token, this, int(MageSettings.CritterSlugGentlemanCost));

		TargetPlate = GetTargetPlate();
		if(TargetPlate == nullptr)
			TargetLocation = TargetComp.Target.ActorLocation;
		else
			TargetLocation = TargetPlate.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Spawn();
		Cooldown.Set(MageSettings.CritterSlugCooldown);
		GentComp.ReleaseToken(Token, this, MageSettings.CritterSlugTokenCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Game::Zoe);
	}

	void Spawn()
	{
		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(LauncherComp.WorldLocation, TargetLocation, MageSettings.SpawnProjectileGravity, MageSettings.SpawnProjectileSpeed);
		UBasicAIProjectileComponent Projectile = LauncherComp.Launch(Velocity, LauncherComp.WorldRotation);
		Projectile.Gravity = MageSettings.SpawnProjectileGravity;
		for(auto Member:  HazeTeam::GetTeam(AITeams::Default).GetMembers())
		{
			if (Member == nullptr)
				continue;
			Projectile.AdditionalIgnoreActors.Add(Member);	
		}
	}

	// Return true if updated successfully
	AHazeActor GetTargetPlate()
	{
		UHazeTeam UserTeam = HazeTeam::GetTeam(n"SummitPlateUser");
		UHazeTeam PlateTeam = HazeTeam::GetTeam(n"SummitMagePlates");

		if(PlateTeam == nullptr)
			return nullptr;

		TArray<ASummitActivationPlate> ValidPlates;

		for(AHazeActor Member: PlateTeam.GetMembers())
		{
			if (Member == nullptr)
				continue;

			if(UserTeam != nullptr)
			{
				for(AHazeActor User: UserTeam.GetMembers())
				{
					if (User == nullptr)
						continue;
					USummitMagePlateComponent PlateComp = USummitMagePlateComponent::GetOrCreate(User);
					if(PlateComp.TargetPlate == Member)
						continue;
				}
			}

			ASummitActivationPlate Plate = Cast<ASummitActivationPlate>(Member);
			if(!Plate.bActivated)
				ValidPlates.Add(Plate);
		}

		if(ValidPlates.Num() == 0)
			return nullptr;

		return ValidPlates[Math::RandRange(0, ValidPlates.Num()-1)];
	}
}

// struct FSummitMageSummonCritterActivationParams
// {
// 	ASummitMetalSpawner Spawner;
// }
