UCLASS(Abstract)
class AGuideKite : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent KiteRoot;

	UPROPERTY(DefaultComponent, Attach = KiteRoot)
	UNiagaraComponent TrailEffectComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FlySplineActor;
	UHazeSplineComponent SplineComp;

	bool bFlying = false;

	float SplineDist = 0.0;

	UPROPERTY(EditAnywhere)
	float FlySpeed = 4000.0;
	
	bool bDisablePending = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(FlySplineActor);
	}

	UFUNCTION()
	void FlyAway()
	{
		TrailEffectComp.Activate(true);
		bFlying = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDisablePending)
			return;

		if (bFlying)
		{
			float Time = Time::GameTimeSeconds;
			float Roll = Math::DegreesToRadians(Math::Sin(Time * 10.0) * 2.5);
			float Pitch = Math::DegreesToRadians(Math::Cos(Time * 5.0) * 3.0);
			FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);

			KiteRoot.SetRelativeRotation(Rotation);

			SplineDist += FlySpeed * DeltaTime;
			FVector Loc = SplineComp.GetWorldLocationAtSplineDistance(SplineDist);
			FRotator Rot = SplineComp.GetWorldRotationAtSplineDistance(SplineDist).Rotator();
			SetActorLocationAndRotation(Loc, Rot);

			if (SplineDist >= SplineComp.SplineLength)
			{
				bDisablePending = true;
				Timer::SetTimer(this, n"Disable", 2.0);
			}
		}
	}

	UFUNCTION()
	private void Disable()
	{
		AddActorDisable(this);
	}
}