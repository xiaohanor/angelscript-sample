class AMeltdownWorldSpinSandActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent EndLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Sand;

	UPROPERTY(EditAnywhere)
	AHazeNiagaraActor Water;

	UPROPERTY()
	bool bCanFill;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	FVector StartSand;
	FVector EndSand;

	UPROPERTY()
	FHazeTimeLike SandMove;
	default SandMove.Duration = 5.0;
	default SandMove.UseSmoothCurveZeroToOne();

	UPROPERTY()
	AMeltdownWorldSpinManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartSand = Sand.RelativeLocation;
		EndSand = EndLocation.RelativeLocation;

		SandMove.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Sand.SetRelativeLocation(Math::Lerp(StartSand,EndSand,CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Manager == nullptr)
			Manager = AMeltdownWorldSpinManager::GetWorldSpinManager();
		if (Manager == nullptr)
			return;
        
		const FVector GravityDir = -Manager.WorldSpinRotation.UpVector;

		if(GravityDir.Y >= 0.3 && bCanFill == true)
		FillSand();
		else
		StopSand();

		
	}

	UFUNCTION(BlueprintEvent)
	void FillSand()
	{
	
	}

	UFUNCTION(BlueprintEvent)
	void StopSand()
	{
	
	}
};