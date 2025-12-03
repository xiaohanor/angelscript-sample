UCLASS(Abstract)
class UFeatureAnimInstanceFantasyFairyCrawl : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFantasyFairyCrawl Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFantasyFairyCrawlAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CurrentNormalizedSpeed = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsExiting = false;

	UTundraPlayerFairyCrawlComponent CrawlPlayerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		auto ParentPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		MoveComp = UPlayerMovementComponent::Get(ParentPlayer);
		CrawlPlayerComp = UTundraPlayerFairyCrawlComponent::GetOrCreate(ParentPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFantasyFairyCrawl NewFeature = GetFeatureAsClass(ULocomotionFeatureFantasyFairyCrawl);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (HazeOwningActor == nullptr)
			return;

		bIsExiting = CrawlPlayerComp.AnimData.bIsExitingCrawl;
		CurrentNormalizedSpeed = MoveComp.HorizontalVelocity.Size() / 110.0;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
