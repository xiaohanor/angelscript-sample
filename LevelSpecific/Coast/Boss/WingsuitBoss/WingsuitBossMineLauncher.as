class UWingsuitBossMineLauncher : UStaticMeshComponent
{
	access EditDefaults = private, * (editdefaults);

	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default RelativeRotation = FRotator(0.0, 0.0, 0.0);
	default RelativeScale3D = FVector(0.7, 0.7, 0.7);
	default CollisionProfileName = n"NoCollision";

	/* The location of this component relative to its parent transform when retracted */
	UPROPERTY(EditAnywhere)
	access:EditDefaults FVector RelativeRetractedLocation = FVector(0.0, 0.0, 43.917444);

	/* The location of this component relative to its parent transform when extended */
	UPROPERTY(EditAnywhere)
	access:EditDefaults FVector RelativeExtendedLocation = FVector(0.0, 0.0, -282.518579);

	/* Where the mine will spawn relative to this components transform */
	UPROPERTY(EditAnywhere)
	access:EditDefaults FVector ShootRelativeLocation = FVector(0.0, 0.0, 0.0);

#if EDITOR
	UPROPERTY(EditAnywhere)
	bool bEditorPreviewExtended = false;
#endif

	FHazeAcceleratedVector AcceleratedRelativeLocation;
	FVector TargetLocation;

	const float MoveDuration = 1.0;

	private TArray<FInstigator> ExtendInstigators;
	private bool bIsExtending = false;
	private bool bIsExtended = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bEditorPreviewExtended)
			RelativeLocation = RelativeExtendedLocation;
		else
			RelativeLocation = RelativeRetractedLocation;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RelativeLocation = RelativeRetractedLocation;
		AcceleratedRelativeLocation.SnapTo(RelativeLocation);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector Location = AcceleratedRelativeLocation.AccelerateToWithStop(TargetLocation, MoveDuration, DeltaTime, 0.01);
		RelativeLocation = Location;
		if(Location.Equals(TargetLocation))
		{
			SetComponentTickEnabled(false);
			bIsExtended = bIsExtending;
		}
	}

	UFUNCTION()
	void Retract(FInstigator Instigator)
	{
		bool bInstigatorsWasEmpty = ExtendInstigators.Num() == 0;
		ExtendInstigators.RemoveSingleSwap(Instigator);
		if(ExtendInstigators.Num() == 0 && !bInstigatorsWasEmpty)
		{
			SetComponentTickEnabled(true);
			TargetLocation = RelativeRetractedLocation;
			bIsExtending = false;
		}
	}

	UFUNCTION()
	void Extend(FInstigator Instigator)
	{
		bool bInstigatorsWasEmpty = ExtendInstigators.Num() == 0;
		ExtendInstigators.AddUnique(Instigator);
		if(ExtendInstigators.Num() > 0 && bInstigatorsWasEmpty)
		{
			SetComponentTickEnabled(true);
			TargetLocation = RelativeExtendedLocation;
			bIsExtending = true;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsExtended()
	{
		return bIsExtended;
	}

	UFUNCTION(BlueprintPure)
	FVector GetShootLocation() const property
	{
		return WorldTransform.TransformPosition(ShootRelativeLocation);
	}

	UFUNCTION(BlueprintPure)
	FRotator GetShootRotation() const property
	{
		return WorldRotation;
	}
}

#if EDITOR
class UWingsuitBossMineLauncherVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UWingsuitBossMineLauncher;
	
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Launcher = Cast<UWingsuitBossMineLauncher>(Component);
		SetHitProxy(n"ShootPoint", EVisualizerCursor::Hand);
		DrawPoint(Launcher.ShootLocation, FLinearColor::Red, 30.0);
		DrawWorldString("Mine Shoot Location", Launcher.ShootLocation, FLinearColor::Red, bCenterText = true);
		ClearHitProxy();
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if(HitProxy != n"ShootPoint")
			return false;
		
		Editor::SelectComponent(EditingComponent);
		return true;
	}
}
#endif