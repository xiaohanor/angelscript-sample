struct FSkylineTorHammerStunnedBehaviourParams
{
	FVector TargetLocation;
}


class USkylineTorHammerStunnedBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineTorHammerStealComponent StealComp;
	USkylineTorHammerPivotComponent PivotComp;
	USkylineTorSettings Settings;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccLocation;
	FRotator TargetRotation;
	FVector StartLocation;
	FVector TargetLocation;
	float Alpha;
	bool bLanded;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineTorHammerStunnedBehaviourParams& OutParams) const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!StealComp.bEnabled)
			return false;
		if(StealComp.bEnableShieldBreak)
			return false;
		OutParams.TargetLocation = Owner.ActorLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineTorHammerStunnedBehaviourParams Params)
	{
		Super::OnActivated();
		USkylineTorHammerEventHandler::Trigger_OnStunnedStart(Owner);

		Owner.BlockCapabilities(n"GroundMovement", this);
		Owner.BlockCapabilities(n"HurtReaction", this);

		StealComp.HammerComp.ResetTranslations();
		PivotComp.SetPivot(StealComp.HammerComp.HoldHammerComp.Hammer.TopLocation.WorldLocation);
		AccRotation.SnapTo(PivotComp.Pivot.ActorRotation);
		TargetRotation = FRotator::MakeFromZX(-FVector::UpVector, -PivotComp.Pivot.ActorForwardVector);
		
		StartLocation = PivotComp.Pivot.ActorLocation;
		TargetLocation = Params.TargetLocation;
		StealComp.Extend(3);

		Alpha = 0;
		bLanded = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorHammerEventHandler::Trigger_OnStunnedStop(Owner);
		PivotComp.RemovePivot();
		Owner.UnblockCapabilities(n"GroundMovement", this);
		Owner.UnblockCapabilities(n"HurtReaction", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRotation.SpringTo(TargetRotation, 100, 0.5, DeltaTime);
		PivotComp.Pivot.ActorRotation = AccRotation.Value;

		if(bLanded)
			return;

		Alpha = Math::Clamp(Alpha + DeltaTime * 2, 0, 1);
		PivotComp.Pivot.ActorLocation = BezierCurve::GetLocation_1CP(StartLocation, StartLocation + FVector::UpVector * 300, TargetLocation, Alpha);

		if(Alpha >= 1)
		{
			bLanded = true;
			FVector Dir = StealComp.HammerComp.HoldHammerComp.Hammer.ActorRightVector;
			StealComp.HammerComp.HoldHammerComp.Hammer.InvertedFauxRotateComp.ApplyImpulse(TargetLocation + FVector::UpVector * 500, Dir * 2000);
		}
	}
}