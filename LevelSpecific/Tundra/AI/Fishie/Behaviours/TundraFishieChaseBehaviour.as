class UTundraFishieChaseBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Chase");

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UTundraFishieComponent FishieComp;
	UTundraFishieSettings Settings;
	float HiddenTargetDuration = 0.0;
	AHazePlayerCharacter Target;

	UCameraShakeBase CamShake;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FishieComp = UTundraFishieComponent::GetOrCreate(Owner);	
		Settings = UTundraFishieSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!FishieComp.CanHunt())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		AHazeActor TestTarget = TargetComp.Target;
		if (!TargetComp.HasVisibleTarget(TargetOffset = TestTarget.ActorUpVector * Settings.VisibilityTargetOffset))
			return false;
		if (!FishieComp.IsNear(TestTarget.ActorCenterLocation, Settings.ChaseRangeAhead, Settings.ChaseRangeBehind, Settings.ChaseRangeAbove, Settings.ChaseRangeBelow))
			return false;
		if (!TestTarget.IsA(AHazePlayerCharacter))
			return false;
		return true;
	}
		
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!FishieComp.CanHunt())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		AnimComp.RequestFeature(TundraFishieAnimTags::Chase, EBasicBehaviourPriority::Medium, this);
		HiddenTargetDuration = 0.0;

		FishieComp.bAgitated.Apply(true, this);

		float Proximity = Math::GetMappedRangeValueClamped(FVector2D(1500.0, 100.0), FVector2D(0.0, 1.0), Owner.ActorLocation.Distance(Target.ActorLocation));
		if (FishieComp.ChasingCamShake.IsValid())
			Target.PlayCameraShake(FishieComp.ChasingCamShake, this, Proximity);	

		UAITundraFishieEventHandler::Trigger_OnStartChase(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		FishieComp.bAgitated.Clear(this);
		Target.StopCameraShakeByInstigator(this);
		Target.StopForceFeedback(this);
		UAITundraFishieEventHandler::Trigger_OnStopChase(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < Settings.ChaseReactionPause)
		{
			DestinationComp.RotateTowards(Target.ActorCenterLocation);
			if (ActiveDuration < Settings.ChaseReactionPause * 0.25)
				DestinationComp.MoveTowardsIgnorePathfinding(Target.ActorCenterLocation, Settings.ChaseMoveSpeed * 4.0);
		}
		else
		{
			DestinationComp.MoveTowardsIgnorePathfinding(Target.ActorCenterLocation, Settings.ChaseMoveSpeed);
		}

		if (TargetComp.HasVisibleTarget(TargetOffset = Target.ActorUpVector * Settings.VisibilityTargetOffset))
			HiddenTargetDuration = 0.0;
		else
			HiddenTargetDuration += DeltaTime;
		if (HiddenTargetDuration > Settings.ChaseLoseHiddenTargetDuration)
			Cooldown.Set(0.5);

		FishieComp.LastChaseTime = Time::GameTimeSeconds;

		FishieComp.UpdateEating(AnimComp);

		if (FishieComp.bIsChaseFish)
		{
			float Proximity = Math::GetMappedRangeValueClamped(FVector2D(1500.0, 100.0), FVector2D(0.0, 1.0), Owner.ActorLocation.Distance(Target.ActorLocation));
			if (CamShake != nullptr)
				CamShake.ShakeScale = Proximity;

			FHazeFrameForceFeedback FrameFF;		
			FrameFF.LeftMotor = Math::PerlinNoise1D(ActiveDuration * 3.23) * 1.0 + 0.8;		
			FrameFF.RightMotor = Math::PerlinNoise1D(ActiveDuration * 4.17) * 1.0 + 0.8;		
			FrameFF.LeftTrigger = Math::PerlinNoise1D(ActiveDuration * 5.87) * 0.05;		
			FrameFF.RightTrigger = Math::PerlinNoise1D(ActiveDuration * 6.91) * 0.05;				
			Target.SetFrameForceFeedback(FrameFF, Proximity);
		}
	}
}
