class AMeltdownBossPhaseThreeFallingDamageTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.DamageAmount = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageTrigger.OnPlayerDamagedByTrigger.AddUFunction(this, n"PlayerHit");

	//	Debug::DrawDebugBox(ActorCenterLocation, DamageTrigger.Shape.BoxExtents, Rotation = ActorRotation, Thickness = 100.0, Duration = 100.0);
	}

	UFUNCTION()
	private void PlayerHit(AHazePlayerCharacter Player)
	{
		auto SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
		SkydiveComp.RequestHitReaction(ActorLocation);
	}

};