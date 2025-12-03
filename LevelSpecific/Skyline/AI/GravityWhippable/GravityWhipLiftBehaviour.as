class UGravityWhipLiftBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityWhippableComponent WhippableComp;
	USkylineEnforcerSentencedComponent SentencedComp;
	UBasicAIControlSideSwitchComponent ControlSwitchComp;
	UGravityWhippableSettings WhippableSettings;

	bool bGrabbedReaction = false;
	float LandTime = 0.0;
	FVector StartLocation;
	float MaxHeight = 500.0;
	FVector LocalVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");

		HealthComp = UBasicAIHealthComponent::Get(Owner);
		SentencedComp = USkylineEnforcerSentencedComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);
		ControlSwitchComp = UBasicAIControlSideSwitchComponent::Get(Owner);
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent,	FHitResult HitResult, FVector Impulse)
	{
		if(IsBlockedByTag(SkylineAICapabilityTags::GravityWhippable))
			return;

		if(WhippableComp.bGrabbed)
		{
			// Reenable gravity
			Owner.ClearSettingsByInstigator(this);
		}
		WhippableComp.bGrabbed = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if (!Cast<UHazeCompoundCapability>(Outer).IsActive())
			return;

		if(IsBlockedByTag(SkylineAICapabilityTags::GravityWhippable))
			return;

		WhippableComp.bGrabbed = true;
		bGrabbedReaction = false;

		// Make sure we switch to whip user control side
		// Note that if whip user is on remote side, this will occur on control side after one crumb delay.
		// Then we switch control side the next tick and the lift capability activates on the whip user side 
		// immediately after that (i.e. with a double crumb delay).
		// Since that activation crumbs over to the whip user remote side there is a double crumb delay thera as well.
		// We might need some local behaviour to cover these delays
		if (ControlSwitchComp != nullptr)
			ControlSwitchComp.WantedController = UserComponent.Owner;		
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		if(IsBlockedByTag(SkylineAICapabilityTags::GravityWhippable))
			return;

		if(WhippableComp.bGrabbed)
		{
			// Reenable gravity
			Owner.ClearSettingsByInstigator(this);
		}
		WhippableComp.bGrabbed = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(WhippableComp.bGrabbed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if(!WhippableComp.bGrabbed && LandTime > 0 && Time::GetGameTimeSince(LandTime) > WhippableSettings.LandDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HealthComp.SetStunned();
		StartLocation = Owner.ActorLocation;
		SentencedComp.Sentence();
		
		UBasicAIMovementSettings::SetGroundFriction(Owner, WhippableSettings.LiftedGroundFriction, this, EHazeSettingsPriority::Gameplay);
		UBasicAIMovementSettings::SetAirFriction(Owner, WhippableSettings.LiftedGroundFriction, this, EHazeSettingsPriority::Gameplay);

		UEnforcerEffectHandler::Trigger_OnGravityWhipGrabbed(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.ClearStunned();
		if(IsBlocked())
			WhippableComp.bGrabbed = false;	
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WhippableComp.bGrabbed && !bGrabbedReaction)
		{
			// Got grabbed again while falling
			StartGrab();
		}

		if(!WhippableComp.bGrabbed && MoveComp.IsOnAnyGround() && LandTime == 0)
		{
			LandTime = Time::GetGameTimeSeconds();
			StartLocation = Owner.ActorLocation;
		}

		if(LandTime > 0)
		{
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::GrabbedLand, EBasicBehaviourPriority::Medium, this);
		}
		else if(!WhippableComp.bGrabbed)
		{
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::GrabbedRelease, EBasicBehaviourPriority::Medium, this);
		}
		else
		{
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::Grabbed, EBasicBehaviourPriority::Medium, this);
		}
	}

	private void StartGrab()
	{
		UMovementGravitySettings::SetGravityAmount(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);
		LandTime = 0;
		bGrabbedReaction = true;
	}
}