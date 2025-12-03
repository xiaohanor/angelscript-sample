UCLASS(Abstract)
class UFeatureAnimInstanceWaterskiAirMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWaterskiAirMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWaterskiAirMovementAnimData AnimData;

	// Add Custom Variables Here
	UPlayerMovementComponent MoveComponent;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AirTime = 0;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		MoveComponent =  UPlayerMovementComponent::Get(Player);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWaterskiAirMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureWaterskiAirMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		SlopeAlignComp.ResetInterpVelocity();

		AirTime = GetAnimFloatParam(n"WaterSkiAirTime");
	
		const FVector MovementInputActorSpace = Player.GetActorRotation().UnrotateVector(MoveComponent.SyncedMovementInputForAnimationOnly);
		BlendspaceValues.X = MovementInputActorSpace.Y;
	}


	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (PrevLocomotionAnimationTag == n"Waterski")
			return 0.5;

		return 0.2;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		const FVector MovementInputActorSpace = Player.GetActorRotation().UnrotateVector(MoveComponent.SyncedMovementInputForAnimationOnly);
		BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X, MovementInputActorSpace.Y, DeltaTime, 5.5);

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 4);

		AirTime += DeltaTime;
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		if (LocomotionAnimationTag == n"WaterskiLanding")
			SetAnimFloatParam(n"WaterSkiAirTime", AirTime);
	}
}
