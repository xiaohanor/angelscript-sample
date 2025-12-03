struct FSkylineDroneBossScatterTrailPlayerData
{
	bool bIsOverlapping = false;
	float DamageTimestamp = 0.0;
}

class ASkylineDroneBossScatterTrail : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default SetLifeSpan(4.0);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"OverlapAll";

	// Time between damage taken if the player keeps overlapping the trail.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trail")
	float DamageInterval = 0.4;

	// How much damage is dealt to the player on first contact.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trail")
	float ContactDamage = 0.1;

	// How much damage is dealt to the player per interval while overlapping the trail.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trail")
	float DamagePerInterval = 0.06;

	TPerPlayer<FSkylineDroneBossScatterTrailPlayerData> PlayerData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"HandleActorBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"HandleActorEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bIsOverlappingAny = false;
		for (auto Player : Game::Players)
		{
			auto& Data = PlayerData[Player];
			if (!Data.bIsOverlapping)
				continue;
			if (Player.IsPlayerDead())
				continue;
			
			float TimeSinceDamageDealt = Time::GetGameTimeSince(Data.DamageTimestamp);
			if (TimeSinceDamageDealt >= DamageInterval)
			{
				DamagePlayer(Player, DamagePerInterval);
				Data.DamageTimestamp = Time::GameTimeSeconds;
			}

			bIsOverlappingAny = true;
		}

		if (!bIsOverlappingAny)
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void HandleActorBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		auto& Data = PlayerData[Player];
		Data.bIsOverlapping = true;
		Data.DamageTimestamp = Time::GameTimeSeconds;

		DamagePlayer(Player, ContactDamage);

		if (!IsActorTickEnabled())
		{
			SetActorTickEnabled(true);
		}
	}
	
	UFUNCTION()
	private void HandleActorEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		auto& Data = PlayerData[Player];
		Data.bIsOverlapping = false;
	}

	private void DamagePlayer(AHazePlayerCharacter Player, float Damage)
	{
		if (Player == nullptr || Damage < SMALL_NUMBER)
			return;

		Player.DamagePlayerHealth(Damage);
	}
}