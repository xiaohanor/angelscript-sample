class UScenepointAnimationComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Animations")
	UAnimSequence EntryAnimation;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Preview", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	UPROPERTY(EditInstanceOnly, Category = "Preview")
	TSubclassOf<AHazeActor> PreviewClass;

	bool bIsPreviewPlaying = true;
#endif
}