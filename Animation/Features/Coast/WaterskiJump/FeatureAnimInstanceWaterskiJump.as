UCLASS(Abstract)
class UFeatureAnimInstanceWaterskiJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWaterskiJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWaterskiJumpAnimData AnimData;

	// Add Custom Variables Here
	
	UPlayerMovementComponent MoveComponent;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UCoastWaterskiPlayerComponent WakeboardComp;  

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsChargeJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UAnimSequence CurrentTrickAnimation;

	float AirTime;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
		WakeboardComp = UCoastWaterskiPlayerComponent::GetOrCreate(Player);
		MoveComponent =  UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWaterskiJump NewFeature = GetFeatureAsClass(ULocomotionFeatureWaterskiJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		AirTime = 0;

		const FVector MovementInputActorSpace = Player.GetActorRotation().UnrotateVector(MoveComponent.SyncedMovementInputForAnimationOnly);
		BlendspaceValues.X = MovementInputActorSpace.Y;

		CurrentTrickAnimation = Feature.AnimData.Tricks.GetAnimationFromIndex(WakeboardComp.AnimData.JumpTrickIndex);
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

		//bIsChargeJump = WakeboardComp.bIsChargingForJump;
		if (!bIsChargeJump)
			AirTime += DeltaTime;
		
		const FVector MovementInputActorSpace = MoveComponent.GetSyncedLocalSpaceMovementInputForAnimationOnly();
		BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X, MovementInputActorSpace.Y, DeltaTime, 5.5);

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.6);

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"WaterskiAirMovement")
			return true;

		return TopLevelGraphRelevantStateName == n"Tricks" && IsLowestLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"WaterskiAirMovement")
			SetAnimFloatParam(n"WaterSkiAirTime", AirTime);
	}
}
