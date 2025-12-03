class USummitStoneBeastCritterGroundSpikeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	AAISummitStoneBeastCritter Critter;
	USummitStoneBeastCritterSettings Settings;

	private float AttackTelegraphDuration = 1.0;
	private float AttackDuration = 0.25;
	private float AttackRecoveryDuration = 0.25;
	private float AttackCooldownDuration = 2.0;
	private bool bAttacked = false;
	private bool bHasSpawned = false;

	private FVector AttackLocation;
	private FVector AttackStartLocation;
	private FHazeAcceleratedVector AccAttack;

	private FHazeAcceleratedFloat HackPitchMesh;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	UHazeActorSpawnPoolReserve SpawnPoolReserve;

	// Alternatively, you can make a Dynamic Material instance from the mesh and set parameters on it.
	UMaterialInstanceDynamic MaterialInstanceDynamic;
	FLinearColor StartColor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Critter = Cast<AAISummitStoneBeastCritter>(Owner);
		Settings = USummitStoneBeastCritterSettings::GetSettings(Owner);
		auto Respawn = UHazeActorRespawnableComponent::GetOrCreate(Critter);
		Respawn.OnRespawn.AddUFunction(this, n"OnReset");
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		SpawnPool = Critter.GetOrCreateGroundSpikeSpawnPool();
		SpawnPoolReserve = HazeActorSpawnPoolReserve::Create(Owner);
		SpawnPoolReserve.ReserveSpawn(SpawnPool);

		int MaterialIndex = 0;

		MaterialInstanceDynamic = Critter.Mesh.CreateDynamicMaterialInstance(MaterialIndex);
		StartColor = MaterialInstanceDynamic.GetVectorParameterValue(n"Tint");
	}

	UFUNCTION()
	private void OnReset()
	{
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
		if(!GentCostQueueComp.IsNext(this) && (Settings.AttackGentlemanCost != EGentlemanCost::None))
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
		if (ActiveDuration > AttackTelegraphDuration + AttackDuration + AttackRecoveryDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bAttacked = false;
		bHasSpawned = false;
		AttackLocation = Owner.ActorLocation + (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal() * Settings.AttackRange * 0.5;
		
		SpawnGroundSpikes();
		GroundSpikes.SetActorLocation(AttackLocation);		
		MaterialInstanceDynamic.SetVectorParameterValue(n"Tint", FLinearColor(2.87, 2.97, 1.4));

		AttackStartLocation = Critter.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraphing
		UHazeOffsetComponent MeshOffsetComp = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
		FRotator MeshRot = MeshOffsetComp.RelativeRotation;

		if(ActiveDuration < AttackTelegraphDuration)
		{
			// Pitch mesh upwards
			float Pitch = HackPitchMesh.AccelerateTo(60.0, 0.3, DeltaTime);
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
			
			GroundSpikes.SetDecalHiddenInGame(false);
			return;
		}
		else
		{
			// Slam down
			float Pitch = HackPitchMesh.AccelerateTo(0.0, 0.1, DeltaTime);
			MeshOffsetComp.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
			
			// Spikes rise
			GroundSpikes.ActivateSpikes();
			GroundSpikes.SetDecalHiddenInGame(true);

			// Color restores
			MaterialInstanceDynamic.SetVectorParameterValue(n"Tint", StartColor);
		}

		// Spawn spikes
		if (bHasSpawned)
			return;

		if(ActiveDuration > AttackTelegraphDuration + AttackDuration)
		{
		}

	}

	ASummitStoneBeastCritterSpikeActor GroundSpikes;
	void SpawnGroundSpikes()
	{
		bHasSpawned = true;
			
		GroundSpikes = Cast<ASummitStoneBeastCritterSpikeActor>(SpawnPoolReserve.Spawn());
		SpawnPoolReserve.ReserveSpawn(SpawnPool);

		auto GroundSpikesRespawnComp = UHazeActorRespawnableComponent::GetOrCreate(GroundSpikes);
		GroundSpikesRespawnComp.OnSpawned(Owner, FHazeActorSpawnParameters());

		GroundSpikes.ActorLocation = AttackLocation;
		GroundSpikes.ActorRotation = Owner.GetActorRotation();
		GroundSpikes.Setup(Critter);	
	}
}

