struct FJetskiDriverTutorialActivateParams
{
	AJetskiTutorialActor TutorialActor;
};

struct FJetskiDriverTutorialDeactivateParams
{
	bool bFinished = false;
};

class UJetskiDriverTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UJetskiDriverComponent DriverComp;
	UJetskiDriverTutorialComponent TutorialComp;
	AJetskiTutorialActor TutorialActor;

	bool bShouldDeactivate = false;
	float DeactivationTimer = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
		TutorialComp = UJetskiDriverTutorialComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJetskiDriverTutorialActivateParams& Params) const
	{
		if(!TutorialComp.bShouldShowDiveTutorial && !TutorialComp.bShouldShowAccelerationTutorial)
			return false;

		if(TutorialComp.TutorialActor == nullptr)
			return false;

		Params.TutorialActor = TutorialComp.TutorialActor;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bShouldDeactivate)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FJetskiDriverTutorialActivateParams Params)
	{
		TutorialActor = Params.TutorialActor;
		bShouldDeactivate = false;
		DeactivationTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FollowJetski();

		// Delaying the deactivation a bit so that the widget have time to fade away completely before we stop following the jetski.
		if(!TutorialComp.bShouldShowDiveTutorial && !TutorialComp.bShouldShowAccelerationTutorial)
		{
			DeactivationTimer += DeltaTime;
			if(DeactivationTimer >= 2)
			{
				bShouldDeactivate = true;
			}
		}
	}

	void FollowJetski()
	{
		if(DriverComp.Jetski == nullptr)
			return;

		FVector Location = DriverComp.Jetski.ActorLocation;
		FRotator Rotation = FRotator::MakeFromXZ(DriverComp.Jetski.ActorForwardVector, FVector::UpVector);
		TutorialActor.SetActorLocationAndRotation(Location, Rotation);
	}
};