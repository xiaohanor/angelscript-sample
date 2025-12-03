UCLASS(Abstract)
class UFeatureAnimInstanceWindWalk : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWindWalk Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWindWalkAnimData AnimData;

	// Add Custom Variables Here

	UWindWalkComponent WindWalkComp;
	UPlayerMovementComponent MoveComp;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FWindWalkAnimationData WindWalkAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ForwardFactor;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RightFactor;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PlayRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FVector MovementInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FVector WindDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float Speed;

	FHazeAcceleratedFloat AccForwardFactor;
	FHazeAcceleratedFloat AccRightFactor;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWindWalk NewFeature = GetFeatureAsClass(ULocomotionFeatureWindWalk);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
		WindWalkComp = UWindWalkComponent::GetOrCreate(Player);
		WindWalkAnimData = WindWalkComp.AnimationData;
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		AccForwardFactor.AccelerateTo(WindWalkComp.AnimationData.ForwardFactor, 1.0, DeltaTime);
		ForwardFactor = AccForwardFactor.Value;
		Print("ForwardFactor: " + ForwardFactor, 0.f);

		AccRightFactor.AccelerateTo(WindWalkComp.AnimationData.RightFactor, 1.0, DeltaTime);
		RightFactor = AccRightFactor.Value;
		Print("RightFactor: " + RightFactor, 0.f);

		PlayRate = WindWalkComp.AnimationData.PlayRate;
		Print("PlayRate: " + PlayRate, 0.f);

		Velocity = WindWalkComp.AnimationData.HorizontalVelocity;
		Print("Velocity: " + Velocity.ToString(), 0.f);

		MovementInput = WindWalkComp.AnimationData.MovementInput;
		Print("MovementInput: " + MovementInput.ToString(), 0.f);

		WindDirection = WindWalkComp.AnimationData.WindDirection;
		Print("WindDirection: " + WindDirection.ToString(), 0.f);

		Speed = WindWalkComp.AnimationData.Speed;
		Print("Speed: " + Speed, 0.f);
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
