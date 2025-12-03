class AMeltdownWorldSpinWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxRotate;

	UPROPERTY(DefaultComponent, Attach = FauxRotate)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere)
	float GravityForce = 300.0;

	AMeltdownWorldSpinManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Manager == nullptr)
			Manager = AMeltdownWorldSpinManager::GetWorldSpinManager();
		if (Manager == nullptr)
			return;
        
		const FVector GravityDir = -Manager.WorldSpinRotation.UpVector;
		FauxRotate.ApplyForce(FauxRotate.WorldLocation + FVector(0, 0, -100), GravityDir * GravityForce);
	}
};