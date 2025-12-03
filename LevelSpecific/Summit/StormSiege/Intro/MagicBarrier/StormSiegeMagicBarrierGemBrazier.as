class AStormSiegeMagicBarrierGemBrazier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent System;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION()
	void DeactivateGemBrazier()
	{
		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 15000.0, 125000.0);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 15000.0, 125000.0);
		System.Deactivate();
		FGemBrazierDeactivateParams Params;
		Params.Location = System.WorldLocation;
		UGemBrazierEffectHandler::Trigger_DeactivateBrazier(this, Params);
	}
}