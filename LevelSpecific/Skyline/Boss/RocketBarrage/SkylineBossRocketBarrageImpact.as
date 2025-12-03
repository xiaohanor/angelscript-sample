UCLASS(Abstract)
class ASkylineBossRocketBarrageImpact : AHazeActor
{
	default PrimaryActorTick.TickInterval = 0.5;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UHazeActorLocalSpawnPoolEntryComponent SpawnPoolEntryComp;

	UPROPERTY(EditDefaultsOnly)
	bool bDamagePlayer = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bDamagePlayer"))
	float Damage = 0.1;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bDamagePlayer"))
	bool bCanKillPlayer = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bDamagePlayer"))
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = "bDamagePlayer"))
	TSubclassOf<UCameraShakeBase> CameraShake;

	float SpawnedTime = 0;
	bool bIsBurning = false;
	TPerPlayer<bool> bHasDamagedPlayer;

	const float BurnDuration = 3.0; // 6.0
	const float SpawnedDuration = 8.0; // 16.0

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnPoolEntryComp.OnSpawned.AddUFunction(this, n"OnSpawned");
		SpawnPoolEntryComp.OnUnspawned.AddUFunction(this, n"OnUnspawned");

		TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		TriggerComp.DisableTrigger(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsBurning && Time::GetGameTimeSince(SpawnedTime) > BurnDuration)
		{
			StopBurning();
		}

		if(Time::GetGameTimeSince(SpawnedTime) > SpawnedDuration)
		{
			SpawnPoolEntryComp.Unspawn();
		}
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor Actor)
	{
		SpawnedTime = Time::GameTimeSeconds;

		bIsBurning = true;

		if(bDamagePlayer)
		{
			TriggerComp.EnableTrigger(this);
			bHasDamagedPlayer[0] = false;
			bHasDamagedPlayer[1] = false;
		}
	}

	UFUNCTION()
	private void OnUnspawned(AHazeActor Actor)
	{
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		check(bDamagePlayer);
		
		if(!Player.HasControl())
			return;

		if(bHasDamagedPlayer[Player])
			return;

		bHasDamagedPlayer[Player] = true;

		Player.PlayCameraShake(CameraShake, this);

		auto HealthComp = UPlayerHealthComponent::Get(Player);
		if(!bCanKillPlayer && HealthComp.WouldDieFromDamage(Damage, true))
			return;

		HealthComp.DamagePlayer(Damage, DamageEffect, nullptr);

		// If we have damaged both players, disable the trigger
		if(bHasDamagedPlayer[Player.OtherPlayer])
			TriggerComp.DisableTrigger(this);
	}

	private void StopBurning()
	{
		check(bIsBurning);
		BP_OnStopBurning();

		TriggerComp.DisableTrigger(this);
		bIsBurning = false;
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnStopBurning() {}
};