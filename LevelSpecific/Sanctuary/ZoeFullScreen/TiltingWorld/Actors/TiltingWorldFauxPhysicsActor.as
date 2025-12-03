class ATiltingWorldFauxPhysicsActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    UFauxPhysicsConeRotateComponent FauxConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = "FauxConeRotateComp")
    UFauxPhysicsWeightComponent FauxWeightComp;
	default FauxWeightComp.RelativeLocation = FVector(0, 0, -500);

	UPROPERTY(DefaultComponent)
    UTiltingWorldResponseComponent TiltingWorldResponseComp;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FRotator Rotation = GetActorRotation();
		Rotation.Pitch = 0.0;
		Rotation.Roll = 0.0;
		SetActorRotation(Rotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetActorRotation(FauxConeRotateComp.CurrentRotation);
	}
}