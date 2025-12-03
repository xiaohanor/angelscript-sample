class USummitStoneBeastZapperAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 

	AAISummitStoneBeastZapper Zapper;
	USummitStoneBeastZapperSettings Settings;

	private bool bAttacked = false;

	private FVector AttackStartLocation;
	private FHazeAcceleratedVector AccAttack;

	private FHazeAcceleratedFloat AcceleratedIntensity;
	private FHazeAcceleratedFloat HackPitchMesh;
	private FHazeAcceleratedFloat HackMeshZOffset;

	private ASummitStoneBeastZapperLightningCrystalActor LightningCrystals;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	UHazeActorSpawnPoolReserve SpawnPoolReserve;

	// Alternatively, you can make a Dynamic Material instance from the mesh and set parameters on it.
	UMaterialInstanceDynamic MaterialInstanceDynamic;
	FLinearColor StartColor;

	private int NumSpawned = 0;
	private float TimeToNextSpawn = 0.0;

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

		SpawnPool = Zapper.GetOrCreateGroundLightningCrystalSpawnPool();
		SpawnPoolReserve = HazeActorSpawnPoolReserve::Create(Owner);
		SpawnPoolReserve.ReserveSpawn(SpawnPool);

		int MaterialIndex = 0;

		MaterialInstanceDynamic = Zapper.Mesh.CreateDynamicMaterialInstance(MaterialIndex);
		StartColor = MaterialInstanceDynamic.GetVectorParameterValue(n"Tint");
	}

	UFUNCTION()
	private void OnReset()
	{
		Zapper.TelegraphChargeSpotLight.SetIntensity(1);
		AcceleratedIntensity.SnapTo(1.0);
		USummitStoneBeastZapperEffectHandler::Trigger_OnStopTelegraphing(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);

		if (!IsActive())
		{
			// Restore pitch after telegraphing
			UHazeOffsetComponent MeshOffsetComp = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
			FRotator MeshRot = MeshOffsetComp.RelativeRotation;
			float Pitch = HackPitchMesh.AccelerateTo(10.0, 0.6, DeltaTime); // Not the original pitch, but looks better for the time being.
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}
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
		if (ActiveDuration > Settings.AttackTelegraphDuration + (Settings.AttackSpawnNum * Settings.AttackSpawnRate) + Settings.AttackRecovery)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bAttacked = false;
		NumSpawned = 0;
		TimeToNextSpawn = 0.0;
		
		MaterialInstanceDynamic.SetVectorParameterValue(n"Tint", FLinearColor(1, 1, 1.5));
		
		// Charging crystal
		Zapper.TelegraphChargeSpotLight.SetVisibility(true);
		Zapper.TelegraphChargeSpotLight.SetIntensity(1);
		USummitStoneBeastZapperEffectHandler::Trigger_OnStartTelegraphing(Owner, FSummitStoneBeastZapperStartTelegraphingParams(Zapper.TelegraphChargeVFXLocation));

		AttackStartLocation = Zapper.ActorLocation;
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
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraphing
		UHazeOffsetComponent MeshOffsetComp = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
		FRotator MeshRot = MeshOffsetComp.RelativeRotation;
		
		if(ActiveDuration < Settings.AttackTelegraphDuration) // Telegraphing
		{
			// Pitch mesh upwards
			float Pitch = HackPitchMesh.AccelerateTo(40.0, Settings.AttackTelegraphDuration, DeltaTime);
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
			float ZOffset = HackMeshZOffset.AccelerateTo(60.0, Settings.AttackTelegraphDuration, DeltaTime);			
			MeshOffsetComp.SetRelativeLocation(FVector(0,0,ZOffset));
			
			// Charging crystal
			float Intensity = AcceleratedIntensity.AccelerateTo(10000.0, Settings.AttackTelegraphDuration * 5, DeltaTime);
			Zapper.TelegraphChargeSpotLight.SetIntensity(Intensity);

			return;
		}
		else // Spawning LightningCrystals
		{
			// Restore pitch
			float Pitch = HackPitchMesh.AccelerateTo(0.0, 0.1, DeltaTime);
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
			float ZOffset = HackMeshZOffset.AccelerateTo(0.0, 0.3, DeltaTime);			
			MeshOffsetComp.SetRelativeLocation(FVector(0,0,ZOffset));

			// Discharging crystal
			float Intensity = AcceleratedIntensity.AccelerateTo(1.0, 0.5, DeltaTime);
			Zapper.TelegraphChargeSpotLight.SetIntensity(Intensity);
			
			// Spawn LightningCrystal
			if (NumSpawned < Settings.AttackSpawnNum && TimeToNextSpawn < 0.0)
			{				
				SpawnLightningCrystal();
				TimeToNextSpawn += Settings.AttackSpawnRate;
				
				// discharge
				USummitStoneBeastZapperEffectHandler::Trigger_OnStopTelegraphing(Owner);

				if (NumSpawned >= Settings.AttackSpawnNum)
				{
					// Color restores
					MaterialInstanceDynamic.SetVectorParameterValue(n"Tint", StartColor);
				}
				
			}
			else
			{
				TimeToNextSpawn -= DeltaTime;				
			}

		}	

	}
	
	// Currently intended to support one or three bolts.
	void SpawnLightningCrystal()
	{
		FVector AttackLocation = GetAttackLocation();
		
		LightningCrystals = Cast<ASummitStoneBeastZapperLightningCrystalActor>(SpawnPoolReserve.Spawn());
		SpawnPoolReserve.ReserveSpawn(SpawnPool);

		auto LightningCrystalsRespawnComp = UHazeActorRespawnableComponent::GetOrCreate(LightningCrystals);
		LightningCrystalsRespawnComp.OnSpawned(Owner, FHazeActorSpawnParameters());

		FSummitStoneBeastZapperLightningCrystalParams Params;
		Params.ZapperOwner = Zapper;
		Params.Settings = Settings;
		Params.SpawnPool = Zapper.GetOrCreateGroundLightningCrystalSpawnPool();
		Params.TargetActor = TargetComp.Target;
		Params.AttackLocation = AttackLocation;
			
		if (NumSpawned % 3 == 0)
			Params.InitialMoveDir = Owner.ActorForwardVector;
		else if (NumSpawned % 3 == 1)
			Params.InitialMoveDir = Owner.ActorRightVector;
		else if (NumSpawned % 3 == 2)
			Params.InitialMoveDir = Owner.ActorRightVector * -1.0;

		LightningCrystals.Setup(Params);
		LightningCrystals.SetActorLocation(Owner.ActorLocation);
		
		NumSpawned++;
	}
	
	private FVector GetAttackLocation()
	{
		// Set attack location to ground beneath player
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		FHitResult GroundImpact = Trace.QueryTraceSingle(TargetComp.Target.ActorCenterLocation, TargetComp.Target.ActorLocation + FVector::DownVector * 400);		
		if (GroundImpact.bBlockingHit)
			return GroundImpact.ImpactPoint;
		else
			return TargetComp.Target.ActorLocation;
	}
};