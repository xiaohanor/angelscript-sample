UCLASS(Abstract)
class UFeatureAnimInstanceGloryKill : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGloryKill Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGloryKillAnimData AnimData;

	// Add Custom Variables Here
	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasAttackStarted;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int GloryKillAnimationIndex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRightFootForward;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAirborne;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGloryKill NewFeature = GetFeatureAsClass(ULocomotionFeatureGloryKill);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		BladeComp = UGravityBladeUserComponent::Get(Player);
		CombatComp = UGravityBladeCombatUserComponent::Get(Player);


#if EDITOR
		// Make a sanity check on the game thread (since usages of the anim data may occur on anim thread where we cannot inform animators properly)
		if (CombatComp != nullptr)
			AnimData.SanityCheck();		
#endif
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.06;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		FGravityBladeCombatGloryKillAnimData GloryKillAnimData = CombatComp.GloryKillAnimData;

		bWasAttackStarted = GloryKillAnimData.WasAttackStarted();
		GloryKillAnimationIndex = GloryKillAnimData.GloryKillAnimationIndex;
		bRightFootForward = CombatComp.GloryKillAnimData.bRightFootForward;
		bAirborne = CombatComp.GloryKillAnimData.bAirborne;

		BladeComp.ActiveAnimations.Reset();
		GetCurrentlyPlayingAnimations(BladeComp.ActiveAnimations);
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

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetAnimationByName(FName AnimationName) const
	{
		if (HazeOwningActor == nullptr)
			return FHazePlaySequenceData(); // Editor preview

		FGravityBladeGloryKillAnimationLeftRightPair Animation = AnimData.GetAnimationFromName(AnimationName, bAirborne);
		if(bRightFootForward)
			return Animation.RightAnimation.Animation;
		else
			return Animation.LeftAnimation.Animation;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetAnimationByIndex(int Index) const
	{
		if (HazeOwningActor == nullptr)
			return FHazePlaySequenceData(); // Editor preview

		FGravityBladeGloryKillAnimationLeftRightPair Animation = AnimData.GetAnimationFromIndex(Index, bAirborne);
		if(bRightFootForward)
			return Animation.RightAnimation.Animation;
		else
			return Animation.LeftAnimation.Animation;
	}
}
