UCLASS(Abstract)
class UFeatureAnimInstanceLaunch : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureLaunch Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLaunchAnimData AnimData;

	// Add Custom Variables Here

	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerAirMotionAnimData AirMoveAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalSpeed;

	// Physical Animation
	UHazePhysicalAnimationComponent PhysAnimComp;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		MoveComp = UPlayerMovementComponent::Get(Player);
		AirMoveComp = UPlayerAirMotionComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLaunch NewFeature = GetFeatureAsClass(ULocomotionFeatureLaunch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile, BlendTime = 0.5);
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

		// Implement Custom Stuff Here

		AirMoveAnimData = AirMoveComp.AnimData;
		VerticalSpeed = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);
		HorizontalSpeed = MoveComp.HorizontalVelocity.Size();
		

		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here
		// if (LocomotionAnimationTag != n"AirMovement")
		// 	return true;

		if (HorizontalSpeed <= (AirMoveComp.Settings.HorizontalMoveSpeed - 200) && (VerticalSpeed <= 0) )
			{
				return true;
			}

		return LocomotionAnimationTag != n"AirMovement";

		
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		if (LocomotionAnimationTag == n"Landing")
			{
				PhysAnimComp.ClearProfileAsset(this, 0);
			}
		else
			PhysAnimComp.ClearProfileAsset(this);
	}
}
