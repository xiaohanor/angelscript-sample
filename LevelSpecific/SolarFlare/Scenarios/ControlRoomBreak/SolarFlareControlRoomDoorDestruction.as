class ASolarFlareControlRoomDoorDestruction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;	

	TArray<UStaticMeshComponent> MeshComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		//Trigger destruction
		for (UStaticMeshComponent MeshComp : MeshComps)
		{
			MeshComp.SetSimulatePhysics(true);
			MeshComp.AddImpulse(ActorForwardVector * 55000.0);
		}
	}
}