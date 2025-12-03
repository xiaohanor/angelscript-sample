UCLASS(Abstract)
class AGoatDevourTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TargetRoot;

	UPROPERTY(DefaultComponent, Attach = TargetRoot)
	UGoatDevourAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UGoatDevourSpitImpactResponseComponent DevourSpitResponseComp;

	UPROPERTY(DefaultComponent, Attach = TargetRoot)
	UGoatLaserEyesAutoAimComponent LaserEyesAutoAimComp;

	UPROPERTY(DefaultComponent)
	UGoatLaserEyesResponseComponent LaserEyesComp;

	UPROPERTY(EditAnywhere)
	TArray<AActor> TargetPoints;

	float Size = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DevourSpitResponseComp.OnImpact.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(AHazeActor OwningActor, FHitResult HitResult)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TargetSize = LaserEyesComp.bLasered ? 1.5 : 0.5;
		Size = Math::FInterpConstantTo(Size, TargetSize, DeltaTime, 1.0);
		TargetRoot.SetRelativeScale3D(FVector(1.0, Size, Size));
	}
}