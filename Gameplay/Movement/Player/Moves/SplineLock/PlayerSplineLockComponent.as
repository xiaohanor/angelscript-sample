class UPlayerSplineLockComponent : USplineLockComponent
{
	access SplineZone = private, UPlayerSplineLockBestSplinePickerCapability, UTundraPlayerSplineLockReleaseByInputCapability, APlayerSplineLockZone, ATundraConditionalPlayerSplineLockZone;

	default ResolverExtensionClass = UPlayerSplineLockResolverExtension;

	private AHazePlayerCharacter Player;

	access:SplineZone
	TArray<APlayerSplineLockZone> ActiveSplineZones;

	access:SplineZone
	APlayerSplineLockZone CurrentSplineZone;

	access:SplineZone
	bool bForceUpdateSplineZoneWithPosition = false;

	access:SplineZone
	FVector SplineZoneUpdatePosition = FVector::ZeroVector;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UHazeOffsetComponent GetMeshOffsetComponent() const override
	{
		return Player.MeshOffsetComponent;
	}

	access:SplineZone
	void ActivateSplineZone(APlayerSplineLockZone SplineZone)
	{
		ActiveSplineZones.Add(SplineZone);
	}

	access:SplineZone
	void DeactivateSplineZone(APlayerSplineLockZone SplineZone)
	{
		for(int i = ActiveSplineZones.Num() - 1; i >= 0; --i)
		{
			if(ActiveSplineZones[i] == SplineZone)
			{
				// Keep the order
				ActiveSplineZones.RemoveAt(i);
				break;
			}
		}
	}

	APlayerSplineLockZone GetCurrentSplineZone() const
	{
		return CurrentSplineZone;
	}
}
