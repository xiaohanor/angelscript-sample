UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyGroundSlam : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyGroundSlam Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyGroundSlamAnimData AnimData;

	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UTundraPlayerSnowMonkeySettings SnowMonkeySettings;

	UHazeMovementComponent MoveComp;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UAnimFootTraceComponent FootTraceComp;
	UPlayerFloorMotionComponent FloorMoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FHazeSlopeWarpingData SlopeWarpData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	float SlopeAlignAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrounded;

	/* Added this because the grounded state would sometimes change before animation would run which would make the animation snap weirdly // Oliver */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCurrentGroundSlamTypeIsGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float GroundedGroundSlamPlayRate = 1.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalVelocity;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp.MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
		FloorMoveComp = UPlayerFloorMotionComponent::GetOrCreate(HazeOwningActor.AttachParentActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyGroundSlam NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyGroundSlam);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
		SnowMonkeySettings = UTundraPlayerSnowMonkeySettings::GetSettings(Cast<AHazeActor>(HazeOwningActor.AttachParentActor));

		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(HazeOwningActor.AttachParentActor);
		
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		bIsMoving = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		bIsGrounded = !MoveComp.IsInAir();
		bCurrentGroundSlamTypeIsGrounded = SnowMonkeyComp.bCurrentGroundSlamIsGrounded;
		VerticalVelocity = MoveComp.VerticalVelocity.Z;

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.8);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp.UpdateSlopeWarpData(SlopeWarpData);

		// Added by Oliver, 1.1 was the original length, if it is changed the animation should playrate accordingly.
		GroundedGroundSlamPlayRate = 1.1 / SnowMonkeySettings.GroundedGroundSlamLockedTime;

		SlopeAlignAlpha = 0.6;

		Print("bIsMoving: " + bIsMoving, 0.f);

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
