class USummitCrystalSkullSpawnCrittersBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCrystalSkullSettings FlyerSettings;

	UBasicAIHealthComponent HealthComp;
	USummitCrystalSkullComponent FlyerComp;
	int NumSpawnAlive = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		HealthComp.OnDie.AddUFunction(this, n"OnDie");

		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);

		if (FlyerComp.CritterSpawner == nullptr)
			UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
		else
			InitializeCritterSpawner();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if (FlyerComp.CritterSpawner == nullptr)
		{
			UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
			if (RespawnComp.SpawnParameters.Spawner != nullptr)
			{
				UHazeActorSpawnPattern SpawnPattern = Cast<UHazeActorSpawnPattern>(RespawnComp.SpawnParameters.Spawner);
				if ((SpawnPattern != nullptr) && (SpawnPattern.Owner != nullptr))
				{
					TArray<AActor> Attachees;
					SpawnPattern.Owner.GetAttachedActors(Attachees, true, true);
					for (AActor Attachee : Attachees)
					{
						AHazeActorSpawnerBase AttachedSpawner = Cast<AHazeActorSpawnerBase>(Attachee);
						if (AttachedSpawner != nullptr)
							FlyerComp.CritterSpawner = AttachedSpawner;	
					}
				}
			}
		}
		InitializeCritterSpawner();
	}

	void InitializeCritterSpawner()
	{
		if (FlyerComp.CritterSpawner != nullptr)
		{
			FlyerComp.CritterSpawner.AttachToActor(Owner, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
			FlyerComp.CritterSpawner.DeactivateSpawner();
			FlyerComp.CritterSpawner.SpawnerComp.OnPostSpawn.AddUFunction(this, n"OnPostSpawn");
			FlyerComp.CritterSpawner.SpawnerComp.OnPostUnspawn.AddUFunction(this, n"OnPostUnspawn");
			UHazeActorSpawnPatternSingle SingleSpawner = UHazeActorSpawnPatternSingle::Get(FlyerComp.CritterSpawner);
			if (SingleSpawner != nullptr)
			{
				SingleSpawner.bInfiniteSpawn = true;
				SingleSpawner.RespawnDuration = 0.0;
			}
			UHazeActorSpawnPatternInterval IntervalSpawner = UHazeActorSpawnPatternInterval::Get(FlyerComp.CritterSpawner);
			if (IntervalSpawner != nullptr)
			{
				IntervalSpawner.bInfiniteSpawn = true;
				IntervalSpawner.RespawnDelay = 0.0;
			}
			UHazeActorSpawnPatternWave WaveSpawner = UHazeActorSpawnPatternWave::Get(FlyerComp.CritterSpawner);
			if (WaveSpawner != nullptr)
			{
				WaveSpawner.bInfiniteSpawn = true;
				WaveSpawner.RespawnDuration = 0.0;
			}
		}
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		// Kill all spawned critters
		if ((FlyerComp.CritterSpawner != nullptr) && (FlyerComp.CritterSpawner.SpawnerComp.SpawnedActorsTeam != nullptr))
		{
			for (AHazeActor Critter : FlyerComp.CritterSpawner.SpawnerComp.SpawnedActorsTeam.GetMembers())
			{
				UBasicAIHealthComponent CritterHealthComp = UBasicAIHealthComponent::Get(Critter);
				if (CritterHealthComp != nullptr)
					CritterHealthComp.TakeDamage(CritterHealthComp.MaxHealth, EDamageType::Explosion, HealthComp.LastAttacker);
			}			
		}
	}

	UFUNCTION()
	private void OnPostUnspawn(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		NumSpawnAlive--;
	}

	UFUNCTION()
	private void OnPostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		NumSpawnAlive++;

		// We only allow a single spawn for now (though that could be a single wave)
		FlyerComp.CritterSpawner.DeactivateSpawner();
	}

	bool WantsToSpawnCritters() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;

		if (FlyerComp.CritterSpawner == nullptr)
			return false;
		if (NumSpawnAlive > 0)
			return false;

		AHazePlayerCharacter Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Target == nullptr)
			Target = Game::Zoe;
		AHazePlayerCharacter OtherPlayer = Target.OtherPlayer;
		FVector TargetLoc = Target.ActorLocation;

		// Is any player in range?
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, FlyerSettings.SpawnCrittersMaxRange) && 
			!Owner.ActorLocation.IsWithinDist(OtherPlayer.ActorLocation, FlyerSettings.SpawnCrittersMaxRange))
			return false;

		// Is target outside of min range?
		if (Owner.ActorLocation.IsWithinDist(TargetLoc, FlyerSettings.SpawnCrittersMinRange))
			return false;

		// Is any player looking at us?
		float MinCosAngle = Math::Cos(Math::DegreesToRadians(FlyerSettings.SpawnCrittersMinAngle));
		if ((Target.ViewRotation.Vector().DotProduct((Owner.ActorLocation - TargetLoc).GetSafeNormal()) < MinCosAngle) &&
		  	(OtherPlayer.ViewRotation.Vector().DotProduct((Owner.ActorLocation - OtherPlayer.ActorLocation).GetSafeNormal()) < MinCosAngle))
			return false;	
	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToSpawnCritters())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > FlyerSettings.SpawnCrittersDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FlyerComp.SetVulnerable();
		USummitCrystalSkullEventHandler::Trigger_OnTelegraphCritterSpawn(Owner);
		NumSpawnAlive = 0;
		FlyerComp.CritterSpawner.ActivateSpawner();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(FlyerSettings.SpawnCrittersCooldown);
		FlyerComp.ClearVulnerable();
		FlyerComp.LastAttackTime = Time::GameTimeSeconds;
		FlyerComp.CritterSpawner.DeactivateSpawner();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Resume signs of being alert just before actually becoming able to dodge
		if (ActiveDuration > FlyerSettings.SpawnCrittersDuration - 0.5)
			FlyerComp.ClearVulnerable();
	}
}

