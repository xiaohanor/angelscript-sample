UCLASS(Abstract)
class ASkylineHighwaySlingableDispenser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<ASkylineHighwaySlingable> SlingableClass;

	int SpawnCounter = 0;
	int WaveCounter = 0;
	int Pattern = 0;
	FVector BaseDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDectivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		if (Game::Zoe.HasControl())
		{
			WaveCounter = 0;
			BaseDirection = ActorForwardVector.RotateAngleAxis(Math::RandRange(-90, 90), ActorUpVector);

			for(int i = 0; i < 3; i++)
			{
				FVector Direction = FVector::ZeroVector;
				if(Pattern == 0)
					Direction = BaseDirection.RotateAngleAxis(WaveCounter * Math::RandRange(15, 30), ActorUpVector);
				if(Pattern == 1)
					Direction = BaseDirection.RotateAngleAxis(WaveCounter * Math::RandRange(80, 160), ActorUpVector);
				CrumbDispense(Direction);
			}

			Pattern++;
			if(Pattern > 1)
				Pattern = 0;
		}
	}

	UFUNCTION()
	private void HandleDectivated(AActor Caller)
	{
	}

	UFUNCTION(CrumbFunction)
	void CrumbDispense(FVector Direction)
	{
		ASkylineHighwaySlingable Slingable = SpawnActor(SlingableClass, ActorLocation, bDeferredSpawn = true);
		Slingable.MakeNetworked(this, SpawnCounter);
		SpawnCounter++;
		Slingable.ActorLocation = ActorLocation;
		Slingable.ActorRotation = ActorRotation;
		Slingable.Direction = Direction;
		WaveCounter++;
		FinishSpawningActor(Slingable);
	}
}