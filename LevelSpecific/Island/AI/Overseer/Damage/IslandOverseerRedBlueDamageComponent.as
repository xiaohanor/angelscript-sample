event void FIslandOverseerRedBlueDamageComponentDamageEvent(float Damage, AHazeActor Instigator);
event void FIslandOverseerRedBlueDamageComponentImpactEvent();

class UIslandOverseerRedBlueDamageComponent : UActorComponent
{
	default PrimaryComponentTick.TickInterval = 0.1;

	FIslandOverseerRedBlueDamageComponentDamageEvent OnDamage;
	FIslandOverseerRedBlueDamageComponentImpactEvent OnImpact;

	bool bMioDamage;
	bool bZoeDamage;
	float DamageDuration = 0.1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UIslandRedBlueImpactResponseComponent ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(FIslandRedBlueImpactResponseParams Data)
	{
		OnImpact.Broadcast();
		if(Data.Player == Game::Mio)
			bMioDamage = true;
		else
			bZoeDamage = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Mio(DeltaSeconds);
		Zoe(DeltaSeconds);
		bMioDamage = false;
		bZoeDamage = false;
	}

	private void Mio(float DeltaSeconds)
	{
		if(!bMioDamage)
			return;

		OnDamage.Broadcast(DeltaSeconds, Game::Mio);
	}

	private void Zoe(float DeltaSeconds)
	{
		if(!bZoeDamage)
			return;

		OnDamage.Broadcast(DeltaSeconds, Game::Zoe);
	}
}