
class UIslandForceFieldCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandRedBlueTargetableComponent BulletTargetableComp;
	UIslandRedBlueStickyGrenadeTargetable GrenadeTargetableComp;
	UIslandRedBlueImpactResponseComponent BulletResponseComp;
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;

	UIslandForceFieldComponent ForceFieldComp;
	UHazeSkeletalMeshComponentBase CharacterMeshComp;
	UIslandForceFieldStateComponent ForceFieldStateComp;

	UIslandRedBlueReflectComponent BulletReflectComp;

	default CapabilityTags.Add(n"IslandForceField");
	
	float RedImpactTime;
	float BlueImpactTime;

	float RespawnCooldownTimer = 0.0;

	bool bHasTempShieldColor = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BulletResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
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


		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		
		if (ForceFieldComp.IsEnabled())
		{
			CharacterMeshComp = Cast<AHazeCharacter>(Owner).Mesh;
			ForceFieldComp.InitializeVisuals(CharacterMeshComp);
			ForceFieldComp.AddComponentVisualsBlocker(this);
			ForceFieldStateComp = UIslandForceFieldStateComponent::GetOrCreate(Owner);

			UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
			BulletResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
			GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
			
			BulletReflectComp = UIslandRedBlueReflectComponent::GetOrCreate(Owner);
			BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets until a shield activates.

			ForceFieldComp.SetLeaderPoseComponent(CharacterMeshComp);

			ForceFieldComp.Reset();
		}
	}

	// Broadcasted by crumb function
	UFUNCTION()
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if (Owner.IsCapabilityTagBlocked(n"IslandForceField"))
			return;

		if (!IsActive())
			return;
		
		if (ForceFieldComp.IsDepleted() || ForceFieldComp.IsDepleting())
			return;

		if(ForceFieldComp.CurrentType == EIslandForceFieldType::Both)
		{
			UIslandRedBlueWeaponUserComponent User = UIslandRedBlueWeaponUserComponent::Get(Data.GrenadeOwner);
			if(User.IsRedPlayer())
				RedImpactTime = Time::GetGameTimeSeconds();
			else
				BlueImpactTime = Time::GetGameTimeSeconds();

			// Change color to opposite User color during impact timing window. Later reset in Tick.
			float TimingWindow = ForceFieldComp.ImpactTiming + (Network::PingRoundtripSeconds * 0.5); // more generous timing window on networked
			if(Math::Abs(RedImpactTime - BlueImpactTime) > TimingWindow) // too long apart
			{
				if (RedImpactTime > BlueImpactTime) // Red was most recent
					ForceFieldComp.InitializeVisuals(CharacterMeshComp, EIslandForceFieldType::Blue); //Set shield color to blue
				else
					ForceFieldComp.InitializeVisuals(CharacterMeshComp, EIslandForceFieldType::Red); //Set shield color to red
				bHasTempShieldColor = true;
				return;
			}
		}
		
		FVector ImpactLocation; 
		Cast<AHazeCharacter>(Owner).CapsuleComponent.GetClosestPointOnCollision(Data.ExplosionOrigin, ImpactLocation);
		ForceFieldComp.TakeDamage(ForceFieldComp.DefaultGrenadeDamage, ImpactLocation, Data.GrenadeOwner);
		if (ForceFieldComp.IsDepleting())
			ForceFieldComp.TriggerBurstEffect();
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Params)
	{	
		if (Owner.IsCapabilityTagBlocked(n"IslandForceField"))
			return;

		if (!IsActive())
			return;

		if (ForceFieldComp.IsDepleting())
			return;

		if (!ForceFieldComp.bHasBulletResponse)
			return;


		ForceFieldComp.Impact(Params.ImpactLocation);

		if(ForceFieldComp.CurrentType == EIslandForceFieldType::Both)
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

		ForceFieldComp.TakeDamage(ForceFieldComp.DefaultBulletDamage * Params.ImpactDamageMultiplier, Params.ImpactLocation, Instigator = Params.Player);
		if (ForceFieldComp.IsDepleting())
			ForceFieldComp.TriggerBurstEffect();
	}

	UFUNCTION()
	private void OnRespawn()
	{		
		ForceFieldStateComp.Reset();
		ForceFieldComp.Reset();
		if (ForceFieldComp.InitialState == EIslandForceFieldState::Depleted)
			RespawnCooldownTimer = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.IsCapabilityTagBlocked(n"IslandForceField"))
			return false;
		if (!ForceFieldComp.IsEnabled())
			return false;
		if (ForceFieldComp.IsDepleted())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ForceFieldComp.IsDepleted())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		IslandForceField::ResetForceField(ForceFieldComp.CurrentType, BulletTargetableComp, BulletResponseComp, this);
		IslandForceField::ResetForceFieldStickyGrenade(ForceFieldComp.CurrentType, GrenadeTargetableComp, GrenadeResponseComp, this);
		ForceFieldStateComp.SetCurrentForceFieldType(ForceFieldComp.CurrentType);
		ForceFieldComp.RemoveComponentVisualsBlocker(this);
		BulletReflectComp.RemoveReflectBlockerForBothPlayers(Owner); // Start reflecting bullets if previously blocked.		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{		
		ForceFieldComp.AddComponentVisualsBlocker(this);
		if (BulletTargetableComp != nullptr)
		{
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(BulletTargetableComp.IsDisabledForPlayer(Player))
					BulletTargetableComp.EnableForPlayer(Player, IslandForceField::ForceFieldToggleInstigator);
			}

			// Enable targeting for both players
			BulletTargetableComp.Enable(this);
		}
		if (GrenadeTargetableComp != nullptr)
		{
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(GrenadeTargetableComp.IsDisabledForPlayer(Player))
					GrenadeTargetableComp.EnableForPlayer(Player, IslandForceField::ForceFieldToggleInstigator);
			}
		}

		
		BulletResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		BulletResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
		GrenadeResponseComp.BlockImpactForPlayer(Game::Mio, this);
		GrenadeResponseComp.BlockImpactForPlayer(Game::Zoe, this);
		BulletReflectComp.AddReflectBlockerForBothPlayers(Owner); // Stop reflecting bullets.
		ForceFieldStateComp.Reset();

		if (ForceFieldComp.bIsAutoRespawnable)
			RespawnCooldownTimer = ForceFieldComp.AutoRespawnCooldown;

		ForceFieldComp.OnDepleted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Prevent auto-aim if player hasn't unlocked grenades yet.
		if (!bHasGrenadeCapability)
		{
			auto GrenadeComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Game::Mio);
			if (GrenadeComp != nullptr && !GrenadeComp.IsGrenadeSheetActive() && BulletTargetableComp != nullptr)
				BulletTargetableComp.Disable(this);
			else
			{
				bHasGrenadeCapability = true;				
				IslandForceField::ResetForceField(ForceFieldComp.CurrentType, BulletTargetableComp, BulletResponseComp, this);
				IslandForceField::ResetForceFieldStickyGrenade(ForceFieldComp.CurrentType, GrenadeTargetableComp, GrenadeResponseComp, this);
			}
		}

		ForceFieldComp.Replenish(ForceFieldComp.ReplenishAmountPerSecond * DeltaTime);

		ForceFieldComp.UpdateVisuals(DeltaTime);

		// Change back to original color after impact timing window runs out.
		if (!bHasTempShieldColor)
			return;
		
		float TimingWindow = ForceFieldComp.ImpactTiming + (Network::PingRoundtripSeconds * 0.5); // more generous timing window on networked
		if (Time::GameTimeSeconds - Math::Max(RedImpactTime, BlueImpactTime) < TimingWindow) // if within timing window
			return;

		bHasTempShieldColor = false;
		ForceFieldComp.InitializeVisuals(CharacterMeshComp); // Resets visuals
	}

	bool bHasGrenadeCapability = false;
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{		
		if (!HasControl())
			return;

		if (!ForceFieldComp.bIsAutoRespawnable)
			return;

		if (IsActive())
			return;

		if (Owner.IsCapabilityTagBlocked(n"IslandForceField"))
			return;
		
		if (ForceFieldComp.IsDepleted())
		{
			RespawnCooldownTimer -= DeltaTime;

			if (RespawnCooldownTimer > 0.0)
				return;

			ForceFieldComp.CrumbRespawnForceField();
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		// ForceField comp
		TemporalLog.Value("ForceFieldComp;IsDepleted", ForceFieldComp.IsDepleted());
		TemporalLog.Value("ForceFieldComp;IsDepleting", ForceFieldComp.IsDepleting());
		TemporalLog.Value("ForceFieldComp;OriginalType", ForceFieldComp.Type);
		TemporalLog.Value("ForceFieldComp;CurrentType", ForceFieldComp.CurrentType);
		TemporalLog.Value("ForceFieldComp;Integrity", ForceFieldComp.GetIntegrity());
		TemporalLog.Value("ForceFieldComp;AccIntegrity", ForceFieldComp.AccIntegrity.Value);

		TemporalLog.Value("ForceFieldComp;CurrentState", ForceFieldComp.CurrentState);

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


		// Bullet targetable and response		
		bool bIsBulletTargetableDisabledForMio = BulletTargetableComp.IsDisabledForPlayer(Game::Mio);
		TemporalLog.Value("BulletTargetableComp;IsDisabledForMio", bIsBulletTargetableDisabledForMio);
		bool bIsBulletTargetableDisabledForZoe = BulletTargetableComp.IsDisabledForPlayer(Game::Zoe);
		TemporalLog.Value("BulletTargetableComp;IsDisabledForZoe", bIsBulletTargetableDisabledForZoe);
		
		bool bIsBulletResponseDisabledForMio = BulletResponseComp.IsImpactBlockedForPlayer(Game::Mio);
		TemporalLog.Value("BulletResponseComp;IsDisabledForMio", bIsBulletResponseDisabledForMio);
		bool bIsBulletResponseDisabledForZoe = BulletResponseComp.IsImpactBlockedForPlayer(Game::Zoe);
		TemporalLog.Value("BulletResponseComp;IsDisabledForZoe", bIsBulletResponseDisabledForZoe);


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