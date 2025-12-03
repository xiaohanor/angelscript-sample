class UAnimNotifySanctuarySlidingDiscContactPoint : UAnimNotify
{

#if EDITOR
	default NotifyColor = FColor::Red;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SanctuarySlidingDiscContactPoint";
	}
}

UCLASS(Abstract)
class UFeatureAnimInstanceSlidingDisc : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSlidingDisc Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSlidingDiscAnimData AnimData;

	USlidingDiscPlayerComponent SlidingComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BlendValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ExplicitTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasLanded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ImpactValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalLandedImpactStrength;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalAirVelocity = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESanctuaryHydraPlayerAnimationReaction HydraPlayerReaction;

	TArray<float32> ContactPointTimes;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSlidingDisc NewFeature = GetFeatureAsClass(ULocomotionFeatureSlidingDisc);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		SlidingComp = USlidingDiscPlayerComponent::Get(Player);

		AnimData.Shuffle.Sequence.GetAnimNotifyTriggerTimes(UAnimNotifySanctuarySlidingDiscContactPoint, ContactPointTimes);
		
		ExplicitTime = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BlendValue = SlidingComp.Lean.Value;

		HydraPlayerReaction = SlidingComp.HydraPlayerReaction; // Not used anywhere yet

		// Impact
		bHasLanded = SlidingComp.bIsLanding;
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled() && bHasLanded)
			PrintToScreen("bHasLanded: " + bHasLanded, 3.0, FLinearColor::Yellow);

		ImpactValue = SlidingComp.LandedImpactStrength;
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled() && ImpactValue > KINDA_SMALL_NUMBER)
			PrintToScreen("ImpactValue: " + ImpactValue, 0.0, FLinearColor::Yellow);


		HorizontalLandedImpactStrength = SlidingComp.HorizontalLandedImpactStrength;
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled() && HorizontalLandedImpactStrength > KINDA_SMALL_NUMBER)
			PrintToScreen("HorizontalLandedImpactStrength: " + HorizontalLandedImpactStrength, 0.0, FLinearColor::Yellow);

		VerticalAirVelocity = SlidingComp.VerticalAirVelocity;
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled() && !Math::IsNearlyEqual(VerticalAirVelocity, 0.0))
			PrintToScreen("VerticalAirVelocity: " + VerticalAirVelocity, 0.0, FLinearColor::Yellow);

		/*
		ExplicitTime = Math::FInterpTo(ExplicitTime, BlendValue + 1, DeltaTime, 5.0);
		ExplicitTime = BlendValue + 1;
		Print("ExplicitTime: " + ExplicitTime, 0.0);
		*/

		const float WantedExplicitTime = BlendValue + 1;

		float TargetExplicitTime = 0;

		if (WantedExplicitTime < ContactPointTimes[0])
			TargetExplicitTime = ContactPointTimes[0];
		else if (WantedExplicitTime >= ContactPointTimes[ContactPointTimes.Num() - 1])
			TargetExplicitTime = ContactPointTimes[ContactPointTimes.Num() - 1];
		else
		{
			// Find the contact point we're closest to
			for (int i = 0; i < ContactPointTimes.Num(); i++)
			{
				const float ContactPointTime = ContactPointTimes[i];
				const float NextContactPointTime = ContactPointTimes[i + 1];

				if (WantedExplicitTime >= ContactPointTime && WantedExplicitTime < NextContactPointTime)
				{
					if (WantedExplicitTime - ContactPointTime < NextContactPointTime - WantedExplicitTime)
						TargetExplicitTime = ContactPointTime;
					else
						TargetExplicitTime = NextContactPointTime;
					break;
				}
			}
		}
		ExplicitTime = Math::FInterpTo(ExplicitTime, TargetExplicitTime, DeltaTime, 1.5);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Movement")
			SetAnimFloatParam(n"MovementBlendTime", 0.6);
	}
}
