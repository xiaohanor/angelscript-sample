class AStormSiegeBarrierRaiseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualRoot;
	default VisualRoot.SetWorldScale3D(FVector(30.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndLocation;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = EndLocation)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(120.0));
#endif

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	FVector EndWorldLocation;
	float Speed = 20000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		EndWorldLocation = EndLocation.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, EndWorldLocation, DeltaSeconds, Speed);

		if ((ActorLocation - EndWorldLocation).Size() < 5.0)
		{
			Game::Mio.StopCameraShakeByInstigator(this);
			Game::Zoe.StopCameraShakeByInstigator(this);
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void ActivateRisingBarriers()
	{
		SetActorTickEnabled(true);
		Game::Mio.PlayCameraShake(CameraShake, this);
		Game::Zoe.PlayCameraShake(CameraShake, this);
	}
}