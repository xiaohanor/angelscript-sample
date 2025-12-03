class ADroneHarpoonRotatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UArrowComponent ArrowComp;

	bool bHit;

	UFUNCTION()
	private void OnMaxHit(float Strength)
	{
		Print("contraint hit",5);
	}

	UFUNCTION(BlueprintCallable)
	void RotatePlatform()
	{
		bHit = true;
	}

	UFUNCTION(BlueprintCallable)
	void ResetPlatform()
	{
		bHit = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bHit)
		RotateComp.ApplyForce(ArrowComp.WorldLocation, ArrowComp.GetForwardVector() * 10);
	}

}
