class ATundraBossRingOfIceSpikesActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float LifeTime = 0;
	float MaxLifeTime = 8;
	float Scale = 1;
	float ScaleSpeed = 12;
	float KillRadius = 100;
	float HeightCheck = 150;
	bool bCanDealDamage = true;
	TArray<AHazePlayerCharacter> Players;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeactivateSlam();
		Players.Add(Game::GetMio());
		Players.Add(Game::GetZoe());
	}

	void TriggerRingOfIceSpikesActor(FVector SpawnLocation, AHazeActor Boss)
	{
		SetActorLocation(SpawnLocation);
		LifeTime = MaxLifeTime;
		SetActorHiddenInGame(false);
		SetActorTickEnabled(true);

		FTundraBossIceRingEventData EventData;
		EventData.RingSpawnLocation = SpawnLocation;
		EventData.RingLifeTime = MaxLifeTime;
		EventData.RingScaleSpeed = ScaleSpeed;
		EventData.RingStartRadius = 125;
		EventData.RingThickness = KillRadius;

		UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_Spawned(this, EventData);
		UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_Spawned(Boss, EventData);

		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			if(IsPlayerWithinInstaDeathZone(Player))
				Player.KillPlayer();
		}

		Scale = 0;
	}

	void DeactivateSlam()
	{
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LifeTime -= DeltaSeconds;
		if(LifeTime <= 0)
		{
			DeactivateSlam();
			return;
		}
		
		Scale += ScaleSpeed*DeltaSeconds;
		for(auto Player : Players)
		{
			if(!Player.HasControl())
				continue;

			UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
			if(!MoveComp.HasGroundContact())
				continue;
			
			if(!CheckPlayerShouldBeDamaged(Player))
				continue;
			
			if(bCanDealDamage)
			{
				Player.DamagePlayerHealth(0.5);

#if TEST
			if(Player.GetGodMode() == EGodMode::God)
				continue;
#endif

				FVector KnockDownDir = (Player.ActorLocation - ActorLocation).GetSafeNormal2D(FVector::UpVector);
				Player.ApplyKnockdown(KnockDownDir * 500, 1, Cooldown = 2);
			}
		}	
	}

	bool CheckPlayerShouldBeDamaged(AHazePlayerCharacter Player)
	{
		return GetActorLocation().Distance(Player.GetActorLocation()) < Scale * 125
			&& GetActorLocation().Distance(Player.GetActorLocation()) > Scale * 125 - KillRadius
			&& Math::Abs(GetActorLocation().Z - Player.GetActorLocation().Z) < HeightCheck;
	}

	bool IsPlayerWithinInstaDeathZone(AHazePlayerCharacter Player)
	{
		return (GetHorizontalDistanceTo(Player) < 500);	
	}
}

namespace TundraBossRingOfIceSpike
{
	UFUNCTION()
	TArray<ATundraBossRingOfIceSpikesActor> GetAllTundraBossRingOfIceSpikes()
	{
		return TListedActors<ATundraBossRingOfIceSpikesActor>().Array;
	}
}