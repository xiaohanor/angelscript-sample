class ACongaLineMonkeyKing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BongoMH;

	ACongaLineManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Manager = CongaLine::GetManager();
		
	}

	UFUNCTION()
	void PlayBongoAnim()
	{
		FHazeSlotAnimSettings AnimSettings;
		AnimSettings.BlendTime = 1;
		AnimSettings.bLoop = true;
		PlaySlotAnimation(BongoMH, AnimSettings);
	}
};