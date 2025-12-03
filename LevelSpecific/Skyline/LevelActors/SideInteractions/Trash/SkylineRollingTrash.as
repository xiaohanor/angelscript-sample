class ASkylineRollingTrash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartLocation;

	UPROPERTY(DefaultComponent, Attach = StartLocation)
	UFauxPhysicsSplineTranslateComponent FauxTranslationComp;
	default FauxTranslationComp.bConstrainZ = true;
	default FauxTranslationComp.MinZ = 0.0;
	default FauxTranslationComp.MaxZ = 5000.0;

	UPROPERTY(DefaultComponent, Attach = FauxTranslationComp)
	UFauxPhysicsAxisRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UStaticMeshComponent TrashMesh;

	bool bReplacing = false;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineThrowableTrash> ThrowableTrashClass;

	bool bHitFloor = false;
	float SafetyCooldown = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USkylineRollingTrashEventHandler::Trigger_StartRolling(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bReplacing)
			return;

		FauxTranslationComp.ApplyForce(TrashMesh.WorldLocation, -FVector::UpVector * 980.0);
		
		if (!HasControl())
			return;

		FVector FauxMove = FauxTranslationComp.GetVelocity();
		SafetyCooldown -= DeltaSeconds;
		if (SafetyCooldown < 0.0 && !bReplacing && FauxMove.Size() < 5.0)
		{
			bReplacing = true;
			if (ThrowableTrashClass != nullptr)
			{
				FVector Location = TrashMesh.WorldLocation;
				CrumbReplaceWithSlingable(Location, TrashMesh.WorldRotation);
				USkylineRollingTrashEventHandler::Trigger_StopRolling(this);
				FauxTranslationComp.AddDisabler(this);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReplaceWithSlingable(FVector TrashMeshLocation, FRotator Rotation)
	{
		ASkylineThrowableTrash SpawnedActor = SpawnActor(ThrowableTrashClass, TrashMeshLocation, Rotation, NAME_None, true);
		SpawnedActor.MakeNetworked(this, 0);
		SpawnedActor.SetActorControlSide(Game::Zoe);
		FVector SlightOffset = TrashMeshLocation - SpawnedActor.TrashMesh.WorldLocation;
		FinishSpawningActor(SpawnedActor);
		SpawnedActor.SetActorLocation(TrashMeshLocation + SlightOffset);

		TrashMesh.SetVisibility(false, true);
		SetAutoDestroyWhenFinished(true);
	}
};