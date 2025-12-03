
class UGeckoCompanioLeashedBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UGravityWhipResponseComponent WhippedComp;
	UGeckoCompanionTail Tail;

	float WagTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WhippedComp = UGravityWhipResponseComponent::Get(Owner);
		Tail = UGeckoCompanionTail::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WhippedComp.IsGrabbed())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!WhippedComp.IsGrabbed())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Tail.SetElevation(-60.0, 10.0);
		WagTime = 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Tail.SetElevation(0.0, 1.0);
		Tail.StopWagging();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FVector Destination = WhippedComp.DesiredLocation + Game::Zoe.ActorVelocity * 1.0;
		float DestDist = Owner.ActorLocation.Distance(Destination);
		if (DestDist > 120.0)
		{
			float Speed = 250.0;
			if (DestDist > 1000.0)
				Speed = 1000.0;
			else if (DestDist > 500.0)
				Speed = 500.0;
			DestinationComp.MoveTowardsIgnorePathfinding(Destination, Speed);
		}

		if (ActiveDuration > WagTime)
		{
			WagTime = BIG_NUMBER;
			Tail.Wag(60.0, 10.0);
			Tail.SetElevation(-40.0, 2.0);
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorCenterLocation, Destination);
			Debug::DrawDebugLine(Destination, Destination + FVector(0.0, 0.0, 200.0));
		}
#endif		
	}
}