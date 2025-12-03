UCLASS(Abstract)
class ALiftSectionElectricalProjectileOn : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFX;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;
	default SetActorHiddenInGame(true);

	UPROPERTY(EditAnywhere)
	ASplineActor SplineToFollow;

	UPROPERTY()
	float DistanceAlongSpline = 0.0;
	UPROPERTY(EditAnywhere)
	float CurrentFollowSpeed = 10000;
	UPROPERTY(EditAnywhere)
	float DesiredFollowSpeed = 10000;

	bool bFollowingSpline = false;
	bool bSetRotation = true;
	float AccelerationMulitplier;
	float TimerDeactivation = 8;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bFollowingSpline == false)
			return;

		CurrentFollowSpeed = Math::FInterpTo(CurrentFollowSpeed, DesiredFollowSpeed, DeltaTime * AccelerationMulitplier, 1.0);
		DistanceAlongSpline += CurrentFollowSpeed * DeltaTime;

		FVector Loc = SplineToFollow.Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
		FQuat Rot = SplineToFollow.Spline.GetWorldRotationAtSplineDistance(DistanceAlongSpline);

	//	FVector Loc = SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		//FRotator Rot = SplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocation(Loc);
		if (bSetRotation)
			SetActorRotation(Rot);


		if(DistanceAlongSpline >= SplineToFollow.Spline.GetSplineLength())
		{
			TimerDeactivation -= DeltaTime;
			if(TimerDeactivation <= 0)
			{
				DeactivateProjectile();
			}
		}
	}

	UFUNCTION()
	void ActivateProjectile()
	{
		bFollowingSpline = true;
		SetActorHiddenInGame(false);
	}
	void DeactivateProjectile()
	{
		bFollowingSpline = false;
		DestroyActor();
	}
}