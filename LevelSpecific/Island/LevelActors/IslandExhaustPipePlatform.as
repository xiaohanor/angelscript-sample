event void FAIslandExhaustPipePlatformSignature();

class AIslandExhaustPipePlatform : AHazeActor
{
	
	UPROPERTY()
	FAIslandExhaustPipePlatformSignature OnImpact;
	UPROPERTY()
	FAIslandExhaustPipePlatformSignature OnActivated;
	UPROPERTY()
	FAIslandExhaustPipePlatformSignature OnReset;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LidRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PanelRef;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel SecondPanelRef;

	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponType BlockColor;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenLidTimeLike;

	TArray<UStaticMeshComponent> LidMeshes;
	float CurrentAlpha;
	AHazePlayerCharacter LastPlayerImpacter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PanelRef != nullptr)
		{
			PanelRef.OnOvercharged.AddUFunction(this, n"HandleOvercharge");
			PanelRef.OnReset.AddUFunction(this, n"HandleReset");
		}

		if (SecondPanelRef != nullptr)
		{
			SecondPanelRef.OnOvercharged.AddUFunction(this, n"HandleOvercharge");
			SecondPanelRef.OnReset.AddUFunction(this, n"HandleReset");
		}

		LidRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, LidMeshes);

		OpenLidTimeLike.BindUpdate(this, n"UpdateOpenLid");
		OpenLidTimeLike.BindFinished(this, n"FinishOpenLid");

		InitializeLid();

	}

	UFUNCTION()
	void InitializeLid()
	{
		for (UStaticMeshComponent MeshComp : LidMeshes)
		{
			FVector Loc = -MeshComp.RelativeRotation.RightVector * 125.0;
			MeshComp.SetRelativeLocation(Loc);
			FVector Scale = FVector(0.7, 1, 1);
			MeshComp.SetRelativeScale3D(Scale);
		}

		float Rot = 200;
		LidRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));
	}

	UFUNCTION()
	private void UpdateOpenLid(float CurrentValue)
	{
		for (UStaticMeshComponent MeshComp : LidMeshes)
		{
			FVector Loc = Math::Lerp(FVector::ZeroVector, -MeshComp.RelativeRotation.RightVector * 125.0, CurrentValue);
			MeshComp.SetRelativeLocation(Loc);
			FVector Scale = Math::Lerp(FVector::OneVector, FVector(0.7, 1, 1), CurrentValue);
			MeshComp.SetRelativeScale3D(Scale);
		}

		float Rot = Math::Lerp(0.0, 200, CurrentValue);
		LidRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));
	}

	UFUNCTION()
	private void FinishOpenLid()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	void HandleOvercharge()
	{
		// Activate
		OnActivated.Broadcast();
		OpenLidTimeLike.Reverse();
	}

	UFUNCTION()
	void HandleReset()
	{
		// Reset
		OnReset.Broadcast();
		OpenLidTimeLike.Play();
	}
}