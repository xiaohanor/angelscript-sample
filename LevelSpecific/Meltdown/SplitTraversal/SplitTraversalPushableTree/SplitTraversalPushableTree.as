class ASplitTraversalPushableTree : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FantasyRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SciFiRoot;

	UPROPERTY()
	FHazeTimeLike PushingTreeTimeLike;
	default PushingTreeTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	UPROPERTY(EditAnywhere)
	float Scale = 1.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FantasyRoot.SetRelativeScale3D(FVector(Scale));
		
		if (CameraActor != nullptr)
		{
			FVector Offset = (SciFiRoot.WorldLocation - CameraActor.ActorLocation) * Scale;

			FantasyRoot.SetWorldLocation(CameraActor.ActorLocation + FVector::ForwardVector * -500000.0 + Offset);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PushingTreeTimeLike.BindUpdate(this, n"PushingTreeTimeLikeUpdate");
	}

	UFUNCTION()
	private void PushingTreeTimeLikeUpdate(float CurrentValue)
	{
		FRotator Rotation = FRotator(Math::Lerp(0.0, 90.0, CurrentValue), 0.0, 0.0);
		FantasyRoot.SetRelativeRotation(Rotation);
		SciFiRoot.SetRelativeRotation(Rotation);
	}

	UFUNCTION()
	void Activate()
	{
		PushingTreeTimeLike.Play();
	}
};