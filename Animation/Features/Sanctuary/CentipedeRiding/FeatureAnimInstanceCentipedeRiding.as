UCLASS(Abstract)
class UFeatureAnimInstanceCentipedeRiding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCentipedeRiding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCentipedeRidingAnimData AnimData;

	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TurnRate;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureCentipedeRiding NewFeature = GetFeatureAsClass(ULocomotionFeatureCentipedeRiding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::GetOrCreate(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Velocity = FVector2D(Player.GetActorLocalVelocity().Y, Player.GetActorLocalVelocity().X);
		Speed = Velocity.Size();
		TurnRate = MoveComp.GetMovementYawVelocity(false) / 230.0;
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
