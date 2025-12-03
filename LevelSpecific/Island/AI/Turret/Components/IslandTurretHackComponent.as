event void FIslandTurretHackHackedResponseSignature();
event void FIslandTurretHackSecuredResponseSignature();

class UIslandTurretHackComponent : UActorComponent
{
	AHazeActor HazeOwner;
	UScifiShieldBusterField ShieldComp;
	UBasicAITargetingComponent TargetComp;

	bool bEnabled;
	bool bHacked;

	FIslandTurretHackHackedResponseSignature OnHacked;
	FIslandTurretHackSecuredResponseSignature OnSecured;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShieldComp = UScifiShieldBusterField::Get(Owner);
		TargetComp = UBasicAITargetingComponent::Get(Owner);

		auto CopsGunsResponse = UScifiCopsGunImpactResponseComponent::Get(Owner);
		if(CopsGunsResponse != nullptr)
		{
			CopsGunsResponse.OnWeaponImpact.AddUFunction(this, n"OnWeaponImpact");
		}

		HazeOwner = Cast<AHazeActor>(Owner);
	}

	UFUNCTION()
	private void OnWeaponImpact(AHazePlayerCharacter ImpactInstigator)
	{
		if(ShieldComp.IsEnabled() && !ShieldComp.IsBroken())
			return;
		Hack();
	}

	bool CanHack()
	{
		return !bHacked && bEnabled;
	}

	bool IsHacked()
	{
		return bHacked;
	}

	void Hack()
	{
		bHacked = true;
		TargetComp.SetTarget(nullptr);
		OnHacked.Broadcast();
	}

	void Secure()
	{
		bHacked = false;
		TargetComp.SetTarget(nullptr);
		OnSecured.Broadcast();
	}
}