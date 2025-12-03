
class UIslandForceFieldBubbleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandRedBlueTargetableComponent BulletTargetableComp;
	UIslandRedBlueStickyGrenadeTargetable GrenadeTargetableComp;
	UIslandRedBlueImpactResponseComponent BulletResponseComp;
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	UIslandForceFieldStateComponent ForceFieldStateComp;
	UIslandRedBlueReflectComponent BulletReflectComp;

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default CapabilityTags.Add(n"IslandForceField");
	default CapabilityTags.Add(n"IslandForceFieldBubble");
	
	float RedImpactTime;
	float BlueImpactTime;

	bool bHasTempShieldColor = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeResponseComp = UIslandRedBlueStickyGrenadeResponseComponent::GetOrCreate(Owner);

		BulletTargetableComp = UIslandRedBlueTargetableComponent::Get(Owner);
		GrenadeTargetableComp = UIslandRedBlueStickyGrenadeTargetable::Get(Owner);		
		if (BulletTargetableComp != nullptr && GrenadeTargetableComp == nullptr)
		{
			// Copy settings from bullets' TargetableComp if GrenadeTargetableComp does not exist.
			GrenadeTargetableComp = UIslandRedBlueStickyGrenadeTargetable::Create(Owner);
			GrenadeTargetableComp.AttachToComponent(BulletTargetableComp.AttachParent);
			GrenadeTargetableComp.RelativeLocation = BulletTargetableComp.RelativeLocation;
			GrenadeTargetableComp.TargetShape = BulletTargetableComp.TargetShape;
			GrenadeTargetableComp.OptionalShape = BulletTargetableComp.OptionalShape;
			GrenadeTargetableComp.AutoAimMaxAngle = BulletTargetableComp.AutoAimMaxAngle;
			GrenadeTargetableComp.AutoAimMaxAngleMinDistance = BulletTargetableComp.AutoAimMaxAngleMinDistance;
			GrenadeTargetableComp.bUseVariableAutoAimMaxAngle = BulletTargetableComp.bUseVariableAutoAimMaxAngle;			
		}
		ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::Get(Owner);
		
		ForceFieldBubbleComp.ReconstructForceFields();
		ForceFieldBubbleComp.AddVisualsBlockers(this);
		ForceFieldBubbleComp.AddCollisionBlockers(this);
		if(ForceFieldBubbleComp.bAttachToParentComponent)
			GrenadeResponseComp.AttachToComponent(ForceFieldBubbleComp);

		ForceFieldStateComp = UIslandForceFieldStateComponent::GetOrCreate(Owner);

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if(RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
				
		if(ForceFieldBubbleComp.bTryGetImpactResponseFromChildren)
		{
			TArray<UIslandRedBlueImpactResponseComponent> ImpactComponents;
			ForceFieldBubbleComp.GetChildrenComponentsByClass(UIslandRedBlueImpactResponseComponent, true, ImpactComponents);
			if(ImpactComponents.Num() > 0)
				BulletResponseComp = ImpactComponents[0];
		}
		
		if(!ForceFieldBubbleComp.bTryGetImpactResponseFromChildren || BulletResponseComp == nullptr)
			BulletResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);

		BulletReflectComp = UIslandRedBlueReflectComponent::GetOrCreate(Owner);
		BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets until a shield activates.

		ForceFieldBubbleComp.OnShieldBurstEffect.AddUFunction(this, n"OnForceFieldBubbleBurst");
		ForceFieldBubbleComp.OnShieldReset.AddUFunction(this, n"OnForceFieldBubbleReset");
		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
	}

	UFUNCTION()
	private void OnForceFieldBubbleReset()
	{
		IslandForceField::ResetForceField(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, BulletResponseComp, this);
		IslandForceField::ResetForceFieldStickyGrenade(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, GrenadeResponseComp, this);
		ForceFieldStateComp.SetCurrentForceFieldType(ForceFieldBubbleComp.GetCurrentForceFieldType());
	}

	UFUNCTION()
	private void OnForceFieldBubbleBurst(EIslandForceFieldEffectType EffectType)
	{
		ForceFieldBubbleComp.TriggerBurstEffect(EffectType);
		// Update response components
		IslandForceField::ResetForceField(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, BulletResponseComp, this);
		IslandForceField::ResetForceFieldStickyGrenade(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, GrenadeResponseComp, this);
		ForceFieldStateComp.SetCurrentForceFieldType(ForceFieldBubbleComp.GetCurrentForceFieldType());
	}


	UFUNCTION()
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if (!IsActive())
			return;

		if (ForceFieldBubbleComp.IsDepleted())
			return;

		if(ForceFieldBubbleComp.GetCurrentForceFieldType() == EIslandForceFieldType::Both)
		{
			UIslandRedBlueWeaponUserComponent User = UIslandRedBlueWeaponUserComponent::Get(Data.GrenadeOwner);
			if(User.IsRedPlayer())
				RedImpactTime = Time::GetGameTimeSeconds();
			else
				BlueImpactTime = Time::GetGameTimeSeconds();
			
			// Change color to opposite User color during impact timing window. Later reset in Tick.
			float TimingWindow = ForceFieldBubbleComp.ImpactTiming + (Network::PingRoundtripSeconds * 0.5); // more generous timing window on networked
			if(Math::Abs(RedImpactTime - BlueImpactTime) > TimingWindow) // too long apart
			{
				if (RedImpactTime > BlueImpactTime) // Red was most recent
				 	ForceFieldBubbleComp.OverrideVisuals(EIslandForceFieldType::Blue); //Set shield color to blue
				else
				 	ForceFieldBubbleComp.OverrideVisuals(EIslandForceFieldType::Red); //Set shield color to red
				bHasTempShieldColor = true;
				return;
			}
		}

		FVector ImpactLocation = ForceFieldBubbleComp.GetExplosionImpactLocation(Data.ExplosionOrigin);
		ForceFieldBubbleComp.TakeDamage(ForceFieldBubbleComp.DefaultGrenadeDamage, ImpactLocation);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Crumbed by respawn comp
		ForceFieldBubbleComp.Reset();
		if (ForceFieldBubbleComp.ForceFields.Num() > 0)
		{
			ForceFieldStateComp.Reset();
		}
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
		if (ForceFieldBubbleComp.HasFinishedDepleting() && !ForceFieldBubbleComp.bLayerHasBurst)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"IslandForceField", this);
		ForceFieldBubbleComp.RemoveVisualsBlockers(this);
		ForceFieldBubbleComp.RemoveCollisionBlockers(this);
		IslandForceField::ResetForceField(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, BulletResponseComp, this);
		IslandForceField::ResetForceFieldStickyGrenade(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, GrenadeResponseComp, this);
		BulletReflectComp.RemoveReflectBlockerForBothPlayers(Owner); // Start reflecting bullets if previously blocked.
		ForceFieldStateComp.SetCurrentForceFieldType(ForceFieldBubbleComp.GetCurrentForceFieldType());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"IslandForceField", this);		
		ForceFieldBubbleComp.AddVisualsBlockers(this);
		ForceFieldBubbleComp.AddCollisionBlockers(this);

		if (BulletTargetableComp != nullptr)
		{
			// Need to enable for both instigators.
			for(auto Player : Game::Players)
			{
				if(BulletTargetableComp.IsDisabledForPlayer(Player))
					BulletTargetableComp.EnableForPlayer(Player, IslandForceField::ForceFieldToggleInstigator);
			}
			BulletTargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Both);
			BulletTargetableComp.Enable(this);
		}
		
		BulletResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		BulletResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
		GrenadeResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		GrenadeResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
		BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets.
		ForceFieldStateComp.SetCurrentForceFieldType(EIslandForceFieldType::MAX);
	}

	bool bHasGrenadeCapability = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Prevent auto-aim if player hasn't unlocked grenades yet.
		if (!bHasGrenadeCapability && BulletTargetableComp != nullptr)
		{
			auto GrenadeComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Game::Mio);
			if (GrenadeComp != nullptr && !GrenadeComp.IsGrenadeSheetActive() && BulletTargetableComp != nullptr)
				BulletTargetableComp.Disable(this);
			else
			{
				bHasGrenadeCapability = true;				
				IslandForceField::ResetForceField(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, BulletResponseComp, this);
				IslandForceField::ResetForceFieldStickyGrenade(ForceFieldBubbleComp.GetCurrentForceFieldType(), BulletTargetableComp, GrenadeResponseComp, this);
			}
		}

		ForceFieldBubbleComp.Replenish(ForceFieldBubbleComp.ReplenishAmountPerSecond * DeltaTime);

		ForceFieldBubbleComp.Update(DeltaTime);

		// Change back to original color after impact timing window runs out.
		if (!bHasTempShieldColor)
			return;
		
		float TimingWindow = ForceFieldBubbleComp.ImpactTiming + (Network::PingRoundtripSeconds * 0.5); // more generous timing window on networked
		if (Time::GameTimeSeconds - Math::Max(RedImpactTime, BlueImpactTime) < TimingWindow) // if within timing window
			return;

		bHasTempShieldColor = false;
		ForceFieldBubbleComp.ClearOverrideVisuals();
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		if (ForceFieldBubbleComp.ForceFields.IsEmpty())
		{
			TemporalLog.Status("Has no forcefield.", FLinearColor::Red);
			return;
		}

		// ForceField comp
		TemporalLog.Value("ForceFieldComp;IsDepleted", ForceFieldBubbleComp.IsDepleted());
		TemporalLog.Value("ForceFieldComp;HasFinishedDepleting", ForceFieldBubbleComp.HasFinishedDepleting());
		TemporalLog.Value("ForceFieldComp;CurrentType", ForceFieldBubbleComp.GetCurrentForceFieldType());
		TemporalLog.Value("ForceFieldComp;Integrity", ForceFieldBubbleComp.GetIntegrity());
		FIslandForceFieldBubble Bubble = ForceFieldBubbleComp.GetCurrentForceFieldBubble();		
		TemporalLog.Value("ForceFieldComp;AccIntegrity", Bubble.AccIntegrity.Value);

		// ForceFieldStateComp - Is used by player capabilities.
		if (ForceFieldStateComp != nullptr)
		{
			TemporalLog.Value("ForceFieldStateComp;CurrentForceFieldType", ForceFieldStateComp.CurrentForceFieldType);
		}

		// Bullet reflect comp
		if (BulletReflectComp != nullptr)
		{
			bool bIsReflectingMio = !BulletReflectComp.IsReflectBlockedFor(Game::Mio); // Having a block means no reflection.
			TemporalLog.Value("BulletReflectComp;IsReflectingBulletsForMio", bIsReflectingMio);
			bool bIsReflectingZoe = !BulletReflectComp.IsReflectBlockedFor(Game::Mio); // Having a block means no reflection.
			TemporalLog.Value("BulletReflectComp;IsReflectingBulletsForZoe", bIsReflectingZoe);
		}

		if (BulletTargetableComp != nullptr)
		{
			// Bullet targetable and response
			bool bIsBulletTargetableDisabledForMio = BulletTargetableComp.IsDisabledForPlayer(Game::Mio);
			TemporalLog.Value("BulletTargetableComp;IsDisabledForMio", bIsBulletTargetableDisabledForMio);
			bool bIsBulletTargetableDisabledForZoe = BulletTargetableComp.IsDisabledForPlayer(Game::Zoe);
			TemporalLog.Value("BulletTargetableComp;IsDisabledForZoe", bIsBulletTargetableDisabledForZoe);
			
			bool bIsBulletResponseDisabledForMio = BulletResponseComp.IsImpactBlockedForPlayer(Game::Mio);
			TemporalLog.Value("BulletResponseComp;IsDisabledForMio", bIsBulletResponseDisabledForMio);
			bool bIsBulletResponseDisabledForZoe = BulletResponseComp.IsImpactBlockedForPlayer(Game::Zoe);
			TemporalLog.Value("BulletResponseComp;IsDisabledForZoe", bIsBulletResponseDisabledForZoe);
		}

		if (GrenadeTargetableComp != nullptr)
		{
			// Grenade targetable and response
			bool bIsGrenadeTargetableDisabledForMio = GrenadeTargetableComp.IsDisabledForPlayer(Game::Mio);
			TemporalLog.Value("GrenadeTargetableComp;IsDisabledForMio", bIsGrenadeTargetableDisabledForMio);
			bool bIsGrenadeTargetableDisabledForZoe = GrenadeTargetableComp.IsDisabledForPlayer(Game::Zoe);
			TemporalLog.Value("GrenadeTargetableComp;IsDisabledForZoe", bIsGrenadeTargetableDisabledForZoe);
		
			bool bIsGrenadeResponseDisabledForMio = GrenadeResponseComp.IsImpactBlockedForPlayer(Game::Mio);
			TemporalLog.Value("GrenadeResponseComp;IsDisabledForMio", bIsGrenadeResponseDisabledForMio);
			bool bIsGrenadeResponseDisabledForZoe = GrenadeResponseComp.IsImpactBlockedForPlayer(Game::Zoe);
			TemporalLog.Value("GrenadeResponseComp;IsDisabledForZoe", bIsGrenadeResponseDisabledForZoe);		
		}
	}
}