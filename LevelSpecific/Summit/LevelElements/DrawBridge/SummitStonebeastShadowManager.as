class ASummitStonebeastShadowManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(4));
	default Visual.SpriteName = "S_TriggerSphere";
#endif

	UPROPERTY(EditInstanceOnly)
	AActor Shadow;

	UPROPERTY(EditInstanceOnly)
	float Speed = 12000.0; 

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditInstanceOnly)
	float TestDistance = 0;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UHazeSplineComponent Spline;
	
	float Distance;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Spline = SplineActor.Spline;
		Shadow.ActorLocation = Spline.GetWorldLocationAtSplineDistance(TestDistance);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.Spline;
		SetActorTickEnabled(false);
	}

	UFUNCTION(CallInEditor)
	void SetShadowLocation()
	{
		Spline = SplineActor.Spline;
		Shadow.ActorLocation = Spline.GetWorldLocationAtSplineDistance(TestDistance);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Distance += Speed * DeltaSeconds;
		Shadow.ActorLocation = Spline.GetWorldLocationAtSplineDistance(Distance);

		if (Distance > Spline.SplineLength)
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void StartShadowMove()
	{
		Distance = 0;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void PlayShadowCameraShake()
	{
		Game::Zoe.PlayCameraShake(CameraShake, this, 0.5);
	}
};