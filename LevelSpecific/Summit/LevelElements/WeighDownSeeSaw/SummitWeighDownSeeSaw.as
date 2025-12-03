class ASummitWeighDownSeeSaw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent LeftPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent RightPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = RightPlatformRoot)
	USceneComponent TargetRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StoneLandImpulseSize = 100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StoneAttachedForce = 500.0;

	bool bStoneIsAttached = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto LeftRotation = LeftPlatformRoot.WorldRotation;
		LeftPlatformRoot.SetAbsolute(false, true, false);
		LeftPlatformRoot.WorldRotation = LeftRotation;

		auto RightRotation = RightPlatformRoot.WorldRotation;
		RightPlatformRoot.SetAbsolute(false, true, false);
		RightPlatformRoot.WorldRotation = RightRotation;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(TargetRoot.WorldLocation, 450, 12, FLinearColor::White, 20, 0.0);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStoneIsAttached)
		{
			FauxPhysics::ApplyFauxForceToActorAt(this, RightPlatformRoot.WorldLocation, -RightPlatformRoot.UpVector * StoneAttachedForce);
		}
	}

	void GetHitByStone(FVector ImpactLocation)
	{
		FauxPhysics::ApplyFauxImpulseToActorAt(this, ImpactLocation, -RightPlatformRoot.UpVector * StoneLandImpulseSize);
	}
};