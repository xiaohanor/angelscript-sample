class APrisonNoseDivePhysicsObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION()
	void StartSimulating()
	{
		RootComp.SetSimulatePhysics(true);
		RootComp.AddAngularImpulseInDegrees(FVector(120.0, 0.0, 0.0), NAME_None, true);
	}
}