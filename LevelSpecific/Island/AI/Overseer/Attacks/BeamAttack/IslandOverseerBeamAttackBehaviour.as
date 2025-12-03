
struct FIslandOverseerBeamAttackBehaviourParams
{
	AIslandOverseerShockwave Beam;
}

class UIslandOverseerBeamAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;

	AAIIslandOverseer Overseer;
	
	AIslandOverseerShockwave CurrentBeam;
	FVector PreviousShapeLocation;
	UAnimInstanceIslandOverseer AnimInstance;
	FBasicAIAnimationActionDurations Durations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Overseer = Cast<AAIIslandOverseer>(Owner);
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Overseer.Mesh.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
			return;

		// CurrentBeam is synced in Activate
		if(!HasControl())
			return;

		TArray<AIslandOverseerShockwave> Beams = TListedActors<AIslandOverseerShockwave>().GetArray();
		for(AIslandOverseerShockwave Beam : Beams)
		{
			if(Beam == nullptr)
				continue;
			if(Beam.bStarted)
				continue;
			if(Beam.GetDistanceTo(Owner) > 1200)
				continue;
			CurrentBeam = Beam;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverseerBeamAttackBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(CurrentBeam == nullptr)
			return false;
		OutParams.Beam = CurrentBeam;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandOverseerBeamAttackBehaviourParams Params)
	{
		Super::OnActivated();
		CurrentBeam = Params.Beam;
		AnimInstance.FinalizeDurations(FeatureTagIslandOverseer::BeamAttack, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagIslandOverseer::BeamAttack, EBasicBehaviourPriority::Medium, this, Durations);
		PreviousShapeLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if(CurrentBeam != nullptr && !CurrentBeam.bStarted)
			CurrentBeam.Start();
		CurrentBeam = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CurrentBeam.bStarted)
			return;

		if(!Durations.IsInActionRange(ActiveDuration))
			return;

		FVector HandLocation = Overseer.Mesh.GetSocketLocation(n"LeftHand");
		FVector HandLocation2 = Overseer.Mesh.GetSocketLocation(n"LeftHandPiston");
		FVector ShapeLocation = (HandLocation + HandLocation2) / 2;

		if(PreviousShapeLocation == FVector::ZeroVector)
			PreviousShapeLocation = ShapeLocation;
		FVector Delta = PreviousShapeLocation - ShapeLocation;
		PreviousShapeLocation = ShapeLocation;

		if(!Delta.IsNearlyZero())
		{
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(CurrentBeam.DamageCollision);
			Trace.UseCapsuleShape(100, HandLocation.Distance(HandLocation2) * 10, ((HandLocation - HandLocation2).Rotation() + FRotator(90, 0, 0)).Quaternion());
			FHitResult Hit = Trace.QueryTraceComponent(ShapeLocation, ShapeLocation - Delta);

			if(Hit.bBlockingHit)
			{
				UIslandOverseerEventHandler::Trigger_OnBeamActivationHit(Owner);
				CurrentBeam.Start();
			}
		}
	}
}