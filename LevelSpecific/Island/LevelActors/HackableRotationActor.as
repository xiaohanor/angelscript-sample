class AHackableRotationActor: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	USceneComponent RotationComp;
	UPROPERTY(DefaultComponent, Attach = RotationComp)
	UStaticMeshComponent PlatformMesh;
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = false;
	default DisableComp.AutoDisableRange = 8000.0;

	FHazeAcceleratedRotator AcceleratedRotator;
	UPROPERTY(EditAnywhere)
	float RotationAdditionValue = 90;
	UPROPERTY(EditAnywhere)
	float ForwardStiffness = 10;
	UPROPERTY(EditAnywhere)
	float ForwardDampening = 0.8;
	FRotator TargetRotValue = FRotator(0,0,0);


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	

	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedRotator.SpringTo(TargetRotValue, ForwardStiffness, ForwardDampening, DeltaSeconds);
		RotationComp.SetRelativeRotation(AcceleratedRotator.Value);
	}

	UFUNCTION()
	void ActivateForward()
	{
		TargetRotValue =  RotationComp.GetRelativeRotation() + FRotator(0,RotationAdditionValue,0);
	}
}

