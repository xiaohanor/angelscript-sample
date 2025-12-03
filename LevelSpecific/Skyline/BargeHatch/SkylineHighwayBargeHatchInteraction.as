class ASkylineHighwayBargeHatchInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(2.0);
#endif
	
	UPROPERTY(EditAnywhere)
	UAnimSequence MioWaitAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence ZoeWaitAnim;

	UFUNCTION()
	void Start()
	{
		FHazePlaySlotAnimationParams MioParams;
		MioParams.Animation = MioWaitAnim;
		Game::GetMio().PlaySlotAnimation(MioParams);

		FHazePlaySlotAnimationParams ZoeParams;
		ZoeParams.Animation = ZoeWaitAnim;
		Game::GetZoe().PlaySlotAnimation(ZoeParams);
	}
}