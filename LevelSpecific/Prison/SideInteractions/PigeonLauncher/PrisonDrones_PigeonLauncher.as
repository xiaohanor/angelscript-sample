UCLASS(Abstract)
class APrisonDrones_PigeonLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UArrowComponent LaunchDirectionComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APrisonDrones_Pigeon> PigeonClass;

	UPROPERTY(EditDefaultsOnly)
	float LaunchForce = 10000;
	
	uint SpawnCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintCallable)
	void LaunchPigeon()
	{
		if(!HasControl())
			return;

		FRotator SpawnRotation;
		SpawnRotation = LaunchDirectionComp.WorldRotation;
		SpawnRotation.Yaw += Math::RandRange(-10, 10);

		float Force = LaunchForce + Math::RandRange(-2000, 2000);

		float RandomDirection = Math::RandRange(-1500,1500);

		UPrisonDrones_PigeonLauncherEventHandler::Trigger_OnLaunchPigeon(this);

		CrumbSpawn(SpawnRotation, Force, RandomDirection);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawn(FRotator SpawnRotation, float Force, float Direction)
	{
		auto Pigeon = SpawnActor(PigeonClass, LaunchDirectionComp.WorldLocation, SpawnRotation, bDeferredSpawn = true);

		Pigeon.MakeNetworked(this, SpawnCount);
		SpawnCount++;

		FVector Impulse = LaunchDirectionComp.ForwardVector * Force;
		Impulse += LaunchDirectionComp.RightVector * Direction;
		Pigeon.FauxTranslateComp.SetVelocity(Impulse);

		FinishSpawningActor(Pigeon);
	}
};