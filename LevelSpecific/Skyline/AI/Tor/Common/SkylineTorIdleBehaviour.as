
class USkylineTorIdleBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USkylineTorHoldHammerComponent HoldHammerComp;
	ASkylineTorCenterPoint CenterPoint;
	float Distance = 1000;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		CenterPoint = TListedActors<ASkylineTorCenterPoint>().Single;

		auto MusicManager = UHazeAudioMusicManager::Get();
		if(MusicManager != nullptr)
		{
			MusicManager.OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
		}
	}

	UFUNCTION()
	private void OnMusicBeat()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		USkylineTorEventHandler::Trigger_OnIdleStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnIdleStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Direction = (Owner.ActorLocation - CenterPoint.ActorLocation).GetSafeNormal2D();
		FVector TargetLocation = CenterPoint.ActorLocation + Direction.RotateAngleAxis(10, FVector::UpVector) * Distance;
		DestinationComp.MoveTowardsIgnorePathfinding(TargetLocation, 350);

		if(LookAtHammer())
			DestinationComp.RotateTowards(HoldHammerComp.Hammer);
		else
			DestinationComp.RotateTowards(CenterPoint.ActorLocation);
	}

	bool LookAtHammer()
	{
		if(HoldHammerComp.Hammer.HammerComp.CurrentMode == ESkylineTorHammerMode::Idle)
			return false;
		if(HoldHammerComp.Hammer.HammerComp.CurrentMode == ESkylineTorHammerMode::Return)
			return false;
		if(HoldHammerComp.Hammer.HammerComp.bRecall)
			return false;
		return true;
	}
}