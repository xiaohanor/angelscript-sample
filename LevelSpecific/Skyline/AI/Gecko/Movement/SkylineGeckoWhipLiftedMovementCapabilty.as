class USkylineGeckoWhipLiftedMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 65; 
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIDestinationComponent DestinationComp;
	UBasicAIAnimationComponent AnimComp;
	UGravityWhippableComponent WhippableComp;
	UGravityWhipResponseComponent WhipResponse;
	USkylineGeckoComponent GeckoComp;
	UGravityWhippableSettings WhippableSettings;
	USimpleMovementData Movement;

	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); 
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if (WhipResponse.GrabMode == EGravityWhipGrabMode::Sling)
			WhippableComp.bGrabbed = true;
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		OnReleased(UserComponent, TargetComponent, Impulse);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		WhippableComp.bGrabbed = false;
		if (!IsActive())
			return;
		MoveComp.AddPendingImpulse(Impulse);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (WhipResponse.GrabMode != EGravityWhipGrabMode::Sling)
			return false; // We can only be dragged
		if (!WhippableComp.bGrabbed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (WhipResponse.GrabMode != EGravityWhipGrabMode::Sling)
			return true; // We can only be dragged
		if(!WhippableComp.bGrabbed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrevLocation = Owner.ActorLocation;
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		AnimComp.RequestFeature(FeatureTagGecko::GrabbedByWhip, EBasicBehaviourPriority::High, this);
		UEnforcerEffectHandler::Trigger_OnGravityWhipGrabbed(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhippableComp.bThrown = true;	
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector Velocity = MoveComp.Velocity;
		Velocity *= Math::Pow(Math::Exp(-WhippableSettings.LiftedAirFriction), DeltaTime);
		Movement.AddVelocity(Velocity);
		Movement.AddPendingImpulses();
		MoveComp.RotateTowardsDirection(Game::Zoe.ViewRotation.Vector(), 10.0, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugArrow(Owner.ActorLocation, Owner.ActorLocation - FVector(0.0, 0.0, 1000.0), 20, FLinearColor::Red, 5.0);
			Debug::DrawDebugSphere(Cast<AHazeCharacter>(Owner).Mesh.WorldLocation);
		}
#endif
	}
}
