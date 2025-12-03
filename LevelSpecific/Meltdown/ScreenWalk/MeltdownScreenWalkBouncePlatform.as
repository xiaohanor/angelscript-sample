class AMeltdownScreenWalkBouncePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UBillboardComponent HitPoint;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	FVector Impulse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnJumpTrigger.AddUFunction(this, n"OnActivated");
	}

	UFUNCTION()
	private void OnActivated()
	{
		TranslateComp.ApplyImpulse(
		Mesh.WorldLocation, FVector(Impulse)
		);
	}
};