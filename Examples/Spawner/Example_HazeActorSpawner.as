// The simplest possible spawner inherits from spawner base which provides base functionality 
// and detail customization
class AExample_SimpleSpawner : AHazeActorSpawnerBase
{
	// You only need to add a spawn pattern with a class to spawn and you're good to go
	// This particular spawn pattern respawn a single actor over and over
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternSingle Single; 
	default Single.SpawnClass = AExample_RespawningActor;

	// This is for testing purposes only, you do not need this!
	UFUNCTION(DevFunction)
	void TestStartSpawning()
	{
		ActivateSpawner();
	}
}

// You can extend an instance of a spawner with further spawn pattern as needed, but you can
// of course also define more advanced spawners in angelscript when appropriate.
class AExample_AdvancedSpawner : AHazeActorSpawnerBase
{
	// This will spawn four actors at 2s intervals before it's completed.
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternInterval StartingInterval; 
	default StartingInterval.SpawnClass = AExample_RespawningActor;
	default StartingInterval.Interval = 2.0;
	default StartingInterval.bInfiniteSpawn = false;
	default StartingInterval.MaxTotalSpawnedActors = 4;
	default StartingInterval.MaxActiveSpawnedActors = 4;
	default StartingInterval.RelativeLocation = FVector(200.0, 0.0, -50.0);

	// This will activate the delay when when StartingInterval has spawned four actors
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternActivateOnDoneSpawning ActivateDelayBeforeRoundTwo;
	default ActivateDelayBeforeRoundTwo.PatternsToActivate.Add(ActivateRoundTwoDelay);

	// This will do nothing until activated by the "DelayBeforeRoundTwo" tag,
	// then wait 10 seconds before activating the round two patterns
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternActivateOnDelay ActivateRoundTwoDelay;
	default ActivateRoundTwoDelay.Delay = 10.0;
	default ActivateRoundTwoDelay.bStartActive = false;
	default ActivateRoundTwoDelay.PatternsToActivate.Add(RoundTwoWaves);
	default ActivateRoundTwoDelay.PatternsToActivate.Add(RoundTwoSingle);
	default ActivateRoundTwoDelay.PatternsToActivate.Add(RoundTwoTeam);
	default ActivateRoundTwoDelay.PatternsToActivate.Add(RoundTwoSettings);
	default ActivateRoundTwoDelay.PatternsToActivate.Add(RoundTwoOtherActivateOnDeaths);

	// This will activate all patterns with the round two patterns as soon as four 
	// spawned actors have been killed.
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternActivateOnDeaths ActivateRoundTwoOnDeaths;
	default ActivateRoundTwoOnDeaths.DeathCount = 4;
	default ActivateRoundTwoOnDeaths.PatternsToActivate.Add(RoundTwoWaves);
	default ActivateRoundTwoOnDeaths.PatternsToActivate.Add(RoundTwoSingle);
	default ActivateRoundTwoOnDeaths.PatternsToActivate.Add(RoundTwoTeam);
	default ActivateRoundTwoOnDeaths.PatternsToActivate.Add(RoundTwoSettings);
	default ActivateRoundTwoOnDeaths.PatternsToActivate.Add(RoundTwoOtherActivateOnDeaths);

	// Once four actor has died or 10s after StartingInterval has completed (four actors 
	// have been spawned), whichever comes first, this pattern will start spawning waves
	// of three actors. When each wave is killed another wave will spawn after 2s.
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternWave RoundTwoWaves; 
	default RoundTwoWaves.SpawnClass = AExample_AnotherRespawningActor;
	default RoundTwoWaves.WaveSize = 3;
	default RoundTwoWaves.RespawnDuration = 2.0;
	default RoundTwoWaves.bStartActive = false;
	default RoundTwoWaves.RelativeLocation = FVector(-300.0, 0.0, -50.0);

	// Once either of the two conditions above are met this will spawn a single actor
	// which respawns 1s after dying.
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternSingle RoundTwoSingle; 
	default RoundTwoSingle.SpawnClass = AExample_OneMoreRespawningActor;
	default RoundTwoSingle.RespawnDuration = 1.0;
	default RoundTwoSingle.bStartActive = false;
	default RoundTwoSingle.RelativeLocation = FVector(-500.0, 0.0, 50.0);

	// Every actor spawned in round two will join this team
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternJoinTeam RoundTwoTeam; 
	default RoundTwoTeam.TeamName = n"RoundTwoTeam";
	default RoundTwoTeam.bStartActive = false;

	// All actors spawned by this spawner will get any settings you set on instances of this pattern
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternApplySettings AllSettings;
	default AllSettings.Priority = EHazeSettingsPriority::Gameplay;

