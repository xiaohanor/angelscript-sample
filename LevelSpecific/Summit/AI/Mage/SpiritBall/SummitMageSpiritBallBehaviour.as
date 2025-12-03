class USummitMageSpiritBallBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AAISummitMage SummitMage;
	USummitMageSettings MageSettings;

	UGentlemanComponent GentComp;
	UBasicAIHealthComponent HealthComp;
	USummitMageSpiritBallLauncherComponent LauncherComp;
	USummitMageModeComponent ModeComp;

	float AttackDuration = 0.3;
	AHazeActor TargetPlate;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SummitMage = Cast<AAISummitMage>(Owner);
		ModeComp = USummitMageModeComponent::GetOrCreate(Owner);
		MageSettings = USummitMageSettings::GetSettings(Owner);
		LauncherComp = USummitMageSpiritBallLauncherComponent::GetOrCreate(Owner);
		GentComp = UGentlemanComponent::GetOrCreate(Game::Zoe);
		GentComp.SetMaxAllowedClaimants(SummitMageTags::SpiritBallToken, int(MageSettings.SpiritBallGentlemanCost));
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
		if(ModeComp.Mode == ESummitMageMode::Melee)
			return false;
		UHazeTeam Team = HazeTeam::GetTeam(n"SummitActiveSpiritBall");
		if(Team != nullptr && Team.GetMembers().Num() >= MageSettings.SpiritBallMax)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		if(!GentComp.IsTokenAvailable(SummitMageTags::SpiritBallToken, int(MageSettings.SpiritBallGentlemanCost)))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > AttackDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentComp.ClaimToken(SummitMageTags::SpiritBallToken, this, int(MageSettings.SpiritBallGentlemanCost));

		TargetPlate = GetTargetPlate();
		if(TargetPlate == nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
			if(Player == nullptr)
				TargetLocation = TargetComp.Target.ActorLocation;
			else
				TargetLocation = Player.OtherPlayer.ActorLocation;
		}
		else
			TargetLocation = TargetPlate.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		SpawnMageSpiritBall();
		Cooldown.Set(MageSettings.SpiritBallCooldown);
		GentComp.ReleaseToken(SummitMageTags::SpiritBallToken, this, MageSettings.SpiritBallTokenCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
	}

	void SpawnMageSpiritBall()
	{
		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(LauncherComp.WorldLocation, TargetLocation, MageSettings.AttackProjectileGravity, MageSettings.AttackProjectileSpeed);
		UBasicAIProjectileComponent Projectile = LauncherComp.Launch(Velocity, LauncherComp.WorldRotation);
		Projectile.Gravity = MageSettings.AttackProjectileGravity;
		for(auto Member:  HazeTeam::GetTeam(AITeams::Default).GetMembers())
			Projectile.AdditionalIgnoreActors.Add(Member);	
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