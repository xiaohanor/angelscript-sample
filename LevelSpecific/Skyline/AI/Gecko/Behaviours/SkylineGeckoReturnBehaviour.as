class USkylineGeckoReturnBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAICharacterMovementComponent MoveComp;
	UWallclimbingComponent WallClimbingComp;
	USkylineGeckoComponent GeckoComp;
	USkylineGeckoSettings GeckoSettings;
	bool bGrabbed;
	bool bFoundDestination;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoSettings = USkylineGeckoSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		WallClimbingComp = UWallclimbingComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);

		auto WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");		
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if(!IsActive())
			return;
		bGrabbed = true;
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bGrabbed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagGecko::Overturned, SubTagGeckoOverturned::OverturnedReturn, EBasicBehaviourPriority::Medium, Owner);
		bFoundDestination = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		AnimComp.ClearFeature(Owner);
	}

	FVector PrevLocation;
	float StuckDuration = 0;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bFoundDestination && DestinationComp.MoveFailed())
			bFoundDestination = false;

		// Hack in case we get stuck. Remove when path following is more dependable
		if (bFoundDestination)
		{
			if (Owner.ActorLocation.IsWithinDist(PrevLocation, DeltaTime * 100.0))
				StuckDuration += DeltaTime;
			else
				StuckDuration = 0.0;
			PrevLocation = Owner.ActorLocation;
			if (StuckDuration > 1.0)
				bFoundDestination = false;
		}

		if (!bFoundDestination && (WallClimbingComp.Navigation != nullptr))
		{
			// Try a new destination
			FVector TestNormal = -WallClimbingComp.PreferredGravity;
			FVector TestX = TestNormal.CrossProduct((Math::Abs(TestNormal.DotProduct(FVector::RightVector)) < 0.9999) ? FVector::RightVector : FVector::ForwardVector);
			FVector TestY = TestNormal.CrossProduct(TestX);
			FVector TestLoc = GeckoComp.OverturnedLocation + TestX * Math::RandRange(-800, 800) + TestY * Math::RandRange(-800, 800) + TestNormal * 100.0;
			int iPoly = WallClimbingComp.Navigation.FindPoly(TestLoc, -WallClimbingComp.PreferredGravity, 80, 400, 400);	
			if (WallClimbingComp.Navigation.NavMesh.IsValidIndex(iPoly))
			{
				bFoundDestination = true;
				Destination = WallClimbingComp.Navigation.NavMesh[iPoly].Center;
			}
		} 

		if (bFoundDestination && ActiveDuration > GeckoSettings.ReturnStartDuration)
		{
			// Go there!
			AnimComp.ClearFeature(Owner);
			DestinationComp.MoveTowards(Destination, GeckoSettings.ReturnSpeed);
			if ((Owner.ActorUpVector.DotProduct(-WallClimbingComp.PreferredGravity) > 0.707) && 
				Pathfinding::IsPathNear(Destination, Owner.ActorLocation, 200.0, 100.0, -WallClimbingComp.PreferredGravity))
				DeactivateBehaviour(); // We're there!	
		}
	}
}