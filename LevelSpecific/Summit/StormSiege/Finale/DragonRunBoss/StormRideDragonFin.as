class AStormRideDragonFin : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetRotation;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachToOwnerComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	float RotationSpeed = HALF_PI;

	bool bRotatingDragonFin;

	FRotator StartingRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingRelativeRotation = MeshRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FQuat TargetQuat;

		if (bRotatingDragonFin)
			TargetQuat = TargetRotation.RelativeRotation.Quaternion();
		else
			TargetQuat = StartingRelativeRotation.Quaternion();

		MeshRoot.RelativeRotation = Math::QInterpConstantTo(
			MeshRoot.RelativeRotation.Quaternion(), 
			TargetQuat, 
			DeltaSeconds, 
			RotationSpeed).Rotator();
	}

	UFUNCTION()
	void ActivateDragonFin()
	{
		bRotatingDragonFin = true;
	}

	UFUNCTION()
	void DeactivateDragonFin()
	{
		bRotatingDragonFin = false;
	}
}