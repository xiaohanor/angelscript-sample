class AStormRideDragonWeakpoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	void ActivateWeakpointDestruction()
	{
		FStormRideWeakPointOnDestructionParams Params;
		Params.Location = ActorLocation;
		Params.AttachComponent = MeshRoot;
		UStormRideDragonWeakpointEffectHandler::Trigger_ActivateDestruction(this, Params);
		Game::Mio.PlayCameraShake(CameraShake, this);
		Game::Zoe.PlayCameraShake(CameraShake, this);
		OnStormRideDragonWeakpointDestroyed();
	}

	UFUNCTION(BlueprintEvent)
	void OnStormRideDragonWeakpointDestroyed() {}
}