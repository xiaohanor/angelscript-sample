class UCoastWaterJetGrenadeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UCoastWaterJetSettings Settings;
	UCoastWaterJetGrenadeWeaponComponent GrenadeWeapon;

	bool bFired;
	float ActivationDelay = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastWaterJetSettings::GetSettings(Owner);
		GrenadeWeapon = UCoastWaterJetGrenadeWeaponComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsBlocked())
			return;
		if(ActivationDelay > 0)
			ActivationDelay -= DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(ActivationDelay > 0)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		UCoastWaterJetEffectHandler::Trigger_OnTelegraph(Owner, FCoastWaterJetOnTelegraphEffectData(GrenadeWeapon));
		bFired = false;

		bFired = true;
		auto Grenade = SpawnActor(GrenadeWeapon.GrenadeClass, GrenadeWeapon.WorldLocation, bDeferredSpawn = true);
		Grenade.TargetLocation = TargetComp.Target.ActorLocation + TargetComp.Target.ActorForwardVector * 4500;
		FinishSpawningActor(Grenade);
		Grenade.SetActorLocation(GrenadeWeapon.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TargetComp.SetTarget(Player.OtherPlayer);
		Cooldown.Set(1.5);
	}
}
