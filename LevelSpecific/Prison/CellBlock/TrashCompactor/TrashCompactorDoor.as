UCLASS(Abstract)
class ATrashCompactorDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent MioFrontDoorMesh;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent ZoeFrontDoorMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenDoorTimeLike;

	UPROPERTY(EditAnywhere)
	bool bSeeThroughMode = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MioFrontDoorMesh.SetVisibility(!bSeeThroughMode);
		ZoeFrontDoorMesh.SetVisibility(!bSeeThroughMode);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MioFrontDoorMesh.SetVisibility(true);
		ZoeFrontDoorMesh.SetVisibility(true);

		OpenDoorTimeLike.BindUpdate(this, n"UpdateOpenDoor");
		OpenDoorTimeLike.BindFinished(this, n"FinishOpenDoor");

		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
		{
			if (Actor.RootComponent.Mobility == EComponentMobility::Movable)
				Actor.AttachToComponent(DoorRoot, NAME_None, EAttachmentRule::KeepWorld);
		}

		MioFrontDoorMesh.SetRenderedForPlayer(Game::Zoe, false);
		ZoeFrontDoorMesh.SetRenderedForPlayer(Game::Mio, false);
	}

	UFUNCTION()
	void HideDoor()
	{
		MioFrontDoorMesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	void ShowDoor()
	{
		MioFrontDoorMesh.SetHiddenInGame(false);

		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
		{
			AStaticMeshActor Mesh = Cast<AStaticMeshActor>(Actor);
			if (Mesh != nullptr)
				Mesh.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	void OpenDoor()
	{
		OpenDoorTimeLike.Play();

		UTrashCompactorDoorEffectEventHandler::Trigger_OpenDoor(this);
	}

	UFUNCTION()
	void CloseDoor()
	{
		OpenDoorTimeLike.Reverse();

		UTrashCompactorDoorEffectEventHandler::Trigger_CloseDoor(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenDoor(float CurValue)
	{
		float Height = Math::Lerp(0.0, -1000.0, CurValue);
		DoorRoot.SetRelativeLocation(FVector(0.0, 0.0, Height));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenDoor()
	{
		AddActorDisable(this);
	}
}