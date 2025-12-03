class ASerpentRunVerticalDropCameraActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector BetweenPoint = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		ActorLocation = BetweenPoint; 
		ActorLocation -= ActorForwardVector * 400.0;
		ActorLocation -= FVector::UpVector * 1000.0;
		FVector Direction = (BetweenPoint - ActorLocation).GetSafeNormal();
		CameraComp.WorldRotation = Direction.Rotation();
	}

	UFUNCTION()
	void ActivateCamera(AHazePlayerCharacter Player, float BlendTime)
	{
		Player.ActivateCamera(CameraComp, BlendTime, this);
	}
}