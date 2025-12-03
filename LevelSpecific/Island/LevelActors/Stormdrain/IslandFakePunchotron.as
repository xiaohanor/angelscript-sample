class AIslandFakePunchotron : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandFakePunchotronForceFieldCapability");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldComponent ForceField;

	UPROPERTY()
	UAnimSequence IntroAnim;

	UPROPERTY()
	UAnimSequence Idle;

	float ForceFieldActivationDelay = 5;
	float ForceFieldActivationAlphaPerSecond = 0.4;
	bool bIsForceFieldActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// FHazePlaySlotAnimationParams Params;
		// Params.Animation = Idle;
		// Params.BlendTime = 0.5;
		// Params.bLoop = true;
		// SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
	}

	UFUNCTION()
	void PlayIntroAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = IntroAnim;
		Params.BlendTime = 0.5;
		Params.bLoop = false;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
		// bIsForceFieldActive = true;
	}

	UFUNCTION()
	void HideForcefield()
	{
		bIsForceFieldActive = false;
	}

};