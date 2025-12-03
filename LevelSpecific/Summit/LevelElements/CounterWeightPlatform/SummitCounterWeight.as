class ASummitCounterWeight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CableEnd;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 1.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AActor> ChainsToMoveUp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bChainDisablePlane = false;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = "bChainDisablePlane", EditConditionHides))
	float ChainDisablePlaneOffset = 4000.0;

	float UpForce = 4000.0;

	FVector StartLocation;
	FVector EndLocation;
	float MaxDistance;

	FHazeAcceleratedFloat AccelForce;

	bool bApplyForce;

	float ChainDisablePlaneHeight = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = TranslateComp.WorldLocation;
		EndLocation = TranslateComp.WorldLocation + FVector::UpVector * TranslateComp.MaxZ;
		MaxDistance = (EndLocation - StartLocation).Size();

		for(auto Chain : ChainsToMoveUp)
		{
			if(Chain != nullptr)
				Chain.AttachToComponent(TranslateComp, AttachmentRule = EAttachmentRule::KeepWorld);
		}

		ChainDisablePlaneHeight = ActorLocation.Z + ChainDisablePlaneOffset;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bApplyForce)
			AccelForce.AccelerateTo(UpForce, 2.0, DeltaSeconds);
		
		ForceComp.Force = FVector(0,0,AccelForce.Value);

		for(auto Chain : ChainsToMoveUp)
		{
			if(Chain.ActorLocation.Z > ChainDisablePlaneHeight)
				Chain.AddActorDisable(this);
		}
	}

	UFUNCTION()
	void StartForce()
	{
		bApplyForce = true;
	}

	float GetAlpha() const
	{
		float CurrentDistance = (TranslateComp.WorldLocation - EndLocation).Size();
		return Math::Clamp(CurrentDistance / MaxDistance, 0, 1);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if(bChainDisablePlane
		&& ChainsToMoveUp.Num() > 0)
		{
			FVector PlaneLocation = ActorLocation + FVector::UpVector * ChainDisablePlaneOffset; 
			FLinearColor DiskColor = FLinearColor::Purple;
			DiskColor.A = 0.7;
			Debug::DrawDebugSolidDisk(PlaneLocation, FVector::UpVector, 1000.0, DiskColor, bDrawInForeground = true);
			Debug::DrawDebugString(PlaneLocation, "Chain Disable Plane", FLinearColor::Purple);
		}
	}
#endif
};