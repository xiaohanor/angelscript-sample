class USanctuaryGhostAvoidanceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryGhost");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryGhost Ghost;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ghost = Cast<ASanctuaryGhost>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TListedActors<ASanctuaryGhost> Ghosts;
		FVector Avoidance;
		FVector ToTarget = Ghost.TargetPlayer.ActorLocation - Ghost.ActorLocation;
		
		for (auto OtherGhost : Ghosts)
		{
			FVector ToOtherGhost = Ghost.ActorLocation - OtherGhost.ActorLocation;
			float Distance = ToOtherGhost.Size();

			if (Distance < Ghost.AvoidanceRange)
			{
				Avoidance += ToOtherGhost.SafeNormal * (Ghost.AvoidanceRange - Distance);
			}
		}

		Avoidance = Avoidance.ProjectOnToNormal(ToTarget.SafeNormal.CrossProduct(FVector::UpVector));

		Ghost.Avoidance = Avoidance;
	//	Debug::DrawDebugLine(Ghost.ActorLocation, Ghost.ActorLocation + Ghost.Avoidance, FLinearColor::Red, 5.0, 0.0);
	}
};