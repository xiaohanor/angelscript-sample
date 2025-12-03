struct FSanctuaryLightDiscFollowActivateParams
{
	ASanctuaryDynamicLightDisc LightDisc;
	FVector InitialFollowLocation;
};

/**
 * InheritMovement behaviour for standing on Light Discs
 */
class USanctuaryLightDiscFollowCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;	// Crumbed since the remote also needs to move the follow component

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;

	ASanctuaryDynamicLightDisc LightDisc;
	USceneComponent FollowComp;
	FVector InitialHorizontalLocation;
	FVector PreviousLightDiscLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryLightDiscFollowActivateParams& Params) const
	{
		if(!MoveComp.IsOnWalkableGround())
			return false;

		auto GroundLightDisc = Cast<ASanctuaryDynamicLightDisc>(MoveComp.GroundContact.Actor);
		if(GroundLightDisc == nullptr)
			return false;

		Params.LightDisc = GroundLightDisc;
		Params.InitialFollowLocation = GroundLightDisc.DynamicLightDiscComponent.WorldLocation;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsValid(LightDisc))
			return true;

		if(!LightDisc.bIsActivated)
			return true;

		const FVector RelativeToLightDisc = LightDisc.DynamicLightDiscComponent.WorldTransform.InverseTransformPositionNoScale(Player.ActorCenterLocation);
		if(RelativeToLightDisc.Size2D() > LightDisc.DynamicLightDiscComponent.Radius)
			return true;

		if(MoveComp.IsOnAnyGround())
		{
			if(!MoveComp.GroundContact.Component.IsA(USanctuaryDynamicLightDiscComponent))
				return true;
		}
		else
		{
			// If we are airborne, and the disc is moving downwards, we don't want to follow it
			FVector LightDiscDelta = LightDisc.DynamicLightDiscComponent.WorldLocation - PreviousLightDiscLocation;
			if(LightDiscDelta.DotProduct(MoveComp.WorldUp) < 0)
				return true;

			// Check if there is a light disc underneath us, if not, stop following
			FHazeTraceSettings TraceSettings = Trace::InitAgainstComponent(LightDisc.DynamicLightDiscComponent);
			TraceSettings.UseLine();

			const FVector Start = Player.ActorCenterLocation;
			const FVector End = Start - Player.MovementWorldUp * 1000;
			const FHitResult Hit = TraceSettings.QueryTraceComponent(Start, End);

			if(!Hit.IsValidBlockingHit())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryLightDiscFollowActivateParams Params)
	{
		LightDisc = Params.LightDisc;
		InitialHorizontalLocation = Params.InitialFollowLocation.VectorPlaneProject(FVector::UpVector);

		const FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
		FName FollowCompName = FName(f"LightDiscFollowComp_{PlayerName}");
		FollowComp = USceneComponent::GetOrCreate(LightDisc, FollowCompName);
		FollowComp.SetWorldLocation(GetFollowLocation());

		MoveComp.ApplyCrumbSyncedRelativePosition(this, FollowComp);

		PreviousLightDiscLocation = LightDisc.DynamicLightDiscComponent.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		FollowComp = nullptr;
		LightDisc = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector FollowLocation = GetFollowLocation();
		FollowComp.SetWorldLocation(FollowLocation);
		PreviousLightDiscLocation = FollowLocation;
	}

	FVector GetFollowLocation() const
	{
		if(LightDisc.DynamicLightDiscComponent.HasTag(ComponentTags::InheritHorizontalMovementIfGround))
		{
			return LightDisc.DynamicLightDiscComponent.WorldLocation;
		}
		else
		{
			const FVector NewVerticalLocation = LightDisc.DynamicLightDiscComponent.WorldLocation.ProjectOnToNormal(FVector::UpVector);
			return InitialHorizontalLocation + NewVerticalLocation;
		}
	}
};