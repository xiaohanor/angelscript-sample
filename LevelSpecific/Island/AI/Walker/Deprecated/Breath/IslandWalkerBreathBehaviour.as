
class UIslandWalkerBreathBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UIslandWalkerSettings WalkerSettings;
	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerBreathComponent BreathComp;
	float SpawnRingDelay = 2;
	bool bSpawnedRing;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerSettings = UIslandWalkerSettings::GetSettings(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		BreathComp = UIslandWalkerBreathComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(LegsComp.NumDestroyedLegs() < 3)
			return false;

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		if(ActiveDuration > 10)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FVector Dir = Owner.ActorForwardVector.RotateAngleAxis(45, Owner.ActorRightVector);
		BreathComp.StartBreath(Dir);
		bSpawnedRing = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(WalkerSettings.BreathCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bSpawnedRing && ActiveDuration > SpawnRingDelay)
		{
			bSpawnedRing = true;
			BreathComp.SpawnRing();
			BreathComp.StopBreath();
		}
	}
}