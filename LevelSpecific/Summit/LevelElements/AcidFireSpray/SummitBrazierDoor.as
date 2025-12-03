class ASummitBrazierDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndLoc;

	UPROPERTY(DefaultComponent, Attach = EndLoc)
	UBillboardComponent Visual;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	bool bGoToEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bGoToEnd)
		{
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, EndLoc.RelativeLocation, DeltaSeconds, 400.0);
			float Dist = (MeshRoot.RelativeLocation - EndLoc.RelativeLocation).Size();
			if (Dist < 2.0)
			{
				Game::Zoe.PlayCameraShake(CameraShake, this);
				Game::Mio.PlayCameraShake(CameraShake, this);
				SetActorTickEnabled(false);
			}
		}
	}

	void ActivateDoor()
	{
		bGoToEnd = true;
	}
}