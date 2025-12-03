UCLASS(Abstract)
class UFeatureAnimInstanceSwingAir : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSwingAir Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSwingAirAnimData AnimData;

	UPlayerSwingComponent SwingComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerSwingAnimData SwingAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PushAdditiveAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditivePlayRate;

	float InterpolatedNormalizedVelocity;

	// Physical Animation
	UHazePhysicalAnimationComponent PhysAnimComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSwingAir NewFeature = GetFeatureAsClass(ULocomotionFeatureSwingAir);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		SwingComp = UPlayerSwingComponent::Get(Player);

		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		if (Feature.PhysAnimProfile != nullptr)
			PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile, BlendTime = 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		SwingAnimData = SwingComp.AnimData;

		//Additive animation stuff

		float NormalizedVelocity = Math::Abs(SwingAnimData.RelativeVelocity.Size()) / 1200;

		InterpolatedNormalizedVelocity = Math::FInterpTo(InterpolatedNormalizedVelocity, NormalizedVelocity, DeltaTime, 1);
		
		if (InterpolatedNormalizedVelocity > 0.1)
		{
			AdditivePlayRate = Math::Clamp(Math::FInterpTo(AdditivePlayRate, (NormalizedVelocity*2), DeltaTime, 2), 0.25, 1.5);

			AdditiveAlpha = Math::Clamp(Math::FInterpTo(AdditiveAlpha,NormalizedVelocity, DeltaTime, 2), 0.2, 1);

			PushAdditiveAlpha = Math::Clamp(Math::FInterpTo(AdditiveAlpha,PushAdditiveAlpha, DeltaTime, 2), 0, 0.3);
		}
		
		//Increases the additive animation playing if nearly completely still
		else
		{
			AdditivePlayRate = Math::Clamp(Math::FInterpTo(AdditivePlayRate, (NormalizedVelocity*2), DeltaTime, 2), 0.4, 1);

			AdditiveAlpha = Math::Clamp(Math::FInterpTo(AdditiveAlpha,NormalizedVelocity, DeltaTime, 2), 0.4, 1);

			PushAdditiveAlpha = Math::Clamp(Math::FInterpTo(AdditiveAlpha,PushAdditiveAlpha, DeltaTime, 2), 0, 0.4);
		}

		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		PhysAnimComp.ClearProfileAsset(this);
	}
}
