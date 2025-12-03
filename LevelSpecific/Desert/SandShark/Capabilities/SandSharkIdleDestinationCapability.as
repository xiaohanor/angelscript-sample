class USandSharkIdleDestinationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Chase);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::AttackLunge);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 0;
	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;
	USandSharkSettings SharkSettings;

	bool bHasBlockedTags = false;
	bool bHasReachedSpline = false;

	UHazeSplineComponent PrevSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		SharkSettings = USandSharkSettings::GetSettings(Owner);
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
		SandShark.DestinationComp.Update();
		if (bHasBlockedTags)
			SandShark.UnblockCapabilities(SandSharkTags::SandSharkIdle, this);
		bHasBlockedTags = false;
		bHasReachedSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SandShark.BlockCapabilities(SandSharkTags::SandSharkIdle, this);
		bHasBlockedTags = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;

		SandShark.DestinationComp.Update();
		FSplinePosition NewSplinePosition = SandShark.GetCurrentSpline().Spline.GetClosestSplinePositionToWorldLocation(SandShark.ActorLocation);
		//Debug::DrawDebugSphere(NewSplinePosition.WorldLocation);

		if (NewSplinePosition.CurrentSpline != PrevSpline)
		{
			bHasReachedSpline = false;
		}

		PrevSpline = NewSplinePosition.CurrentSpline;
		
		if (NewSplinePosition.WorldLocation.Dist2D(SandShark.ActorLocation) < 10 || bHasReachedSpline)
		{
			NewSplinePosition.MatchFacingTo(SandShark.ActorRotation);
			bHasReachedSpline = true;
			SandShark.DestinationComp.FollowSpline = NewSplinePosition.CurrentSpline;
			SandShark.DestinationComp.FollowSplinePosition = NewSplinePosition;
			SandShark.DestinationComp.MoveAlongSpline(SandShark.DestinationComp.FollowSplinePosition.CurrentSpline, SharkSettings.IdleSplineFollowSpeed, SandShark.DestinationComp.FollowSplinePosition.IsForwardOnSpline());
			MoveComp.UpdateMoveSplinePosition(SandShark.DestinationComp.FollowSplinePosition);
		}
		else
		{
			NewSplinePosition.Move(500);
			SandShark.DestinationComp.MoveTowards(NewSplinePosition.WorldLocation, 1000);
			MoveComp.UpdateMoveSplinePosition(NewSplinePosition);
		}
		//SandShark.MoveToComp.Path.DrawDebugSpline();
	}
};