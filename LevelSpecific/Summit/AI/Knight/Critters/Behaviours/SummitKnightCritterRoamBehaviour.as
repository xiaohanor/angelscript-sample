
// Move around randomly when we have no target
class USummitKnightCritterRoamBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitKnightCritterSettings Settings;
	ASummitKnightMobileArena Arena = nullptr;
	FVector Destination;
	float SwitchDestinationTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightCritterSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		if (Arena == nullptr)
			Arena = TListedActors<ASummitKnightMobileArena>().GetSingle();
		SwitchDestinationTime = 0.0;
		Destination = Owner.ActorLocation;
		UBasicAIMovementSettings::SetTurnDuration(Owner, 2.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Arena == nullptr)
		{
			Cooldown.Set(0.5);
			return;
		}

		if ((ActiveDuration > SwitchDestinationTime) || Owner.ActorLocation.IsWithinDist(Destination, 20.0))
		{
			SwitchDestinationTime = ActiveDuration + Math::RandRange(0.7, 1.2);
			Destination = Owner.ActorLocation + Owner.ActorForwardVector * 600.0 + Math::GetRandomPointInCircle_XY() * 200.0;
			Destination = Arena.GetClampedToArena(Destination, 800.0);
		}

		// Face destination and move forward unless we would move off arena edge
		DestinationComp.RotateTowards(Destination);
		FVector AheadLoc = Owner.ActorLocation + Owner.ActorForwardVector * 100.0;
		if (Arena.IsInsideArena(AheadLoc, 80.0))
			DestinationComp.MoveTowardsIgnorePathfinding(AheadLoc, Settings.ChaseMoveSpeed);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Destination, Owner.ActorCenterLocation, FLinearColor::Yellow, 5.0);	
			Debug::DrawDebugLine(Destination, Destination + FVector(0.0, 0.0, 100.0), FLinearColor::Green, 10.0);	
		}
#endif		
	}
}