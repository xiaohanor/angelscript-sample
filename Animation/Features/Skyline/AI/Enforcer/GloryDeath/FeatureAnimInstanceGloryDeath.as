UCLASS(Abstract)
class UFeatureAnimInstanceGloryDeath : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGloryDeath Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGloryDeathAnimData AnimData;

	// Add Custom Variables Here
	UGravityBladeCombatEnforcerGloryDeathComponent GloryDeathComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWasAttackStarted;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int GloryDeathAnimationIndex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioRightFootForward;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioAirborne;

	UPROPERTY()
	bool bHasDied;

	
	//* Sperring madness
	TArray<FName> BonesToHide;

	FName HiddenBone;

	UHazeSkeletalMeshComponentBase Mesh;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		ULocomotionFeatureGloryDeath NewFeature = GetFeatureAsClass(ULocomotionFeatureGloryDeath);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bHasDied = false;

		// Implement Custom Stuff Here

		GloryDeathComp = UGravityBladeCombatEnforcerGloryDeathComponent::Get(HazeOwningActor);

		AHazeCharacter Character = Cast<AHazeCharacter>(HazeOwningActor);
		Mesh = Character.Mesh;

		BonesToHide.Add(n"Head");
		BonesToHide.Add(n"Spine");
		BonesToHide.Add(n"RightForeArm");
		BonesToHide.Add(n"LeftForeArm");
		BonesToHide.Add(n"RightLeg");
		BonesToHide.Add(n"LeftLeg");

#if EDITOR
		// Make a sanity check on the game thread (since usages of the anim data may occur on anim thread where we cannot inform animators properly)
		if (GloryDeathComp != nullptr)
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
		Super::BlueprintUpdateAnimation(DeltaTime);

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		FGravityBladeCombatGloryKillAnimData GloryKillAnimData = GloryDeathComp.AnimData;

		bWasAttackStarted = GloryKillAnimData.WasAttackStarted();
		GloryDeathAnimationIndex = GloryKillAnimData.GloryKillAnimationIndex;
		bMioRightFootForward = GloryDeathComp.AnimData.bRightFootForward;
		bMioAirborne = GloryDeathComp.AnimData.bAirborne;

		if (HealthComp.IsDead())
			bHasDied = true;
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
		//Mesh.UnHideBoneByName(n"LeftLeg");
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetAnimationByName(FName AnimationName) const
	{
		if (HazeOwningActor == nullptr)
			return FHazePlaySequenceData(); // Editor preview

		FGravityBladeGloryDeathAnimationWithMetaData Animation = AnimData.GetAnimationFromName(AnimationName, bMioAirborne);
		if(GloryDeathComp != nullptr && bMioRightFootForward)
			return Animation.MioRightFootAnimation;
		else
			return Animation.MioLeftFootAnimation;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	FHazePlaySequenceData GetAnimationByIndex(int Index) const
	{
		if (HazeOwningActor == nullptr)
			return FHazePlaySequenceData(); // Editor preview

		FGravityBladeGloryDeathAnimationWithMetaData Animation = AnimData.GetAnimationFromIndex(Index, bMioAirborne);
		if(GloryDeathComp != nullptr && bMioRightFootForward)
			return Animation.MioRightFootAnimation;
		else
			return Animation.MioLeftFootAnimation;
	}
}
