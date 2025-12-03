UCLASS(Abstract)
class UAnimInstanceSerpentHead : UHazeCharacterAnimInstance
{
	ASerpentHead SerpentHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeRuntimeSpline Spline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HeadOffset = 3500.0;

	//USerpentHeadRuntimeSplineFollowComponent SplineFollow;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		
		SerpentHead = Cast<ASerpentHead>(HazeOwningActor);
		//SplineFollow = USerpentHeadRuntimeSplineFollowComponent::Get(SerpentHead);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SerpentHead == nullptr)
			return;

		//Spline = SplineFollow.RuntimeSpline;
		//LocationAlongSpline = SerpentHead.LocationAlongSpline;
		//HeadOffset = SplineFollow.HeadOffset;
	}


	// UFUNCTION(BlueprintOverride)
	// void BlueprintThreadSafeUpdateAnimation(float DeltaTime)
	// {
	// }
}