class USanctuaryDodgerSleepBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USanctuaryDodgerSleepComponent SleepComp;
	USanctuaryDodgerSettings DodgerSettings;
	AAISanctuaryDodger Dodger;

	bool bStirred;
	float StirTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Dodger = Cast<AAISanctuaryDodger>(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
		SleepComp = USanctuaryDodgerSleepComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!SleepComp.IsSleeping())
			return false;
		if(TargetComp.HasValidTarget())
			return false;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!SleepComp.IsSleeping())
			return true;
		if(TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		RequestSleep();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.RequestFeature(FeatureTagDodger::Default, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bInRange = false;
		for(AHazePlayerCharacter Player: Game::Players)
		{
			float Distance = Owner.ActorCenterLocation.Distance(Player.ActorLocation);
			// Debug::DrawDebugSphere(Owner.FocusLocation, DodgerSettings.SleepWakeRange);
			if(Distance <= DodgerSettings.SleepStirRange)
			{
				if(!bStirred)
				{
					StirTime = Time::GetGameTimeSeconds() + 0.5;

					// This should be the stirring subtag
					if(SleepComp.bStandingSleep)
						AnimComp.RequestFeature(FeatureTagDodger::Sleeping, SubTagDodgerSleeping::Shrug, EBasicBehaviourPriority::Medium, this, StirTime);
					else	
						AnimComp.RequestFeature(FeatureTagDodger::Sleeping, SubTagDodgerSleeping::Shrug, EBasicBehaviourPriority::Medium, this, StirTime);
				}	
				bInRange = true;
			}
		}
		bStirred = bInRange;
		
		if(StirTime != 0 && Time::GetGameTimeSeconds() > StirTime)
		{
			RequestSleep();
			StirTime = 0;
		}
	}

	private void RequestSleep()
	{
		if(SleepComp.bStandingSleep)
			AnimComp.RequestFeature(FeatureTagDodger::Sleeping, SubTagDodgerSleeping::SleepStanding, EBasicBehaviourPriority::Medium, this);
		else	
			AnimComp.RequestFeature(FeatureTagDodger::Sleeping, SubTagDodgerSleeping::SleepHanging, EBasicBehaviourPriority::Medium, this);
	}
}