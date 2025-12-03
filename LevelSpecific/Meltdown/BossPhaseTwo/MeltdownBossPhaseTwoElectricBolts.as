class AMeltdownBossPhaseTwoElectricBolts : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UDamageTriggerComponent DamageTrigger;

	float Timer;

	float LifeTime = 3;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		DamageTrigger.OnPlayerDamagedByTrigger.AddUFunction(this, n"OnDamagedPlayer");
    }

    UFUNCTION()
    private void OnDamagedPlayer(AHazePlayerCharacter Player)
    {
		Player.AddKnockbackImpulse(
			(Player.ActorLocation - AttachParentActor.ActorLocation).GetSafeNormal2D(),
			1200.0, 0.0,
		);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if(Timer > LifeTime)
		{
			AddActorDisable(this);
		}
	}
};