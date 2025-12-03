class USummitCameraShakeComponent : UActorComponent
{
	UPROPERTY(Category = "Setup")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Owner);		
		if (HealthComp != nullptr)
			HealthComp.OnDie.AddUFunction(this, n"OnSummitAIDie");
	}

	UFUNCTION()
	void OnSummitAIDie(AHazeActor ActorBeingKilled)
	{
		// ActivateCurseExplosionEffect();
		Game::Mio.PlayCameraShake(CameraShake, this);
		Game::Zoe.PlayCameraShake(CameraShake, this);
	}
}