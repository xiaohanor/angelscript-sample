
class UIslandWalkerHeadForceFieldCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WalkerForceField"); 
	UIslandWalkerSettings Settings;

	UIslandRedBlueTargetableComponent TargetableComp;
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	UIslandWalkerHeadForceFieldComponent ForceFieldComp;

	float ReplenishCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeResponseComp = UIslandRedBlueStickyGrenadeResponseComponent::GetOrCreate(Owner);
		TargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		ForceFieldComp = UIslandWalkerHeadForceFieldComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(ForceFieldComp.WalkerHead); 

		ForceFieldComp.InitializeVisuals();
		ForceFieldComp.AddComponentVisualsBlocker(this);

		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
		ForceFieldComp.Reset();
	}

	UFUNCTION()
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if (IslandForceField::GetPlayerForceFieldType(Data.GrenadeOwner) != ForceFieldComp.Type)
			return;
		
		// Break immediately
		ForceFieldComp.TakeDamage(ForceFieldComp.Integrity + 1.0, Data.ExplosionOrigin);		
		ReplenishCooldown = Time::GameTimeSeconds + Settings.ForceFieldReplenishCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())
			return;
		
		if (Time::GameTimeSeconds > ReplenishCooldown)
			ForceFieldComp.Replenish(Settings.ForceFieldReplenishAmountPerSecond * DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ForceFieldComp.IsDepleted())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ForceFieldComp.HasFinishedDepleting())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ForceFieldComp.RemoveComponentVisualsBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ForceFieldComp.TriggerBurstEffect();
		ForceFieldComp.AddComponentVisualsBlocker(this);
		TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Both);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		ForceFieldComp.UpdateVisuals(DeltaTime);
	}
}