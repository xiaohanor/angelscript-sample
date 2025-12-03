struct FHoveringEnforcerThrownBehaviourParams
{
	ASkylineJetpackCombatZone TargetZone;
}

class UEnforcerHoveringGravityWhipThrownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityWhippableSettings WhippableSettings;
	UEnforcerHoveringSettings HoveringSettings;
	UGravityWhippableComponent WhippableComp;
	UGravityWhipTargetComponent WhipTargetComp;
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UHazeActorRespawnableComponent RespawnComp;
	UEnforcerHoveringComponent HoveringComp;	

	UGravityBladeCombatTargetComponent BladeTargetComp; 
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	FVector ThrowImpulse;
	AHazeActor ThrowingActor;
	FName PreviousCollisionProfile;
	ECollisionResponse PreviousCollisionResponse;
	float ThrowTime;
	FVector PreviousCenterLocation;

	UHazeCapsuleCollisionComponent CapsuleComponent;
	FVector CapsuleComponentInitialRelativeLocation;

	TArray<AActor> HitTargets;
	ASkylineJetpackCombatZoneManager BillboardManager;
	ASkylineJetpackCombatZone TargetZone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");

		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);		
				
		WhipTargetComp = UGravityWhipTargetComponent::Get(Owner);
		WhipAutoAimComp = UGravityWhipSlingAutoAimComponent::Get(Owner);

		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HomingProjectileComp = UBasicAIHomingProjectileComponent::GetOrCreate(Owner);
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);
		HoveringSettings = UEnforcerHoveringSettings::GetSettings(Owner);
		HoveringComp = UEnforcerHoveringComponent::GetOrCreate(Owner);

		CapsuleComponent = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		CapsuleComponentInitialRelativeLocation = CapsuleComponent.RelativeLocation;

		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);

		RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		BillboardManager = TListedActors<ASkylineJetpackCombatZoneManager>().GetSingle();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		HealthBarComp.SetHealthBarEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		if(IsBlockedByTag(SkylineAICapabilityTags::GravityWhippable))
			return;

		ThrowTime = Time::GetGameTimeSeconds();
		WhippableComp.bThrown = true;
		WhippableComp.OnThrown.Broadcast();
		ThrowingActor = Cast<AHazeActor>(UserComponent.Owner);
		FVector OwnLoc = Owner.ActorCenterLocation;
		if (BillboardManager.HasRayBillboardIntersection(OwnLoc, Impulse.GetSafeNormal()))
		{
			// Full impulse when thrown at billboard, tweaked to aim at unexploded billboard section
			ThrowImpulse = Impulse;
			FVector BillboardIntersectLoc = BillboardManager.LineBillboardPlaneIntersection(OwnLoc, ThrowImpulse);
			ASkylineJetpackCombatZone Zone = BillboardManager.GetNearestUnoccupiedBillboardZone(BillboardIntersectLoc);
			if (Zone != nullptr)
			{
				ThrowImpulse = (Zone.ActorLocation - OwnLoc).GetSafeNormal() * Impulse.Size();
				TargetZone = Zone;
			}
		}
		else
		{
			// Weak impulse when not thrown at billboard
			ThrowImpulse = Impulse.GetClampedToMaxSize(HoveringSettings.HoverThrownMaxImpulse);
		} 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoveringEnforcerThrownBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!WhippableComp.bThrown)
			return false;
		OutParams.TargetZone = TargetZone;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(HealthComp.IsDead())
			return true;
		if(!WhippableComp.bThrown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoveringEnforcerThrownBehaviourParams Params)
	{
		Super::OnActivated();

		TargetZone = Params.TargetZone;
		if (TargetZone != nullptr)
		{
			HoveringComp.TargetBillboardZone.Apply(TargetZone, BasicAITags::Behaviour, EInstigatePriority::Normal);
			TargetZone.CurrentlyOccupiedBy = Owner;
		}

		Owner.SetActorVelocity(ThrowImpulse * WhippableSettings.ThrownForceFactor);
		Owner.BlockCapabilities(n"CrowdRepulsion", this);
		
		WhipTargetComp.Disable(this);
		WhipAutoAimComp.Disable(this);
	
		UBasicAIMovementSettings::SetAirFriction(Owner, 0, this);
		UBasicAIMovementSettings::SetGroundFriction(Owner, 0, this);
		UMovementGravitySettings::SetGravityScale(Owner, 0, this);

		// Set capsule collsion, size and relative location
		CapsuleComponent.ApplyCollisionProfile(n"NoCollision", this);

		UEnforcerEffectHandler::Trigger_OnGravityWhipThrown(Owner);

		PreviousCenterLocation = Owner.ActorCenterLocation;

		HitTargets.Empty();

		HealthBarComp.SetHealthBarEnabled(false);
		HoveringComp.StuckWithNoActionCounter = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ThrowImpulse = FVector::ZeroVector;
		WhippableComp.bThrown = false;
		Owner.UnblockCapabilities(n"CrowdRepulsion", this);
		Owner.ClearSettingsByInstigator(this);

		WhipTargetComp.Enable(this);
		WhipAutoAimComp.Enable(this);

		HomingProjectileComp.Target = nullptr;
		ThrowTime = 0;

		// Restore capusle collsion, size and relative location 
		CapsuleComponent.ClearCollisionProfile(this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipThrown, SubTagAIGravityWhipThrown::Thrown, EBasicBehaviourPriority::Medium, this);

		if(HomingProjectileComp.Target != nullptr)
		{
			FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
			if(Owner.ActorVelocity.DotProduct(TargetLocation - Owner.ActorLocation) > 0)
			{
				float LaunchDuration = Time::GetGameTimeSince(ThrowTime);
				Owner.ActorVelocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, Owner.ActorVelocity.GetSafeNormal(), 300.0 * LaunchDuration) * DeltaTime;
			}
		}
	}
}