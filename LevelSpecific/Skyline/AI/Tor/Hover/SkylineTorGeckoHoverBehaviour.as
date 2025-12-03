class USkylineTorGeckoHoverBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Hover");
	USkylineTorHoverComponent HoverComp;
	USkylineTorSettings Settings;
	FHazeAcceleratedVector AccLocation;
	UHazeOffsetComponent OffsetComp;
	USkylineTorHammerResponseComponent ThrownGeckoResponseComp;
	ASplineActor SplineActor;
	FHazeAcceleratedFloat Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		OffsetComp = UHazeOffsetComponent::GetOrCreate(Owner);
		ThrownGeckoResponseComp = USkylineTorHammerResponseComponent::GetOrCreate(Owner);
		SplineActor = TListedActors<ASkylineTorReferenceManager>().Single.CircleMovementSplineActor;
		Settings = USkylineTorSettings::GetSettings(Owner);
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
		AccLocation.SnapTo(Owner.ActorLocation);
		HoverComp.StartHover(this);
		Speed.SnapTo(0.0); // Snap to velocity projected onto spline tangent if we need to maintain momentum
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HoverComp.ClearHover(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HoverComp.StartHover(this);
		
		// Circle around to stay near view front of whip wielder
		AHazePlayerCharacter Whipper = Game::Zoe;
		FVector ViewFwd = Whipper.ViewRotation.ForwardVector.GetSafeNormal2D();
		if ((ViewFwd.DotProduct((Owner.ActorCenterLocation - Whipper.ViewLocation).GetSafeNormal2D()) > 0.866))
		{
			// To the front, pause
			Speed.AccelerateTo(0.0, 5.0, DeltaTime);
		}
		else if (DestinationComp.FollowSplinePosition.IsValid())
		{
			// Circle
			float CircleSpeed = 500.0;
			if (DestinationComp.FollowSplinePosition.WorldForwardVector.DotProduct(ViewFwd) < 0.0)
				CircleSpeed = -500.0;
			Speed.AccelerateTo(CircleSpeed, 3.0, DeltaTime);
		}

		DestinationComp.MoveAlongSpline(SplineActor.Spline, Math::Abs(Speed.Value), (Speed.Value > 0.0));
	}
}
