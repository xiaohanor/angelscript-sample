event void FVillageOgreBreakableEvent();
// Will presumably be replaced with actual breakables later :)
class AVillageOgreBreakable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BreakEffectPosition;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BreakEffect;

	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToDisable;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	FVillageOgreBreakableEvent OnBroken;

	bool bBroken = false;

	UFUNCTION()
	void Break()
	{
		if (bBroken)
			return;

		bBroken = true;

		OnBroken.Broadcast();

		for (AActor Actor : ActorsToDisable)
		{
			Actor.AddActorDisable(this);
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakEffect, BreakEffectPosition.WorldLocation);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (CameraShake.IsValid())
				Player.PlayCameraShake(CameraShake, this);

			if (ForceFeedback != nullptr)
				Player.PlayForceFeedback(ForceFeedback, false, true, this);
		}

		AddActorDisable(this);
	}
}