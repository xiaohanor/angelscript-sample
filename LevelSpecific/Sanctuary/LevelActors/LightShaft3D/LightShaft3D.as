

class ALightShaft3D : AHazeActor
{
	
    UPROPERTY(DefaultComponent)
	USceneCaptureComponentCube CaptureComponent;

    UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
    UPROPERTY(EditAnywhere)
	float Radius = 2000;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CaptureComponent.CaptureScene();
		Mesh.SetRelativeScale3D(FVector::OneVector * Radius * 0.01);
		SetActorScale3D(FVector::OneVector);
	}
}

