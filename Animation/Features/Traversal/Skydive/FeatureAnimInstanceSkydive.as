enum ESkydiveDashDirections
{
	Forward,
	Backward,
	Left,
	Right
};

UCLASS(Abstract)
class UFeatureAnimInstanceSkydive : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSkydive Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSkydiveAnimData AnimData;

	UPlayerSkydiveComponent SkydiveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPlayerSkydiveStyle SkydiveStyle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D Input;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGroundDetected;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DistanceToGround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLandingIsBlocked;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWaterLandingDetected;

	bool bAirDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedAirDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESkydiveDashDirections DashDirection;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		SkydiveComp = UPlayerSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSkydive NewFeature = GetFeatureAsClass(ULocomotionFeatureSkydive);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bAirDashing = false;

		bStartedAirDashing = false;

		bSkipStart = (PrevLocomotionAnimationTag == n"IslandSkydive" || GetAnimBoolParam(n"SkipSkydiveStart", true) || SkydiveComp.GetShouldSkipEnter());
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return GetAnimFloatParam(n"SkydiveBlendTime", true, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Input = SkydiveComp.AnimData.SkydiveInput;

		bGroundDetected = SkydiveComp.AnimData.bLandingDetected;

		DistanceToGround = SkydiveComp.AnimData.RemainingHeightForLanding;

		bLandingIsBlocked = SkydiveComp.AnimData.bLandingIsBlocked;

		// ADD variable from Component that detects if player will land in water
		bWaterLandingDetected = SkydiveComp.AnimData.bWaterLandingDetected;

		SkydiveStyle = SkydiveComp.GetCurrentSkydiveStyle();

		// ADD variable from Component for AirDashing
		// bAirDashing =

		// ADD logic for setting bool to true for one frame when player starts an AirDash
		// bStartedAirDashing = CheckValueChangedAndSetBool(bAirDashing, SkydiveComp.AnimData.DASHING, EHazeCheckBooleanChangedDirection::FalseToTrue);

		// if (bStartedAirDashing)
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"ApexDive")
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION()
	void SetDashDirection()
	{
		if (Input.Y >= 0 && Input.X > -0.45 && Input.X < 0.45)
		{
			DashDirection = ESkydiveDashDirections::Forward;
		}

		else if (Input.Y < 0 && Input.X > -0.45 && Input.X < 0.45)
		{
			DashDirection = ESkydiveDashDirections::Backward;
		}

		else if (Input.X < 0)
		{
			DashDirection = ESkydiveDashDirections::Left;
		}

		else if (Input.X > 0)
		{
			DashDirection = ESkydiveDashDirections::Right;
		}
	}
}
