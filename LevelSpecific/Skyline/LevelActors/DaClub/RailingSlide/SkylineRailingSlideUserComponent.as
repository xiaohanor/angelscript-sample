class USkylineRailingSlideUserComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence SlidingAnim;

	TArray<USkylineRailingSlideComponent> RailingSlides;
	USkylineRailingSlideComponent RailingSlide;

	bool bIsSliding = false;
	float RailingSnapRange = 100.0;
	float SlideSpeed = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};