
class UIslandOverseerForceFieldCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandRedBlueStickyGrenadeTargetable TargetableComp;
	UIslandRedBlueImpactResponseComponent BulletResponseComp;
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	UIslandOverseerForceFieldComponent ForceFieldComp;
	UIslandForceFieldStateComponent ForceFieldStateComp;
	UIslandRedBlueReflectComponent BulletReflectComp;

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default CapabilityTags.Add(n"IslandForceField");
	
	float RedImpactTime;
	float BlueImpactTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeResponseComp = UIslandRedBlueStickyGrenadeResponseComponent::GetOrCreate(Owner);

		TargetableComp = UIslandRedBlueStickyGrenadeTargetable::Get(Owner);
		ForceFieldComp = UIslandOverseerForceFieldComponent::Get(Owner);
		
		ForceFieldComp.ReconstructForceFields();
		ForceFieldComp.Hide();
		GrenadeResponseComp.AttachToComponent(ForceFieldComp);

		ForceFieldStateComp = UIslandForceFieldStateComponent::GetOrCreate(Owner);

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if(RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
				
		if(ForceFieldComp.bTryGetImpactResponseFromChildren)
		{
			TArray<UIslandRedBlueImpactResponseComponent> ImpactComponents;
			ForceFieldComp.GetChildrenComponentsByClass(UIslandRedBlueImpactResponseComponent, true, ImpactComponents);
			if(ImpactComponents.Num() > 0)
				BulletResponseComp = ImpactComponents[0];
		}
		
		if(!ForceFieldComp.bTryGetImpactResponseFromChildren || BulletResponseComp == nullptr)
			BulletResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		BulletResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		
		BulletReflectComp = UIslandRedBlueReflectComponent::GetOrCreate(Owner);
		BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets until a shield activates.

		ForceFieldComp.OnShieldBurstEffect.AddUFunction(this, n"OnForceFieldBubbleBurst");
		ForceFieldComp.OnShieldReset.AddUFunction(this, n"OnForceFieldBubbleReset");
		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
	}

	UFUNCTION()
	private void OnForceFieldBubbleReset()
	{
		IslandForceField::ResetForceField(ForceFieldComp.GetCurrentForceFieldType(), TargetableComp, BulletResponseComp, this);
		IslandForceField::ResetForceFieldStickyGrenade(ForceFieldComp.GetCurrentForceFieldType(), TargetableComp, GrenadeResponseComp, this);
		ForceFieldStateComp.SetCurrentForceFieldType(ForceFieldComp.GetCurrentForceFieldType());
	}

	UFUNCTION()
	private void OnForceFieldBubbleBurst(EIslandForceFieldEffectType EffectType)
	{
		ForceFieldComp.TriggerBurstEffect(EffectType);
		// Update response components
		IslandForceField::ResetForceField(ForceFieldComp.GetCurrentForceFieldType(), TargetableComp, BulletResponseComp, this);
		IslandForceField::ResetForceFieldStickyGrenade(ForceFieldComp.GetCurrentForceFieldType(), TargetableComp, GrenadeResponseComp, this);
		ForceFieldStateComp.SetCurrentForceFieldType(ForceFieldComp.GetCurrentForceFieldType());
	}


	UFUNCTION()
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if (!IsActive())
			return;

		if(ForceFieldComp.GetCurrentForceFieldType() == EIslandForceFieldType::Both)
		{
			UIslandRedBlueWeaponUserComponent User = UIslandRedBlueWeaponUserComponent::Get(Data.GrenadeOwner);
			if(User.IsRedPlayer())
				RedImpactTime = Time::GetGameTimeSeconds();
			else
				BlueImpactTime = Time::GetGameTimeSeconds();

			if(RedImpactTime == 0)
				return;
			if(BlueImpactTime == 0)
				return;

			if(Math::Abs(RedImpactTime - BlueImpactTime) > ForceFieldComp.ImpactTiming + (Network::PingRoundtripSeconds * 0.5) ) // more generous timing window on networked
				return;
		}

		FVector ImpactLocation = ForceFieldComp.GetExplosionImpactLocation(Data.ExplosionOrigin);
		ForceFieldComp.TakeDamage(ForceFieldComp.DefaultGrenadeDamage, ImpactLocation);
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{	
		if (!IsActive())
			return;
		
		if (!ForceFieldComp.bHasBulletResponse)
			return;

		ForceFieldComp.Impact(Params.ImpactLocation);

		if(ForceFieldComp.GetCurrentForceFieldType() == EIslandForceFieldType::Both)
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

			if(Math::Abs(RedImpactTime - BlueImpactTime) > ForceFieldComp.ImpactTiming + (Network::PingRoundtripSeconds * 0.5) ) // more generous timing window on networked
				return;
		}

		ForceFieldComp.TakeDamage(ForceFieldComp.DefaultBulletDamage, Params.ImpactLocation);		
	}

	UFUNCTION()
	private void OnRespawn()
	{
		ForceFieldComp.ReconstructForceFields();
		if (ForceFieldComp.ForceFields.Num() > 0)
		{
			ForceFieldStateComp.Reset();
		}
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
		if (ForceFieldComp.HasFinishedDepleting() && !ForceFieldComp.bLayerHasBurst)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"IslandForceField", this);
		ForceFieldComp.Show();
		IslandForceField::ResetForceField(ForceFieldComp.GetCurrentForceFieldType(), TargetableComp, BulletResponseComp, this);
		IslandForceField::ResetForceFieldStickyGrenade(ForceFieldComp.GetCurrentForceFieldType(), TargetableComp, GrenadeResponseComp, this);
		BulletReflectComp.RemoveReflectBlockerForBothPlayers(Owner); // Start reflecting bullets if previously blocked.
		ForceFieldStateComp.SetCurrentForceFieldType(ForceFieldComp.GetCurrentForceFieldType());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"IslandForceField", this);		
		ForceFieldComp.Hide();
		if (TargetableComp != nullptr)
			TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Both);
		
		BulletResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		BulletResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
		GrenadeResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		GrenadeResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
		BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets.
		ForceFieldStateComp.SetCurrentForceFieldType(EIslandForceFieldType::MAX);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ForceFieldComp.Replenish(ForceFieldComp.ReplenishAmountPerSecond * DeltaTime);

		ForceFieldComp.Update(DeltaTime);
	}	
}