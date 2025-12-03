class USummitStoneBeastZapperBeamAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);

	AAISummitStoneBeastZapper Zapper;
	USummitStoneBeastZapperSettings Settings;

	private bool bHasStartedBeamAttack = false;
	private bool bIsStoppingBeamAttack = false;

	private FHazeAcceleratedFloat AcceleratedIntensity;

	private ASummitStoneBeastZapperLightningCrystalActor LightningCrystals;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitStoneBeastZapperBeamComponent BeamComp;
	UDragonSwordCombatResponseComponent SwordResponseComp;

	// Alternatively, you can make a Dynamic Material instance from the mesh and set parameters on it.
	UMaterialInstanceDynamic MaterialInstanceDynamic;
	FLinearColor StartColor;

	private int NumSpawned = 0;
	private float TimeToNextSpawn = 0.0;
	
	private float CurrentBeamDist = 0.0;
	private float CurrentDecalScale = 0.0;
	private FVector OriginalDecalScale;
	private FVector DecalOffsetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Zapper = Cast<AAISummitStoneBeastZapper>(Owner);
		Settings = USummitStoneBeastZapperSettings::GetSettings(Owner);		
		auto Respawn = UHazeActorRespawnableComponent::GetOrCreate(Zapper);
		Respawn.OnRespawn.AddUFunction(this, n"OnReset");
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		BeamComp = USummitStoneBeastZapperBeamComponent::GetOrCreate(Owner);
		SwordResponseComp = UDragonSwordCombatResponseComponent::Get(Owner);
		SwordResponseComp.OnHit.AddUFunction(this, n"OnSwordHit");

		int MaterialIndex = 0;
		MaterialInstanceDynamic = Zapper.Mesh.CreateDynamicMaterialInstance(MaterialIndex);
		StartColor = MaterialInstanceDynamic.GetVectorParameterValue(n"Tint");
		OriginalDecalScale = Zapper.BeamAttackDecalComp.WorldScale;
	}

	UFUNCTION()
	private void OnSwordHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		// If one wish to only register hits while shield is down, use this:
		//if (!Zapper.VFXShieldTemp.IsHiddenInGame())
		//	return;
		
		// Cut in line (assumes Owner is already in the queue)
		if (!GentCostQueueComp.IsNext(this))
			GentCostQueueComp.MoveToNextInQueue(this);
	}

	UFUNCTION()
	private void OnReset()
	{
		Zapper.TelegraphChargeSpotLight.SetIntensity(1);
		AcceleratedIntensity.SnapTo(1.0);
		Zapper.BeamAttackDecalComp.SetHiddenInGame(true);
		USummitStoneBeastZapperEffectHandler::Trigger_OnStopTelegraphing(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (ActiveDuration > Settings.BeamAttackTelegraphDuration + (Settings.BeamAttackFlashEffectSpawnNum * Settings.BeamAttackFlashEffectSpawnRate) + Settings.BeamAttackRecovery)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bHasStartedBeamAttack = false;
		NumSpawned = 0;
		TimeToNextSpawn = 0.0;
		CurrentBeamDist = 0.0;
		CurrentDecalScale = 0.0;
		DecalOffsetLocation = FVector::ZeroVector;
		bIsStoppingBeamAttack = false;
		Zapper.VFXShieldTemp.SetHiddenInGame(false);

		Zapper.BeamAttackDecalComp.SetWorldScale3D(OriginalDecalScale);
		
		MaterialInstanceDynamic.SetVectorParameterValue(n"Tint", FLinearColor(1, 1, 1.5));
		
		// Charging crystal
		Zapper.TelegraphChargeSpotLight.SetVisibility(true);
		Zapper.TelegraphChargeSpotLight.SetIntensity(1);
		USummitStoneBeastZapperEffectHandler::Trigger_OnStartTelegraphing(Owner, FSummitStoneBeastZapperStartTelegraphingParams(Zapper.TelegraphChargeVFXLocation));

		AnimComp.RequestFeature(FeatureTagCrystalCrawler::Locomotion, SummitCrystalCrawlerSubTags::AttackEnter, EBasicBehaviourPriority::Minimum, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown, Settings.AttackTokenPersonalCooldown);
		Zapper.TelegraphChargeSpotLight.SetIntensity(1);
		AcceleratedIntensity.SnapTo(1.0);
		Zapper.VFXShieldTemp.SetHiddenInGame(true);
		Zapper.BeamAttackDecalComp.SetHiddenInGame(true);
		USummitStoneBeastZapperEffectHandler::Trigger_OnStoppedBeamAttack(Owner);
		
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraphing
		UHazeOffsetComponent MeshOffsetComp = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
		FRotator MeshRot = MeshOffsetComp.RelativeRotation;
		
		if(ActiveDuration < Settings.AttackTelegraphDuration) // Telegraphing
		{			
			// Charging crystal
			float Intensity = AcceleratedIntensity.AccelerateTo(10000.0, Settings.AttackTelegraphDuration * 5, DeltaTime);
			Zapper.TelegraphChargeSpotLight.SetIntensity(Intensity);

			// Update telegraphing decal size
			Zapper.BeamAttackDecalComp.SetHiddenInGame(false);
			CurrentDecalScale += Settings.BeamDecalScaleSpeed * DeltaTime;
			CurrentDecalScale = Math::Clamp(CurrentDecalScale, 0, Settings.BeamDecalMaxScale);
			Zapper.BeamAttackDecalComp.SetWorldScale3D(FVector(CurrentDecalScale, OriginalDecalScale.Y, OriginalDecalScale.Z));
			DecalOffsetLocation.X = CurrentDecalScale * 64.0; // Should be times decal initial X
			Zapper.BeamAttackDecalComp.SetRelativeLocation(DecalOffsetLocation);
			return;
		}
		else // Spawning Beam
		{
			// Activate Beam 
			BeamComp.BeamParams.BeamStartLocation = Owner.ActorCenterLocation;			
			BeamComp.BeamParams.BeamEndLocation = Owner.ActorCenterLocation + Owner.ActorForwardVector * CurrentBeamDist;

			
			// TODO: trace for player

			CurrentBeamDist += Settings.BeamAttackSpeed * DeltaTime;
			if (!bHasStartedBeamAttack)
			{
				USummitStoneBeastZapperEffectHandler::Trigger_OnStartedBeamAttack(Owner, FSSummitStoneBeastZapperBeamData(BeamComp));
				bHasStartedBeamAttack = true;
			}

			// Discharging Zapper's crystal
			float Intensity = AcceleratedIntensity.AccelerateTo(1.0, 0.5, DeltaTime);
			Zapper.TelegraphChargeSpotLight.SetIntensity(Intensity);
			
			// Spawn effect flashes
			if (NumSpawned < Settings.BeamAttackFlashEffectSpawnNum && TimeToNextSpawn < 0.0)
			{				
				NumSpawned++;
				TimeToNextSpawn += Settings.BeamAttackFlashEffectSpawnRate;
				
				// discharge
				USummitStoneBeastZapperEffectHandler::Trigger_OnStopTelegraphing(Owner);

				if (NumSpawned >= Settings.BeamAttackFlashEffectSpawnNum)
				{
					// Zapper's color restores
					MaterialInstanceDynamic.SetVectorParameterValue(n"Tint", StartColor);
				}
				
			}
			else
			{
				TimeToNextSpawn -= DeltaTime;				
			}

		}	

		// Start animation for moving to Recovery/Vulnerable state
		if (!bIsStoppingBeamAttack && ActiveDuration > Settings.AttackTelegraphDuration + (Settings.BeamAttackFlashEffectSpawnNum * Settings.BeamAttackFlashEffectSpawnRate) )
		{
			AnimComp.RequestFeature(FeatureTagCrystalCrawler::Locomotion, SummitCrystalCrawlerSubTags::AttackExit, EBasicBehaviourPriority::Minimum, this);
			bIsStoppingBeamAttack = true;
		}

	}

};