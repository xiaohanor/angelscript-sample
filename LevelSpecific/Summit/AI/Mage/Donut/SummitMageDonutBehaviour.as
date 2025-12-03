class USummitMageDonutBehaviour : UBasicBehaviour
{
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);

	USummitMageSettings MageSettings;
	USummitMageModeComponent ModeComp;
	UGentlemanComponent GentComp;
	USummitMageDonutComponent DonutComp;
	private FName Token = n"SummitMageDonut";
	private bool bSpawned;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MageSettings = USummitMageSettings::GetSettings(Owner);
		ModeComp = USummitMageModeComponent::GetOrCreate(Owner);
		DonutComp = USummitMageDonutComponent::GetOrCreate(Owner);
		GentComp = UGentlemanComponent::GetOrCreate(Game::Zoe);
		GentComp.SetMaxAllowedClaimants(Token, int(MageSettings.DonutGentlemanBudget));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(ModeComp.Mode == ESummitMageMode::Ranged)
			return false;
		if(!GentComp.IsTokenAvailable(Token, int(MageSettings.DonutGentlemanCost)))
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > MageSettings.DonutDuration)
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentComp.ClaimToken(Token, this, int(MageSettings.DonutGentlemanCost));
		bSpawned = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(MageSettings.DonutCooldown);
		GentComp.ReleaseToken(Token, this, int(MageSettings.DonutTokenCooldown));
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bSpawned && ActiveDuration > MageSettings.DonutDuration / 2)
		{
			bSpawned = true;			
			ASummitMageDonut Donut = SpawnActor(DonutComp.DonutClass, Owner.ActorLocation + Owner.ActorUpVector * 50, bDeferredSpawn = true);
			Donut.Owner = Owner;
			FinishSpawningActor(Donut);
		}
	}
}