UCLASS(Abstract)
class ATundra_MonkeyHatch_FloorHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HatchRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	USceneComponent LeftHatchRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	USceneComponent RightHatchRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	USceneComponent MiddleHatchRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	USceneComponent OtherMiddleHatchRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MonkeyRoot;
	
	// UPROPERTY(DefaultComponent, Attach = MonkeyRoot)
	// UHazeSkeletalMeshComponentBase MonkeyMeshComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TL_HatchOpen;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TL_HatchClose;

	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatchSlamPlatform SlamPlatform;

	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatchDrum Drum;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> ActorsToDisable;

	UPROPERTY(EditInstanceOnly)
	bool bReversed = false;

	bool bIsOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TL_HatchClose.BindUpdate(this, n"TL_HatchClose_Update");
		TL_HatchClose.BindFinished(this, n"TL_HatchClose_Finished");
		TL_HatchOpen.BindUpdate(this, n"TL_HatchOpen_Update");
		TL_HatchOpen.BindFinished(this, n"TL_HatchOpen_Finished");

		if(SlamPlatform != nullptr)
		{
			// SlamPlatform.OnGroundSlammed.AddUFunction(this, n"OnPlatformSlammed");
			// SlamPlatform.OnRecovered.AddUFunction(this, n"OnPlatformRecovered");
		}

		if(Drum != nullptr)
		{
			Drum.OnDrumHit.AddUFunction(this, n"OnDrumHit");
		}

		if(bReversed)
		{
			TryOpenHatch();
		}
	}

	UFUNCTION()
	private void OnDrumHit()
	{
		TryOpenHatch();
	}

	UFUNCTION()
	private void OnPlatformRecovered()
	{
		if(bReversed)
		{
			TryOpenHatch();
		}
		else
		{
			TryCloseHatch();
		}
	}

	UFUNCTION()
	private void OnPlatformSlammed()
	{
		if(bReversed)
		{
			TryCloseHatch();
		}
		else
		{
			TryOpenHatch();
		}
	}

	UFUNCTION()
	private void TryCloseHatch()
	{
		if(!bIsOpen)
			return;

		TL_HatchClose.PlayFromStart();
	}

	UFUNCTION()
	void TryOpenHatch()
	{
		if(bIsOpen)
			return;

		TL_HatchOpen.PlayFromStart();
	
		bIsOpen = true;

		for(auto Actor : ActorsToDisable)
		{
			if(Actor != nullptr)
				Actor.AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void TL_HatchOpen_Finished()
	{
	}

	UFUNCTION()
	private void TL_HatchOpen_Update(float CurrentValue)
	{
		LeftHatchRoot.RelativeRotation = FRotator(Math::Lerp(0, -80, CurrentValue), 0, 0);
		RightHatchRoot.RelativeRotation = FRotator(Math::Lerp(0, 80, CurrentValue), 0, 0);
		MiddleHatchRoot.RelativeRotation = FRotator(0, 0, Math::Lerp(0, -80, CurrentValue));
		OtherMiddleHatchRoot.RelativeRotation = FRotator(0, 0, Math::Lerp(0, 80, CurrentValue));
	}

	UFUNCTION()
	private void TL_HatchClose_Finished()
	{
		bIsOpen = false;
	}

	UFUNCTION()
	private void TL_HatchClose_Update(float CurrentValue)
	{
		LeftHatchRoot.RelativeRotation = FRotator(Math::Lerp(-80, 0, CurrentValue), 0, 0);
		RightHatchRoot.RelativeRotation = FRotator(Math::Lerp(80, 0, CurrentValue), 0, 0);
		MiddleHatchRoot.RelativeRotation = FRotator(0, 0, Math::Lerp(-80, 0, CurrentValue));
		OtherMiddleHatchRoot.RelativeRotation = FRotator(0, 0, Math::Lerp(80, 0, CurrentValue));
	}
};
