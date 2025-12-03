class UDesertGrappleFishPlayerDeathCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);

	default TickGroup = EHazeTickGroup::Gameplay;

	UDesertGrappleFishPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsPlayerDead())
			return false;

		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (PlayerComp.GrappleFish == nullptr)
			return false;

		if (PlayerComp.GrappleFish.DeathCamera == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsPlayerDead())
			return true;

		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return true;

		if (PlayerComp.GrappleFish == nullptr)
			return true;

		if (PlayerComp.GrappleFish.DeathCamera == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Spline = PlayerComp.GrappleFish.DeathCameraSpline.Spline;
		auto SplinePos = Spline.GetClosestSplinePositionToWorldLocation(PlayerComp.GrappleFish.ActorLocation);
		SplinePos.Move(-500);
		PlayerComp.GrappleFish.DeathCamera.SetActorLocation(SplinePos.WorldLocation);
		Player.ActivateCamera(PlayerComp.GrappleFish.DeathCamera, 2, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(PlayerComp.GrappleFish.DeathCamera);
	}
};