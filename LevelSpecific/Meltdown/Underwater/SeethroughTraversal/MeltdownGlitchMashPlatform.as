class AMeltdownGlitchMashPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent,RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MashPlatform;

	UPROPERTY(EditAnywhere)
	AMeltdownSeethroughMashInteraction MashInteract;

	FVector Startlocation;

	UPROPERTY(EditAnywhere)
	float MoveDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Startlocation = MashPlatform.GetRelativeLocation();
		MashInteract.ProgressUpdate.AddUFunction(this, n"MashInteraction");
	}


	UFUNCTION()
	private void MashInteraction (float MashProgress)
	{
		MashPlatform.SetRelativeLocation(Math::Lerp(Startlocation,FVector(MoveDistance,Startlocation.Y,Startlocation.Z), MashProgress));
	}
}