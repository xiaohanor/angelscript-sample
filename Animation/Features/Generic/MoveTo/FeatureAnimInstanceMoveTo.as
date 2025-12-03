UCLASS(Abstract)
class UFeatureAnimInstanceMoveTo : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureMoveTo Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureMoveToAnimData AnimData;

	// Add Custom Variables Here

	//The angle from the player character's forward to the interact point. -180 is 180 to the left, 0 is straight ahead from the player, 180 is 180 degrees to the player's right
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float AngleToInteractPosition;

	//The angle difference between the player character's forward and the forward of the interact point. -180 is 180 to the left, 0 is straight ahead from the player, 180 is 180 degrees to the player's right
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AngleToInteractFwd;

	//The distance in units between the player and the interact point
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DistanceToInteract;

	// Whether the move to was started while the player was airborne
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedAirborne;

	// How long the move to was determined to take
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Duration;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PlayRateMultiplier;


	private UMoveToComponent MoveToComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		
		MoveToComp = UMoveToComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureMoveTo NewFeature = GetFeatureAsClass(ULocomotionFeatureMoveTo);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.03;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		AngleToInteractPosition = MoveToComp.AnimAngleToInteractPosition;
		AngleToInteractFwd = MoveToComp.AnimAngleToInteractFwd;
		DistanceToInteract = MoveToComp.AnimDistanceToInteract;
		bStartedAirborne = MoveToComp.bAnimStartedAirborne;
		Duration = MoveToComp.AnimDuration;

		PlayRateMultiplier = 0.6/(Duration);
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (TopLevelGraphRelevantAnimTimeFraction >= 0.55)
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
