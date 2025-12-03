class ASummitStoneChainManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;
	default Root.WorldScale3D = FVector(10, 10, 10);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> ChainActors;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor ActorToAttachTo;

	UPROPERTY(EditInstanceOnly, Category = "Setup", Meta = (GetOptions = "GetComponentNames", EditCondition = "ActorToAttachTo != nullptr", EditConditionHides))
	FName ComponentNameToAttachTo;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bUpperDisablePlane = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bUpperDisablePlane", EditConditionHides))
	float UpperDisablePlaneOffset = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bLowerDisablePlane = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bLowerDisablePlane", EditConditionHides))
	float LowerDisablePlaneOffset = 3000.0;

	float LowerPlaneHeight;
	float UpperPlaneHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(ActorToAttachTo != nullptr)
		{
			USceneComponent AttachComponent = ActorToAttachTo.GetComponent(USceneComponent, ComponentNameToAttachTo);
			if(AttachComponent != nullptr)
			{
				for(auto Chain : ChainActors)
				{
					Chain.AttachToComponent(AttachComponent, AttachmentRule = EAttachmentRule::KeepWorld);
				}
			}
		}
		UpperPlaneHeight = ActorLocation.Z + UpperDisablePlaneOffset;
		LowerPlaneHeight = ActorLocation.Z - LowerDisablePlaneOffset;

		DisableChainsIfOutsidePlanes();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DisableChainsIfOutsidePlanes();
	}

	void DisableChainsIfOutsidePlanes()
	{
		for(auto Chain : ChainActors)
		{
			bool bShouldBeActive = true;
			if(bUpperDisablePlane)
			{
				if(Chain.ActorLocation.Z > UpperPlaneHeight)
					bShouldBeActive = false;
			}
			if(bLowerDisablePlane)
			{
				if(Chain.ActorLocation.Z < LowerPlaneHeight)
					bShouldBeActive = false;
			}

			if(!bShouldBeActive)
				Chain.AddActorDisable(this);
			else
				Chain.RemoveActorDisable(this);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if(bUpperDisablePlane)
		{
			FVector PlaneLocation = ActorLocation + FVector::UpVector * UpperDisablePlaneOffset; 
			FLinearColor DiskColor = FLinearColor::White;
			DiskColor.A = 0.7;
			Debug::DrawDebugSolidDisk(PlaneLocation, FVector::UpVector, 1000.0, DiskColor, bDrawInForeground = true);
			Debug::DrawDebugString(PlaneLocation, "Upper Chain Disable Plane", FLinearColor::White);
		}

		if(bLowerDisablePlane)
		{
			FVector PlaneLocation = ActorLocation + FVector::DownVector * LowerDisablePlaneOffset; 
			FLinearColor DiskColor = FLinearColor::Black;
			DiskColor.A = 0.7;
			Debug::DrawDebugSolidDisk(PlaneLocation, FVector::UpVector, 1000.0, DiskColor, bDrawInForeground = true);
			Debug::DrawDebugString(PlaneLocation, "Lower Chain Disable Plane", FLinearColor::Black);
		}
	}

	UFUNCTION()
	private TArray<FName> GetComponentNames() const
	{
		return Editor::GetAllEditorComponentNamesOfClass(ActorToAttachTo, USceneComponent);
	}
#endif
};