class UTeenDragonKillOnImpactComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto CallBackComp = UMovementImpactCallbackComponent::GetOrCreate(Owner);
		CallBackComp.OnAnyImpactByPlayer.AddUFunction(this, n"OnAnyImpactByPlayer"); 
	}

	UFUNCTION()
	private void OnAnyImpactByPlayer(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(FPlayerDeathDamageParams(Player.ActorForwardVector, 10.0), DeathEffect);
		Player.PlayCameraShake(CameraShake, this);
	}
};