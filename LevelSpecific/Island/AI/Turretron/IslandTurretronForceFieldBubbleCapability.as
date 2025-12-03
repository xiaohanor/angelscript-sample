
class UIslandTurretronForceFieldBubbleCapability : UHazeCapability
{
	UIslandTurretronSettings Settings;

	UIslandRedBlueTargetableComponent TargetableComp;
	UIslandRedBlueImpactResponseComponent ResponseComp;
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	UHazeSkeletalMeshComponentBase CharacterMeshComp;

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default CapabilityTags.Add(n"IslandForceField");

	float ImpactTiming = 0.25;
	float RedImpactTime;
	float BlueImpactTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UIslandTurretronSettings::GetSettings(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		
		TargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::Get(Owner);
		
		CharacterMeshComp = Cast<AHazeCharacter>(Owner).Mesh;		
		ForceFieldBubbleComp.ReconstructForceFields();
		ForceFieldBubbleComp.AddVisualsBlockers(this);

		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		ForceFieldBubbleComp.OnShieldBurstEffect.AddUFunction(this, n"OnForceFieldBubbleBurst");		
	}

	UFUNCTION()
	private void OnForceFieldBubbleBurst(EIslandForceFieldEffectType EffectType)
	{
		ForceFieldBubbleComp.TriggerBurstEffect(EffectType);
		// Update response component
		IslandForceField::ResetForceField(ForceFieldBubbleComp.GetCurrentForceFieldType(), TargetableComp, ResponseComp, this);
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{	
		if (!IsActive())
			return;

		if(ForceFieldBubbleComp.GetCurrentForceFieldType() == EIslandForceFieldType::Both)
		{
			UIslandRedBlueWeaponUserComponent User = UIslandRedBlueWeaponUserComponent::Get(Params.Player);
			if(User.IsRedPlayer())
				RedImpactTime = Time::GetGameTimeSeconds();
			else
				BlueImpactTime = Time::GetGameTimeSeconds();

			if(RedImpactTime == 0)
				return;
			if(BlueImpactTime == 0)
				return;

			if(Math::Abs(RedImpactTime - BlueImpactTime) > ImpactTiming + (Network::PingRoundtripSeconds * 0.5) ) // more generous timing window on networked
				return;
		}

		// Note: We assume this is networked
		ForceFieldBubbleComp.TakeDamage(Settings.ForceFieldDefaultDamage * Params.ImpactDamageMultiplier, Params.ImpactLocation);		
	}

	UFUNCTION()
	private void OnRespawn()
	{
		ForceFieldBubbleComp.ReconstructForceFields();
		if (ForceFieldBubbleComp.ForceFields.Num() > 0)
			IslandForceField::ResetForceField(ForceFieldBubbleComp.GetCurrentForceFieldType(), TargetableComp, ResponseComp, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ForceFieldBubbleComp.IsDepleted())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ForceFieldBubbleComp.HasFinishedDepleting())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"IslandForceField", this);
		ForceFieldBubbleComp.RemoveVisualsBlockers(this);
		IslandForceField::ResetForceField(ForceFieldBubbleComp.GetCurrentForceFieldType(), TargetableComp, ResponseComp, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"IslandForceField", this);		
		ForceFieldBubbleComp.AddVisualsBlockers(this);
		if (TargetableComp != nullptr)
			TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Both);
		
		ResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		ResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ForceFieldBubbleComp.Replenish(Settings.ReplenishAmountPerSecond * DeltaTime);

		ForceFieldBubbleComp.Update(DeltaTime);
	}
}