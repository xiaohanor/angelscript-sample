UCLASS(Abstract)
class UFeatureAnimInstanceWaterskiLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWaterskiLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWaterskiLandingAnimData AnimData;

	// Add Custom Variables Here
	UCoastWaterskiPlayerComponent WakeboardComp;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerMovementComponent MoveComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipLanding;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
		WakeboardComp = UCoastWaterskiPlayerComponent::Get(Player);
		MoveComponent =  UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWaterskiLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureWaterskiLanding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;
		
		const float AirTime = GetAnimFloatParam(n"WaterSkiAirTime", true);
		
		BlendspaceValues.Y =  (AirTime - 0.2) / 1.3;
		bSkipLanding = AirTime < 0.1;

		const FVector MovementInputActorSpace = Player.GetActorRotation().UnrotateVector(MoveComponent.SyncedMovementInputForAnimationOnly);
		BlendspaceValues.X = MovementInputActorSpace.Y;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		const FVector MovementInputActorSpace = MoveComponent.GetSyncedLocalSpaceMovementInputForAnimationOnly();
		BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X, MovementInputActorSpace.Y, DeltaTime, 5.5);

		// Implement Custom Stuff Here
		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (bSkipLanding)
			return true;

		if (LocomotionAnimationTag != n"Waterski" && LocomotionAnimationTag != n"WaterskiAirMovement")
			return true;

		return TopLevelGraphRelevantStateName == n"Landing" && IsLowestLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
