class ASkylineGravityBikeElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;
	default ArrowComp.bHiddenInGame = true;

	UPROPERTY(EditAnywhere)
	float Speed = 1000.0;

	UPROPERTY(EditInstanceOnly)
	bool bStartUpwards = false;

	FVector Direction = FVector::DownVector;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bStartUpwards)
			ArrowComp.RelativeRotation = FVector::UpVector.Rotation();
		else
			ArrowComp.RelativeRotation = FVector::DownVector.Rotation();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		if (bStartUpwards)
			Direction = FVector::UpVector;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldOffset(Direction * Speed * DeltaSeconds);
	}

	UFUNCTION()
	void Activate()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void Deactivate()
	{
		SetActorTickEnabled(false);
	}
};