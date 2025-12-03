UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyWallClimb : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyWallClimb Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyWallClimbAnimData AnimData;

	UPROPERTY(BlueprintReadOnly)
	FVector2D LocalVelocity = FVector2D::ZeroVector;
	
	UHazeMovementComponent MoveComp;
	
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyWallClimb NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyWallClimb);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		FVector Velocity = MoveComp.GetVelocity();
		Velocity = MoveComp.Owner.ActorRotation.UnrotateVector(Velocity);
		LocalVelocity.X = Velocity.Y;
		LocalVelocity.Y = Velocity.Z;
		LocalVelocity.Normalize();
		PrintToScreen("Vel: " + LocalVelocity);
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
