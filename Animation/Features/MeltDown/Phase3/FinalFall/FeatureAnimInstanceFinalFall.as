UCLASS(Abstract)
class UFeatureAnimInstanceFinalFall : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFinalFall Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFinalFallAnimData AnimData;

	// Add Custom Variables Here

	//Direction Rader is hit from and how big his reaction is - small, big, or a spin. Default state is Inactive.
	UPROPERTY()
	ERaderFallingHitReactType HitReactType;

	//Set to true for the frame Rader is hit by something
	UPROPERTY()
	bool bHitThisFrame;

	//Can be increased when Rader starts falling faster through the portals at the end
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float FallSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveAlpha;

	bool bAlphaIncrease;

	AMeltdownBossPhaseThreeDummyRaderFalling Rader;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFinalFall NewFeature = GetFeatureAsClass(ULocomotionFeatureFinalFall);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		Rader = Cast<AMeltdownBossPhaseThreeDummyRaderFalling>(HazeOwningActor);

		AdditiveAlpha = 0;
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

		if (Rader != nullptr)
		{
			auto SkydiveComp = UMeltdownSkydiveComponent::Get(Game::Mio);

			FallSpeed = SkydiveComp.Settings.FallingVelocity;
			bHitThisFrame = (Rader.ObstacleHitFrame == GFrameNumber-1);
			HitReactType = Rader.ObstacleHitType;
		}

		
		AdditiveAlpha = Math::FInterpTo(AdditiveAlpha, 0.5, DeltaTime, 0.3);


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
	}

    UFUNCTION()
    void AnimNotify_StartedLastPart()
    {
       AdditiveAlpha = 0;
    }

}

enum ERaderFallingHitReactType

{
	Inactive,
	Hit_LeftSmall,
	Hit_LeftBig,
	Hit_LeftSpin,
	Hit_RightSmall,
	Hit_RightBig,
	Hit_RightSpin,
	Hit_FwdSmall,
	Hit_FwdBig,
	Hit_FwdSpin,
	Hit_BwdSpin,
	Hit_Crane,
	Hit_Debris,
	Hit_Laser,
	Hit_Ships,
	Hit_Worm,
	Hit_Ice,
	

}