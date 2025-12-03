struct FEnforcerFleeBehaviourParams
{
	float ReactionTime = 0.4;
	UHazeSplineComponent Spline;
}

class UEnforcerFleeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIFleeingComponent FleeComp;
	UHazeSplineComponent Spline;
	USkylineEnforcerSettings Settings;
	UEnforcerJetpackComponent Jetpack;
	FVector SplineStart;
	float ReactionTime;
	bool bFleeing;
	bool bJetpackTravelling;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FleeComp = UBasicAIFleeingComponent::Get(Owner);
		Jetpack = UEnforcerJetpackComponent::Get(Owner);
		Settings = USkylineEnforcerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FEnforcerFleeBehaviourParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!FleeComp.bWantsToFlee)
			return false;
		if (FleeComp.SplineOptions.IsEmpty())
			return false;
		// Random reaction time so we won't all flee at exactly the same time
		OutParams.ReactionTime = Math::RandRange(0.0, 0.7);
		OutParams.Spline = FleeComp.SplineOptions.UseBestSpline(Owner, 0.0, 5.0);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!FleeComp.bWantsToFlee)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FEnforcerFleeBehaviourParams Params)
	{
		Super::OnActivated();
		ReactionTime = Params.ReactionTime;		
		Spline = Params.Spline;
		SplineStart = Spline.GetWorldLocationAtSplineFraction(0.0);
		bFleeing = false;
		bJetpackTravelling = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if(Owner.IsActorDisabled())
			FleeComp.CompleteFlight();
		if (Jetpack.IsUsingJetpack())
		{
			Jetpack.StopJetpack();
			UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < ReactionTime)
		{
			// Do nothing while the gut-wrenching dread forms in our stomach
		}
		else if (ActiveDuration < ReactionTime + 0.5)
		{
			// Turn towards escape spline
			DestinationComp.RotateTowards(SplineStart);
			if (!bFleeing)
			{
				// Start fleeing
				bFleeing = true;
				Jetpack.StartJetpack();
				AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, EBasicBehaviourPriority::Medium, this);
				UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
			}
		}
		else 
		{
			if (!bJetpackTravelling)
				UEnforcerJetpackEffectHandler::Trigger_JetpackTravel(Owner);
			bJetpackTravelling = true;

			// Fly you fool!
			DestinationComp.MoveAlongSpline(Spline, Settings.FleeSpeed);
			if (DestinationComp.IsAtSplineEnd(Spline, 100.0))
			{
				FleeComp.CompleteFlight();
				DeactivateBehaviour();				
			}
		}
	}
}
