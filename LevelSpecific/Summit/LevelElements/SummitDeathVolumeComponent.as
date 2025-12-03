enum ESummitDeathVolumeType
{
	BabyDragon,
	TeenDragon,
	AdultDragon,
	Player
}

class USummitDeathVolumeComponent : USceneComponent
{
	/* OBS! SHOULD PROBABLY USE NORMAL PLAYER DEATH ZONES  */

	UPROPERTY(EditAnywhere, Category = "Settings")
	private bool bIsActive = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Size = 400;

	UPROPERTY(EditDefaultsONly, Category = "Settings")
	ESummitDeathVolumeType Type = ESummitDeathVolumeType::Player;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UDeathEffect> DeathEffect = nullptr;

	TArray<ABabyDragon>	BabyDragons;
	TArray<AHazePlayerCharacter> TeenDragons;
	TArray<AHazePlayerCharacter> AdultDragons;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::Players)
		{
			switch(Type)
			{
				case ESummitDeathVolumeType::BabyDragon :
				{
					auto BabyDragon = UPlayerBabyDragonComponent::Get(Player).BabyDragon;
					if(BabyDragon != nullptr)
						BabyDragons.Add(BabyDragon);
					break;
				}
				case ESummitDeathVolumeType::TeenDragon :
				{
					auto TeenDragon = UPlayerTeenDragonComponent::Get(Player);
					if(TeenDragon != nullptr)
						TeenDragons.Add(Player);
					break;
				}
				case ESummitDeathVolumeType::AdultDragon : 
				{
					auto AdultDragon = UPlayerAdultDragonComponent::Get(Player);
					if(AdultDragon != nullptr)
						AdultDragons.Add(Player);
					break;
				}
				default :
				{
					break;
				} 
			}
		}
	}

	void SetKillActive(bool bActive)
	{
		bIsActive = bActive;

		if (bIsActive)
		{
			TArray<AActor> OverlappingActors;
			// GetOverlappingActors(OverlappingActors);

			if (OverlappingActors.Num() > 0)
			{
				for (AActor OtherActor : OverlappingActors)
				{
					KillPlayerCheck(OtherActor);
				}
			}
		}
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (!bIsActive)
			return;

		KillPlayerCheck(OtherActor);
	}

	void KillPlayerCheck(AActor Actor)
	{
		AHazePlayerCharacter TeenDragon = Cast<AHazePlayerCharacter>(Actor);

		if (TeenDragon != nullptr)
		{
			TeenDragon.KillPlayer();
		}	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsActive)
			return;

		switch(Type)
		{
			case ESummitDeathVolumeType::BabyDragon :
			{
				for(auto BabyDragon : BabyDragons)
				{
					if(BabyDragon.ActorLocation.DistSquared(WorldLocation) <= Math::Square(Size))
						BabyDragon.Player.KillPlayer(DeathEffect = DeathEffect);
				}
				break;
			}
			case ESummitDeathVolumeType::TeenDragon :
			{
				for(auto TeenDragon : TeenDragons)
				{
					if(TeenDragon.ActorLocation.DistSquared(WorldLocation) <= Math::Square(Size))
						TeenDragon.KillPlayer(DeathEffect = DeathEffect);
				}
				break;
			}
			case ESummitDeathVolumeType::AdultDragon : 
			{
				for(auto AdultDragon : AdultDragons)
				{
					if(AdultDragon.ActorLocation.DistSquared(WorldLocation) <= Math::Square(Size))
						AdultDragon.KillPlayer(DeathEffect = DeathEffect);
				}
				break;
			}
			case ESummitDeathVolumeType::Player:
			{
				for(auto Player : Game::Players)
				{
					if(Player.ActorLocation.DistSquared(WorldLocation) <= Math::Square(Size))
						Player.KillPlayer(DeathEffect = DeathEffect);
				}
				break;
			}
			default : 
			{
				break;
			}
		}
	}
}