	// Actors spawned in round two will get these settings which override the settings above
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternApplySettings RoundTwoSettings;
	default RoundTwoSettings.Priority = EHazeSettingsPriority::Script;
	default RoundTwoSettings.bStartActive = false;

	// When 10 actors have died during round two another spawner will be activated (if set on instance).
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternOtherActivateOnDeaths RoundTwoOtherActivateOnDeaths;
	default RoundTwoOtherActivateOnDeaths.DeathCount = 10; 
	default RoundTwoOtherActivateOnDeaths.bStartActive = false;

	// This is for testing purposes only, you do not need this!
	UFUNCTION(DevFunction)
	void TestStartSpawning()
	{
		ActivateSpawner();
	}

	// This is for testing purposes only, you do not need this!
	UFUNCTION(DevFunction)
	void KillAllSpawnedActors()
	{
		if (SpawnerComp.SpawnedActorsTeam != nullptr)
		{
			for (auto SpawnedActor : SpawnerComp.SpawnedActorsTeam.GetMembers())
			{
				AExample_RespawningActor Respawner = Cast<AExample_RespawningActor>(SpawnedActor);
				if (Respawner != nullptr)
					Respawner.Die();
			}
		}
	}
}

// If you need to have an existing actor spawn things, then you can skip inheriting from
// spawner base and use the components and capability that handles spawning
// Note that you will not get the actor details customization that allow you to easily add 
// patterns!
class AExample_SpawnerFromScratch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// This (or an appropriate substitute) will handle spawning of actors given suitable 
	// spawn patterns and a spawner component
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HazeActorSpawnerCapability");

	// This holds common spawner data
	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeActorSpawnerComponent SpawnerComp;

	// Finally, some spawn patterns to define how this should spawn
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternSingle SingleSpawn; 
}

class AExample_RespawningActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	FLinearColor Colour = FLinearColor::Yellow;
	float Size = 50.0;
	float SpawnHeight;
	float CanDieTime = 0.0;
	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spawn();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Just so we have something visible in game
		Debug::DrawDebugSphere(ActorLocation, Size, 4, Colour);
		
		if ((ActorLocation.Z > SpawnHeight) || (Velocity.DotProduct(ActorUpVector) > 0.01))
		{
			// Fall
			Velocity -= Velocity * 0.2 * DeltaTime;
			Velocity -= ActorUpVector * 982.0 * DeltaTime;
		}
		else
		{
			// Slide
			Velocity -= Velocity * 3.0 * DeltaTime;
			Velocity.Z = 0.0;
		}

		// Jump randomly when fairly stationary
		if (Velocity.IsNearlyZero(10.0) && (Math::RandRange(0.0, 1.0) < 5.0 * DeltaTime))
			Velocity += Math::GetRandomConeDirection(FVector::UpVector, PI * 0.4, PI * 0.1) * 500.0;

		ActorLocation += Velocity * DeltaTime;

		if (Time::GameTimeSeconds > CanDieTime)
		{
			// Kill when close to any player
			for (auto Player : Game::Players)
			{
				if (Player.ActorCenterLocation.IsWithinDist(ActorCenterLocation, 200.0))
				{
					Die();
					break;
				}
			}
		}
	}

	void Die()
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(this); 
		if (RespawnComp != nullptr)
		{
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");	
			AddActorDisable(n"GameOverMan");
			RespawnComp.UnSpawn();
			Debug::DrawDebugCircle(FVector(ActorLocation.X, ActorLocation.Y, SpawnHeight - 25.0), Size * 0.6, 12, FLinearColor::Red, 5.0, Duration = 5.0);
			Debug::DrawDebugCircle(FVector(ActorLocation.X, ActorLocation.Y, SpawnHeight - 25.0), Size * 0.4, 12, FLinearColor::Red, 5.0, Duration = 5.0);
			Debug::DrawDebugCircle(FVector(ActorLocation.X, ActorLocation.Y, SpawnHeight - 25.0), Size * 0.2, 12, FLinearColor::Red, 5.0, Duration = 5.0);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn()
	{
		Spawn();
		RemoveActorDisable(n"GameOverMan");
	}

	void Spawn()
	{
		SpawnHeight = ActorLocation.Z;
		Velocity = Math::GetRandomConeDirection(FVector::UpVector, PI * 0.4, PI * 0.1) * 500.0;
		CanDieTime = Time::GameTimeSeconds + 2.0;
	}
}

class AExample_AnotherRespawningActor : AExample_RespawningActor
{
	default Colour = FLinearColor::Green;
	default Size = 80.0;
}

class AExample_OneMoreRespawningActor : AExample_RespawningActor
{
	default Colour = FLinearColor::LucBlue;
	default Size = 30.0;
}
