struct FGravityBikeFreeDamagedDeactivateParams
{
	bool bDied = false;
	bool bFullyHealed = false;
}

class UGravityBikeFreeDamagedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AGravityBikeFree GravityBike;
	UPlayerHealthComponent DriverHealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GravityBike.HasExploded())
			return false;

		auto HealthComp = UPlayerHealthComponent::Get(GravityBike.GetDriver());
		if(HealthComp.Health.HasFullHealth())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeFreeDamagedDeactivateParams& Params) const
	{
		if(GravityBike.HasExploded())
		{
			Params.bDied = true;
			return true;
		}

		if(!DriverHealthComp.Health.IsDamaged())
		{
			Params.bFullyHealed = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DriverHealthComp = UPlayerHealthComponent::Get(GravityBike.GetDriver());

		FGravityBikeFreeInitialDamageEventData EventData;
		EventData.DamageFraction = DriverHealthComp.Health.CurrentHealth;
		UGravityBikeFreeEventHandler::Trigger_OnInitialDamage(GravityBike, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeFreeDamagedDeactivateParams Params)
	{
		if(Params.bDied || Params.bFullyHealed)
			UGravityBikeFreeEventHandler::Trigger_OnFullyHealed(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FGravityBikeFreeUpdateDamageEventData EventData;
		EventData.DamageFraction = DriverHealthComp.Health.CurrentHealth;
		UGravityBikeFreeEventHandler::Trigger_OnUpdateDamage(GravityBike, EventData);
	}
};