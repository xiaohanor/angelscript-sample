class USandSharkHazardAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USandSharkHazardComponent HazardComp;
	FVector SurfaceLocation;
	FVector DiveLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HazardComp = USandSharkHazardComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HazardComp.Hazard.TimeAlive >= SandSharkHazard::Shark::LifeTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DiveLocation = HazardComp.Hazard.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HazardComp.Hazard.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float HeightAlpha = HazardComp.HeightAlphaCurve.GetFloatValue(ActiveDuration);
		float Height = Math::Lerp(0, SandSharkHazard::Shark::AttackHeight, HeightAlpha);

		FVector NewLocation = DiveLocation + FVector::UpVector*Height;
		FQuat NewRotation = Math::QInterpConstantTo(HazardComp.Hazard.ActorQuat, FQuat::MakeFromX(HazardComp.TargetPlayer.ActorLocation - HazardComp.Hazard.ActorLocation), DeltaTime, 20);
		HazardComp.Hazard.SetActorLocationAndRotation(NewLocation, NewRotation);

		if (HazardComp.Hazard.TimeAlive > SandSharkHazard::Shark::TimeToKillPlayer)
		{
			HazardComp.TargetPlayer.KillPlayer();
		}
	}
};