
class UIslandOverseerDeployEyeAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerVisorComponent VisorComp;

	UIslandOverseerSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;

	UIslandOverseerDeployEyeManagerComponent EyeManager;
	bool bEyesAreDead = false;
	float StopTime;
	bool bActivatedEyes;
	float DeactivatedEyesTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		EyeManager = UIslandOverseerDeployEyeManagerComponent::GetOrCreate(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Owner.IsCapabilityTagBlocked(n"Eye"))
			return true;
		if(DeactivatedEyesTime > 0 && Time::GetGameTimeSince(DeactivatedEyesTime) > VisorComp.CloseDuration + 1)
			return true;		
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Durations.Telegraph = 1.8;
		Durations.Action = 0.1;
		Durations.Recovery = 1;
		AnimComp.RequestAction(FeatureTagIslandOverseer::DeployEye, EBasicBehaviourPriority::Medium, this, Durations);
		StopTime = 0;
		VisorComp.Open();
		bActivatedEyes = false;
		DeactivatedEyesTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(3);
		VisorComp.Close();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Durations.Telegraph)
			return;

		if(!bActivatedEyes)	
		{			
			bActivatedEyes = true;
			for(AAIIslandOverseerEye Eye : EyeManager.Eyes)
				Eye.Activate();
			UIslandOverseerEventHandler::Trigger_OnDeployEyes(Owner);
		}
		else if(DeactivatedEyesTime < SMALL_NUMBER)
		{
			bool AreDeactivated = true;
			for(AAIIslandOverseerEye Eye : EyeManager.Eyes)
			{
				if(Eye.Active)
					AreDeactivated = false;
			}

			if(AreDeactivated)
			{
				VisorComp.Close();
				DeactivatedEyesTime = Time::GameTimeSeconds;
			}
		}

		if(ActiveDuration > Durations.GetTotal())
			AnimComp.RequestFeature(FeatureTagIslandOverseer::DeployEye, EBasicBehaviourPriority::Medium, this, 0);
	}
}