struct FAdultDragonStrafeRespawnParams
{
	AActor CurrentFollowingSplineActor;
	FTransform RespawnTransform;
}

class UAdultDragonStrafeRespawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonStrafeRespawn);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UAdultDragonStrafeSettings StrafeSettings;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;

	FAdultDragonStrafeRespawnParams RespawnParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
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
		Player.OtherPlayer.ClearRespawnPointOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Settings = UAdultDragonSplineFollowRubberBandingSettings::GetSettings(Player);
		// PrintToScreen("PreferredAheadPlayer: " + Settings.PreferredAheadPlayer);

		if (SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
		{
			FAdultDragonSplineFollowData Data = SplineFollowManagerComp.GetSplineFollowData();

			// While we are in strafe mode, we override the respawn to be next to the other player
			FTransform SplineTransform = Data.WorldTransform;
			SplineTransform = SplineTransform.GetRelativeTransform(Player.ActorTransform);
			const FVector Forward = SplineTransform.Rotation.ForwardVector;

			// If the spline is to far away, just respawn at the player location
			if (SplineTransform.Location.SizeSquared() > Math::Square(5000))
				SplineTransform = FTransform::Identity;

			// Don't know why the values need to be opposite for putting one player behind or more in front, but this seems to work
			float ForwardOffset = 1000.0;

			if (UAdultDragonSplineFollowRubberBandingSettings::GetSettings(Player).PreferredAheadPlayer == EHazePlayer::Zoe && Player.IsZoe())
			{
				ForwardOffset = -4000.0;
			}

			// always spawn a bit behind the other player so we get a feeling for where we are going
			SplineTransform.AddToTranslation(Forward * ForwardOffset);

			RespawnParams.CurrentFollowingSplineActor = SplineFollowManagerComp.CurrentSplineActor;
			RespawnParams.RespawnTransform = SplineTransform;
			Player.OtherPlayer.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"));
		}
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter RespawningPlayer, FRespawnLocation& OutLocation)
	{
		if (RespawnParams.CurrentFollowingSplineActor == nullptr)
			return false;

		OutLocation.RespawnTransform = RespawnParams.RespawnTransform;
		OutLocation.RespawnRelativeTo = Player.RootComponent;
		UAdultDragonSplineFollowManagerComponent::Get(RespawningPlayer).SetSplineToFollow(RespawnParams.CurrentFollowingSplineActor, false);
		return true;
	}
};