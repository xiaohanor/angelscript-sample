class ATundra_IcePalace_CircularCameraActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraAttachComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Dir = Game::GetMio().ActorLocation - ActorLocation;
		ActorRotation = FRotator::MakeFromX(Dir.GetSafeNormal2D());
	}
};