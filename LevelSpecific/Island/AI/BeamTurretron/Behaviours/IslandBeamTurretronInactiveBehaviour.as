
class UIslandBeamTurretronInactiveBehaviour : UBasicBehaviour
{
	UIslandRedBlueImpactResponseComponent ResponseComp;
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	UBasicAIHealthComponent HealthComp;
	UHazeActorRespawnableComponent RespawnComp;
	UIslandBeamTurretronInactiveComponent InactiveComp;
	UIslandBeamTurretronSettings Settings;

		
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandBeamTurretronSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::Get(Owner);
		GrenadeResponseComp = UIslandRedBlueStickyGrenadeResponseComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		InactiveComp = UIslandBeamTurretronInactiveComponent::GetOrCreate(Owner);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
	}

	UFUNCTION()
	private void OnReset()
	{
		InactiveComp.SetOwnerInactive();
	}

	UFUNCTION()
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{		
		InactiveComp.SetOwnerActive();
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		InactiveComp.SetOwnerActive();
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{
		InactiveComp.SetOwnerActive();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (InactiveComp.bIsOwnerActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (InactiveComp.bIsOwnerActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		// Set cannon rotation downward
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: run activation animation before deactivating		
	}
}

class UIslandBeamTurretronInactiveComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsOwnerActive;

	UFUNCTION()
	void SetOwnerActive()
	{
		bIsOwnerActive = true;
	}

	UFUNCTION()
	void SetOwnerInactive()
	{
		bIsOwnerActive = false;
	}

	UFUNCTION(DevFunction)
	void Dev_ToggleOwnerActive()
	{
		bIsOwnerActive = !bIsOwnerActive;
	}

}
