class ASplitTraversalTempIntroCutsceneManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase RaderSkeletalMesh;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams StumbleAnim;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams RaderAttackAnim;

	UPROPERTY(EditAnywhere)
	float DelayAfterAnimation = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void Activate()
	{
		Timer::SetTimer(this, n"DelayedActivation", DelayAfterAnimation);
		RaderSkeletalMesh.PlaySlotAnimation(RaderAttackAnim);
	}

	UFUNCTION()
	private void DelayedActivation()
	{
		FadeFullscreenToColor(this, FLinearColor::White, 0.2, 0.5, 0.2);
		//Stumble();
		//Timer::SetTimer(this, n"Stumble", 0.5);
	}

	UFUNCTION()
	private void Stumble()
	{
		Game::Zoe.PlaySlotAnimation(StumbleAnim);
		Game::Mio.PlaySlotAnimation(StumbleAnim);
	}
};