UCLASS(NotBlueprintable, HideCategories = "Debug ComponentTick Activation Cooking Disable Tags Navigation")
class USkylineBossFootStompComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	int NumOfProjectiles = 12;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AHazeActor> ProjectileClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineBossFootStompImpact> ImpactClass;

	ASkylineBoss Boss;

	private uint FootPlacedFrame = 0;
	ASkylineBossLeg PlacedLeg;

	private uint FootLiftedFrame = 0;
	ASkylineBossLeg LiftedLeg;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);

		Boss.OnFootPlaced.AddUFunction(this, n"HandleFootPlaced");
		Boss.OnTraversalBegin.AddUFunction(this, n"Reset");
		Boss.OnFootLifted.AddUFunction(this, n"HandleFootLifted");
	}



	UFUNCTION()
	private void Reset(ASkylineBossSplineHub FromHub, ASkylineBossSplineHub ToHub)
	{
		PlacedLeg = nullptr;
		LiftedLeg = nullptr;
	}

	UFUNCTION()
	private void HandleFootPlaced(ASkylineBossLeg Leg)
	{
		FootPlacedFrame = Time::FrameNumber;
		PlacedLeg = Leg;
	}

	UFUNCTION()
	private void HandleFootLifted(ASkylineBossLeg Leg)
	{
		FootLiftedFrame = Time::FrameNumber;
		LiftedLeg = Leg;
	}

	bool WasFootPlacedThisFrame() const
	{
		return FootPlacedFrame == Time::FrameNumber;
	}

	bool WasFootLiftedThisFrame() const
	{
		return FootLiftedFrame == Time::FrameNumber;
	}
};