class USanctuaryDodgerScenepointLandBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock);
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerChargeBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 

	UBasicAIHealthComponent HealthComp;
	USanctuaryDodgerGrabComponent GrabComp;
	USanctuaryDodgerLandComponent LandComp;
	UScenepointComponent Scenepoint;
	USanctuaryDodgerSettings DodgerSettings;

	private UScenepointComponent PrevScenepoint;
	float ValidTime;
	float InvalidTime;
	float LandTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GrabComp = USanctuaryDodgerGrabComponent::Get(Owner);
		LandComp = USanctuaryDodgerLandComponent::Get(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive() || !HealthComp.IsAlive() || IsBlocked())
			return;

		if(!TargetComp.HasValidTarget())
			return;

		auto ScenepointTargetComp = UScenepointTargetComponent::Get(TargetComp.Target);
		if(ScenepointTargetComp == nullptr)
			return;

		PrevScenepoint = Scenepoint;
		Scenepoint = ScenepointTargetComp.ScenepointContainer.UseBestScenepoint();

		if(Scenepoint != nullptr && Scenepoint.CanUse(Owner) && (PrevScenepoint == nullptr || Scenepoint == PrevScenepoint))
		{
			if(ValidTime == 0)
				ValidTime = Time::GetGameTimeSeconds();
		}
		else
		{
			ValidTime = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(GrabComp.bGrabbing)
			return false;
		if(Scenepoint == nullptr)
			return false;
		if(ValidTime == 0 || Time::GetGameTimeSince(ValidTime) < DodgerSettings.ScenepointLandDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		if(InvalidTime != 0 && Time::GetGameTimeSince(InvalidTime) > DodgerSettings.ScenepointLandReleaseDelay)	
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Scenepoint.Use(Owner);
		Owner.BlockCapabilities(SanctuaryDodgerTags::SanctuaryDodgerLandBlock, this);
		LandTime = 0;
		InvalidTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Scenepoint.Release(Owner);
		Requirements.Removeblock(EBasicBehaviourRequirement::Weapon);
		if(Owner.IsCapabilityTagBlocked(SanctuaryDodgerTags::SanctuaryDodgerLandBlock))
			Owner.UnblockCapabilities(SanctuaryDodgerTags::SanctuaryDodgerLandBlock, this);
		LandComp.bLanded = false;
		AnimComp.RequestFeature(FeatureTagDodger::Default, SubTagDodger::StartFly, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Owner.ActorVelocity.IsNearlyZero(100) && Owner.ActorLocation.IsWithinDist(Scenepoint.WorldLocation, 100))
		{
			AnimComp.RequestFeature(FeatureTagDodger::Default, SubTagDodger::Landing, EBasicBehaviourPriority::Medium, this);

			if(LandTime == 0)
				LandTime = Time::GetGameTimeSeconds();

			if(!LandComp.bLanded && Time::GetGameTimeSince(LandTime) > 2)
			{
				Owner.UnblockCapabilities(SanctuaryDodgerTags::SanctuaryDodgerLandBlock, this);
				LandComp.bLanded = true;
			}
		}
		else
		{
			float Speed = Math::Clamp(Owner.ActorLocation.Distance(Scenepoint.WorldLocation), 100, DodgerSettings.ScenepointLandSpeed);
			DestinationComp.MoveTowardsIgnorePathfinding(Scenepoint.WorldLocation, Speed);
		}
		
		auto ScenepointTargetComp = UScenepointTargetComponent::Get(TargetComp.Target);
		if(ScenepointTargetComp != nullptr)
		{
			bool Valid = ScenepointTargetComp.ScenepointContainer.Scenepoints.Contains(Scenepoint);
			if(Valid)
				InvalidTime = 0;
			if(!Valid && InvalidTime == 0)
				InvalidTime = Time::GetGameTimeSeconds();
		}
		else if(InvalidTime == 0)
		{
			InvalidTime = Time::GetGameTimeSeconds();
		}
	}
}