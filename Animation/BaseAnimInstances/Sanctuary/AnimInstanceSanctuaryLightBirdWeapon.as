class UAnimInstanceLightBirdWeapon : UHazeAnimInstanceBase
{
    // Animation sequences  
    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData AbsorbMh;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData AimMh;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Release;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Launch;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FlyMH;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HoverMh;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Illuminate;

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Recall;

    // Components
    ULightBirdUserComponent LightBirdComp;

	UHazePhysicalAnimationComponent PhysComp;

	UPROPERTY(BlueprintReadOnly)
	UHazePhysicalAnimationProfile PhysProfile;

    // Custom variables

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)    
    bool bIsAbsorbed;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)    
    bool bIsAiming;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)    
    bool bIsReleased;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)    
    bool bIsLaunching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsHovering;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsIlluminating;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsRecalling;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
		//PhysComp.ApplyProfileAsset(PhysProfile);
	}

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;
		
        LightBirdComp = ULightBirdUserComponent::Get(Game::GetMio());
        if (LightBirdComp == nullptr)
            return;

    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        if (LightBirdComp == nullptr)
            return;

        // auto LightBirdAnimData = LightBirdComp.AnimationData;

        bIsAiming = LightBirdComp.AnimationData.bIsAiming;
        bIsHovering = LightBirdComp.State == ELightBirdState::Hover;
        bIsIlluminating = LightBirdComp.IsIlluminating();

		// PhysComp.Disable(this);

		/*
		if (PhysComp != nullptr)
		{
			if (CheckValueChangedAndSetBool(bIsAbsorbed, LightBird.IsAbsorbed()))
			{
				if (bIsAbsorbed)
					PhysComp.Enable();
				else 
					PhysComp.Disable();
			}
		}
		*/
    }
    
}