class UEnforcerHoveringGravityWhipBillboardImpactBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	USkylineEnforcerSettings EnforcerSettings;
	UEnforcerJetpackSettings JetpackSettings;
	UEnforcerHoveringSettings HoveringSettings;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineEnforcerGravityWhipComponent EnforcerGravityWhipComp;
	UGravityWhippableComponent WhippableComp;
	UGravityBladeCombatTargetComponent BladeTargetComp;
	UGravityBladeGrappleComponent BladeGrappleTargetComp;
	UGravityWhipTargetComponent WhipTargetComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UEnforcerHoveringComponent HoveringComp;
	ASkylineJetpackCombatZoneManager BillboardManager;
	
	bool bThrown;
	bool bHit;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		EnforcerSettings = USkylineEnforcerSettings::GetSettings(Owner);
		JetpackSettings = UEnforcerJetpackSettings::GetSettings(Owner);
		HoveringSettings = UEnforcerHoveringSettings::GetSettings(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);
		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(Owner);
		BladeGrappleTargetComp = UGravityBladeGrappleComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
		HoveringComp = UEnforcerHoveringComponent::GetOrCreate(Owner);

		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		UGravityWhipResponseComponent WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");

		EnforcerGravityWhipComp = USkylineEnforcerGravityWhipComponent::GetOrCreate(Owner);
		WhipTargetComp = UGravityWhipTargetComponent::GetOrCreate(Owner);

		BillboardManager = TListedActors<ASkylineJetpackCombatZoneManager>().GetSingle();

		// No blade target unless stuck to billboard
		BladeTargetComp.Disable(this); 
		BladeGrappleTargetComp.Disable(this);
	}

	UFUNCTION()
	private void OnReset()
	{
		bThrown = false;
		bHit = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		bThrown = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bThrown)
			return;
		if (HoveringComp.TargetBillboardZone.IsDefaultValue())
			return;
		if(MoveComp.HasAnyValidBlockingImpacts())
		{
			for (FMovementHitResult Impact :MoveComp.AllImpacts)
			{
				if (Impact.Actor.IsA(AHazeCharacter))
					continue; // Ignore characters
				if (!BillboardManager.IsAtBillboard(Impact.Location))
					continue;

				// We've hit billboard
				bHit = true;
				WhippableComp.bThrown = false;
				EnforcerGravityWhipComp.ImpactNormal = Impact.Normal;
				EnforcerGravityWhipComp.ImpactLocation = Impact.Location;
				EnforcerGravityWhipComp.OnImpact.Broadcast();
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bHit)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > EnforcerSettings.GravityWhipImpactDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// We are now stuck to billboard
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(HoveringComp.TargetBillboardZone.Get().Root, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal, n"Hips");

		bThrown = false;
		bHit = false;
		MoveComp.Reset();
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipWallImpact, SubTagAIGravityWhipWallImpact::Impact, EBasicBehaviourPriority::Medium, this, EnforcerSettings.GravityWhipImpactDuration);

		FEnforcerEffectOnGravityWhipThrowImpactData Data;
		Data.ImpactLocation = EnforcerGravityWhipComp.ImpactLocation + Owner.ActorUpVector * 100;
		Data.ImpactNormal = EnforcerGravityWhipComp.ImpactNormal;
		UEnforcerEffectHandler::Trigger_OnGravityWhipThrowImpact(Owner, Data);

		Owner.BlockCapabilities(n"CrowdRepulsion", this);
		UBasicAIMovementSettings::SetAirFriction(Owner, 12, this);
		WhipTargetComp.Disable(Owner);

		// Blade target is only ever enabled when stuck to billboard
		BladeTargetComp.Enable(this); 
		BladeGrappleTargetComp.Enable(this);

		UBasicAIHealthBarSettings::SetHealthBarOffset(Owner, FVector(100.0, 0.0, 150.0), this, EHazeSettingsPriority::Script);
		HealthBarComp.SetHealthBarEnabled(true);

		if (BillboardManager.FauxPhysicsRoot != nullptr)
			FauxPhysics::ApplyFauxImpulseToActorAt(BillboardManager.FauxPhysicsRoot, Owner.ActorCenterLocation, -Data.ImpactNormal * HoveringSettings.BillboardThrownImpactForce);

		UEnforcerJetpackEffectHandler::Trigger_OnHitBillboard(Owner, FJetpackBillboardParams(HoveringComp.TargetBillboardZone.Get()));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		MoveComp.ClearFollowEnabledOverride(this);
		MoveComp.UnFollowComponentMovement(this);
		Owner.UnblockCapabilities(n"CrowdRepulsion", this);
		Owner.ClearSettingsByInstigator(this);
		WhipTargetComp.Enable(Owner);
		HealthBarComp.SetHealthBarEnabled(false);

		// Stop being a valid blade target as soon as we leave billboard.
		BladeTargetComp.Disable(this); 
		BladeGrappleTargetComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Hit the ground
        if (Owner.ActorUpVector.DotProduct(EnforcerGravityWhipComp.ImpactNormal) > 1 - SMALL_NUMBER)
            return;

		DestinationComp.RotateTowards(Owner.ActorLocation + EnforcerGravityWhipComp.ImpactNormal * 100);
	}
}