struct FTundraTreeGuardianLifeGivingAnimationData
{
	FTundraTreeGuardianLifeGivingAnimationData(float In_EnterDuration, float In_ExitDuration, float In_RequiredStartThreshold, float In_RequiredEndThreshold, float In_AllowedExitTime)
	{
		EnterDuration = In_EnterDuration;
		ExitDuration = In_ExitDuration;
		RequiredStartThreshold = In_RequiredStartThreshold;
		RequiredEndThreshold = In_RequiredEndThreshold;
		AllowedExitTime = In_AllowedExitTime;
	}

	bool CanExit(float ScrubTime)
	{
		if(Math::IsNearlyEqual(ScrubTime, EnterDuration))
			return true;

		if(RequiredStartThreshold > 0.0 && ScrubTime < RequiredStartThreshold)
			return false;

		if(RequiredEndThreshold > 0.0 && ScrubTime > RequiredEndThreshold)
			return false;

		return true;
	}

	float EnterDuration = 1.0;
	float ExitDuration = 1.0;
	// Amount of seconds required to elapse in the animation before allowing a blend out.
	float RequiredStartThreshold = 0.5;
	// When this amount of seconds have elapsed in the animation the enter must finish before blending out.
	float RequiredEndThreshold = 0.8;
	float AllowedExitTime = 0.5;
}

class UTundraTreeGuardianLifeGivingAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLifeGiving);

	// This has to be after grounded and ranged life giving capabilities
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerMovementComponent MoveComp;
	FTundraTreeGuardianLifeGivingAnimationData AnimationData;
	FName FeatureTag;
	bool bExit = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TreeGuardianComp.CurrentLifeReceivingComp == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bExit)
			return false;

		if(TreeGuardianComp.LifeGiveAnimData.bExitInstant)
			return true;

		if(!GetAttributeVector2D(AttributeVectorNames::MovementRaw).IsNearlyZero())
		{
			if(TreeGuardianComp.LifeGiveAnimData.AnimationScrubTime <= AnimationData.AllowedExitTime)
				return true;
		}

		if(TreeGuardianComp.LifeGiveAnimData.AnimationScrubTime <= KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FeatureTag = GetFeatureTag();
		UHazeLocomotionFeatureBase Feature = TreeGuardianComp.GetShapeActor().Mesh.GetFeatureByTag(FeatureTag);
		AnimationData = GetAnimationDataFromFeature(Feature);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		TreeGuardianComp.bInLifeGivingAnimation = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		TreeGuardianComp.LifeGiveAnimData.bShouldExit = false;
		bExit = false;
		TreeGuardianComp.LifeGiveAnimData.AnimationScrubTime = 0.0;
		TreeGuardianComp.TimeOfExitLifeGiveAnimation.Set(Time::GetGameTimeSeconds());
		TreeGuardianComp.bInLifeGivingAnimation = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bShouldExit = TreeGuardianComp.CurrentLifeReceivingComp == nullptr;
		float& ScrubTime = TreeGuardianComp.LifeGiveAnimData.AnimationScrubTime;

		if(bShouldExit && !bExit && AnimationData.CanExit(ScrubTime))
		{
			bExit = true;
			if(Math::IsNearlyEqual(ScrubTime, AnimationData.EnterDuration))
			{
				ScrubTime = AnimationData.ExitDuration;
				TreeGuardianComp.LifeGiveAnimData.bShouldExit = true;
			}
		}
		else if(!bShouldExit)
		{
			bExit = false;
			TreeGuardianComp.LifeGiveAnimData.bShouldExit = false;
		}

		if(bExit)
			ScrubTime -= DeltaTime;
		else
			ScrubTime += DeltaTime;
		
		float Max = TreeGuardianComp.LifeGiveAnimData.bShouldExit ? AnimationData.ExitDuration : AnimationData.EnterDuration;
		ScrubTime = Math::Clamp(ScrubTime, 0.0, Max);

		if(Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(FeatureTag, this);

		if(bExit)
			return;

		if(ScrubTime < 0.9)
		{
			float ForceFeedbackForce = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.9), FVector2D(0.0, 0.1), ScrubTime);
			Player.SetFrameForceFeedback(ForceFeedbackForce, ForceFeedbackForce, 0.0, 0.0);
		}
		else if(ScrubTime < 1.05)
		{
			Player.SetFrameForceFeedback(0.5, 0.5, 0.0, 0.0);
		}
	}

	FName GetFeatureTag() const
	{
		FName Feature;
		if(TreeGuardianComp.bCurrentLifeGiveIsRanged)
		{
			Feature = n"RangedLifeGiving";
			auto RangedLifeActor = Cast<ATundraRangedLifeGivingActor>(TreeGuardianComp.CurrentLifeReceivingComp.Owner);

			if(TreeGuardianComp.CurrentLifeReceivingComp.bOverrideFeatureTag)
				Feature = TreeGuardianComp.CurrentLifeReceivingComp.OverrideFeatureTag;
			else if(RangedLifeActor != nullptr && RangedLifeActor.bOverrideFeatureTag)
				Feature = RangedLifeActor.OverrideFeatureTag;
		}
		else
		{
			Feature = n"TreeGuardianHeal";
			auto GroundedLifeActor = Cast<ATundraGroundedLifeGivingActor>(TreeGuardianComp.CurrentLifeReceivingComp.Owner);

			if(TreeGuardianComp.CurrentLifeReceivingComp.bOverrideFeatureTag)
				Feature = TreeGuardianComp.CurrentLifeReceivingComp.OverrideFeatureTag;
			else if(GroundedLifeActor != nullptr && GroundedLifeActor.bOverrideFeatureTag)
				Feature = GroundedLifeActor.OverrideFeatureTag;
		}
		return Feature;
	}

	FTundraTreeGuardianLifeGivingAnimationData GetAnimationDataFromFeature(UHazeLocomotionFeatureBase Feature) const
	{
		auto DistanceInteract = Cast<ULocomotionFeatureTreeGuardianDistanceInteract>(Feature);
		if(DistanceInteract != nullptr)
		{
			return FTundraTreeGuardianLifeGivingAnimationData(
				DistanceInteract.AnimData.Enter.Sequence.PlayLength,
				DistanceInteract.AnimData.Exit.Sequence.PlayLength,
				0.5,
				0.8,
				0.9
			);
		}

		auto Heal = Cast<ULocomotionFeatureTreeGuardianHeal>(Feature);
		if(Heal != nullptr)
		{
			return FTundraTreeGuardianLifeGivingAnimationData(
				Heal.AnimData.Enter.Sequence.PlayLength,
				Heal.AnimData.Exit.Sequence.PlayLength,
				0.5,
				0.8,
				0.9
			);
		}

		auto FlowerInteract = Cast<ULocomotionFeatureTreeGuardianFlowerInteract>(Feature);
		if(FlowerInteract != nullptr)
		{
			return FTundraTreeGuardianLifeGivingAnimationData(
				FlowerInteract.AnimData.Start.Sequence.PlayLength,
				FlowerInteract.AnimData.End.Sequence.PlayLength,
				0.5,
				-1.0,
				0.5
			);
		}

		auto WalkingStickInteract = Cast<ULocomotionFeatureTreeGuardianWalkingstickInteract>(Feature);
		if(WalkingStickInteract != nullptr)
		{
			return FTundraTreeGuardianLifeGivingAnimationData(
				WalkingStickInteract.AnimData.InteractStart.Sequence.PlayLength,
				WalkingStickInteract.AnimData.InteractEnd.Sequence.PlayLength,
				0.3,
				0.6,
				0.5
			);
		}

		devError(f"Forgot to add case for feature {Feature.Name}");
		return FTundraTreeGuardianLifeGivingAnimationData();
	}
}