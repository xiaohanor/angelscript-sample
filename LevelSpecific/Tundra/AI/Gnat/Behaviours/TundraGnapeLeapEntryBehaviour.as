class UTundraLeapEntryBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;
	UTundraGnatComponent GnatComp;
	UTundraGnatSettings Settings;
	float MoveTime;
	FHazeAcceleratedFloat AccScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnatComp = UTundraGnatComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");	
		Settings = UTundraGnatSettings::GetSettings(Owner); 
	}

	UFUNCTION()
	private void OnRespawn()
	{
		GnatComp.bHasCompletedEntry = false;
		if (RespawnComp.Spawner == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (GnatComp.bHasCompletedEntry)
			return false;
		if (GnatComp.LeapEntryTarget == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (GnatComp.bHasCompletedEntry)
			return true;
		if (GnatComp.LeapAlpha > 1.0 - SMALL_NUMBER)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		MoveTime = BIG_NUMBER;
		AccScale.SnapTo(Owner.ActorScale3D.Z);
		AnimComp.RequestFeature(TundraGnatTags::Leaping, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GnatComp.LeapEntryTarget = nullptr;
		GnatComp.bHasCompletedEntry = true;
		Owner.SetActorScale3D(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Scale us during leap in case we started scaled up for visibility
		float LeapScale = AccScale.AccelerateTo(1.0, Settings.LeapEntryDuration, DeltaTime);
		Owner.SetActorScale3D(FVector::OneVector * LeapScale);
	}
}
