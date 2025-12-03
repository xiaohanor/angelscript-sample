class UTundraGnatShakenOffBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UTundraGnatSettings Settings;
	UTundraGnatComponent GnatComp;
	FVector PushDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnatComp = UTundraGnatComponent::Get(Owner); 
		Settings = UTundraGnatSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		GnatComp.bShakenOff = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!GnatComp.bShakenOff)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.ShakeOffStunnedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GnatComp.bShakenOff = false;
		PushDir = (Owner.ActorLocation - Game::Zoe.ActorLocation).GetSafeNormal2D() * 0.866;
		PushDir.Z = 0.5;

		AnimComp.RequestFeature(TundraGnatTags::Stunned, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float PushTime  = 0.3;
		if (ActiveDuration < PushTime)
			DestinationComp.AddCustomAcceleration(PushDir * Settings.ShakeOffForce / PushTime);
	}
}
