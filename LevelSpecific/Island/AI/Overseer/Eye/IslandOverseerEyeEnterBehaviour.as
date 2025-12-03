
class UIslandOverseerEyeEnterBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	AAIIslandOverseerEye Eye;
	UIslandOverseerEyeSettings Settings;
	bool bArrived;
	float Distance;
	FVector StartLocation;
	float TargetScale = 1.3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		Eye.OnActivated.AddUFunction(this, n"Activated");
		Settings = UIslandOverseerEyeSettings::GetSettings(Owner);
		ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::Get(Owner);
	}

	UFUNCTION()
	private void Activated(AAIIslandOverseerEye ActivatedEye)
	{
		bArrived = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bArrived)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 1)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FVector SideVector = Eye.Boss.ActorRightVector;
		if(!Eye.bBlue)
			SideVector *= -1;
		StartLocation = Owner.ActorLocation + (FVector::DownVector * 200) + (SideVector * 200);
		StartLocation.Y = Game::Mio.ActorLocation.Y;
		UIslandOverseerEyeEventHandler::Trigger_OnEnterStart(Owner);
		ForceFieldBubbleComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bArrived = true;

		Eye.bInAttackSpace = true;
		Eye.Targetable.Enable(Eye);

		Owner.ActorLocation = StartLocation;
		Owner.ActorScale3D = Eye.OriginalScale * TargetScale;

		UHazeCrumbSyncedActorPositionComponent NetworkMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner);
		if (NetworkMotionComp != nullptr && Owner.HasActorBegunPlay())
			NetworkMotionComp.TransitionSync(this);

		UIslandOverseerEyeEventHandler::Trigger_OnEnterEnd(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Eye.AccLocation.SpringTo(StartLocation, 100, 0.25, DeltaTime);
		Owner.ActorLocation = Eye.AccLocation.Value;

		Eye.AccScale.AccelerateTo(Eye.OriginalScale * TargetScale, Settings.EnterDuration, DeltaTime);
		Owner.ActorScale3D = Eye.AccScale.Value;
	}
}