class UCoastBomblingProximityExplosionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UCoastBomblingSettings ExploderSettings;
	UBasicAIHealthComponent HealthComp;
	UCoastBomblingExplosionComp ExplosionComp;
	AAICoastBombling Bombling;
	float FlashTimer;
	float ExplosionTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ExploderSettings = UCoastBomblingSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ExplosionComp = UCoastBomblingExplosionComp::Get(Owner);
		Bombling = Cast<AAICoastBombling>(Owner);
	}

	private bool WithinWarningDistance() const
	{
		if(Owner.ActorLocation.Distance(Game::Mio.ActorLocation) < ExploderSettings.ProximityExplosionDistance * 3)
			return true;
		if(Owner.ActorLocation.Distance(Game::Zoe.ActorLocation) < ExploderSettings.ProximityExplosionDistance * 3)
			return true;
		return false;
	}

	private bool WithinDistance() const
	{
		if(Owner.ActorLocation.Distance(Game::Mio.ActorLocation) < ExploderSettings.ProximityExplosionDistance)
			return true;
		if(Owner.ActorLocation.Distance(Game::Zoe.ActorLocation) < ExploderSettings.ProximityExplosionDistance)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(HealthComp.IsDead())
			return false;
		if(!WithinWarningDistance())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		if(HealthComp.IsDead())
			return true;
		if(!WithinWarningDistance())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ExplosionTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Bombling.BallMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", FLinearColor(100, 0, 0));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WithinDistance() && ExplosionTime == 0)
			ExplosionTime = Time::GameTimeSeconds;

		if(ExplosionTime == 0)
			FlashTimer += DeltaTime * 100;
		else
			FlashTimer += DeltaTime * 200;

		float Color = 100 - Math::Abs(Math::Sin(FlashTimer)) * 100;
		Bombling.BallMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", FLinearColor(Color, 0, 0));

		if(ExplosionTime != 0 && Time::GetGameTimeSince(ExplosionTime) > 0.5)
			HealthComp.Die();
	}
}