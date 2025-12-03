class ABattlefieldShipPartExplosion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditInstanceOnly)
	AActor DebrisActor;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DebrisExplosion;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	float MaxDistance = 12000.0;

	UFUNCTION()
	void ActivateExplosion()
	{
		DebrisActor.AddActorDisable(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Multiplier = MaxDistance / (Player.ActorLocation - ActorLocation).Size();
			Multiplier = Math::Saturate(Multiplier);

			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, MaxDistance / 5, MaxDistance);
			Player.PlayForceFeedback(Rumble, false, false, this, Multiplier);
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(DebrisExplosion, ActorLocation, ActorRotation);
	}
};