struct FSummitGeyserBuildUpFeedbackParams
{
	ASummitGeyser ClosestGeyser;
	float HighestBuildUpAlpha;
}

class USummitGeyserBuildUpFeedbackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::Gameplay;

	UCameraShakeBase BuildUpCameraShake;
	ASummitGeyser CurrentBuildUpGeyser;

	const float BuildUpShakeFallOff = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto ListedGeysers = TListedActors<ASummitGeyser>().Array;
		if(ListedGeysers.IsEmpty())
			return false;

		for(auto Geyser : ListedGeysers)
		{
			if(!Geyser.bTimedEruption)
				continue;

			float DistToGeyserSqrd = Player.ActorLocation.DistSquared(Geyser.ActorLocation);
			if(DistToGeyserSqrd < Math::Square(Geyser.BuildUpCameraShakeMaxDistance))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto ListedGeysers = TListedActors<ASummitGeyser>().Array;
		if(ListedGeysers.IsEmpty())
			return true;

		for(auto Geyser : ListedGeysers)
		{
			if(!Geyser.bTimedEruption)
				continue;

			float DistToGeyserSqrd = Player.ActorLocation.DistSquared(Geyser.ActorLocation);
			if(DistToGeyserSqrd < Math::Square(Geyser.BuildUpCameraShakeMaxDistance))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Params = GetClosestGeyser();
		if(Params.IsSet())
		{
			BuildUpCameraShake = PlayCameraShakeBasedOnParams(Params.Value);
			CurrentBuildUpGeyser = Params.Value.ClosestGeyser;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopCameraShakeInstance(BuildUpCameraShake);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Params = GetClosestGeyser();
		if(!Params.IsSet())
			return;

		ASummitGeyser ClosestGeyser = Params.Value.ClosestGeyser;
		if(ClosestGeyser != CurrentBuildUpGeyser
		|| BuildUpCameraShake == nullptr)
		{
			Player.StopCameraShakeInstance(BuildUpCameraShake);
			BuildUpCameraShake = PlayCameraShakeBasedOnParams(Params.Value);
			CurrentBuildUpGeyser = ClosestGeyser;
		}

		if(BuildUpCameraShake != nullptr)
		{
			float ShakeAlpha = Math::EaseIn(0.0, 1.0, ClosestGeyser.GetEruptionBuildUpAlpha(), 2);
			BuildUpCameraShake.ShakeScale = ShakeAlpha;
		}

		SetRumbleBasedOnParams(Params.Value);
	}

	TOptional<FSummitGeyserBuildUpFeedbackParams> GetClosestGeyser() const
	{
		TOptional<FSummitGeyserBuildUpFeedbackParams> Params;
		ASummitGeyser ClosestGeyser = nullptr;
		auto ListedGeysers = TListedActors<ASummitGeyser>().Array;
		if(ListedGeysers.IsEmpty())
			return Params;
		
		float ClosestDistSqrd = MAX_flt;
		float HighestBuildUpAlpha = -MAX_flt;
		for(auto Geyser : ListedGeysers)
		{
			if(!Geyser.bTimedEruption)
				continue;

			const float DistSqrd = Geyser.ActorLocation.DistSquared(Player.ActorLocation);
			if(DistSqrd < ClosestDistSqrd)
			{
				ClosestGeyser = Geyser;
				ClosestDistSqrd = DistSqrd;
			}

			const float BuildUpAlpha = Geyser.GetEruptionBuildUpAlpha();
			if(BuildUpAlpha > HighestBuildUpAlpha)
				HighestBuildUpAlpha = BuildUpAlpha;
		}

		FSummitGeyserBuildUpFeedbackParams NewParams;
		NewParams.ClosestGeyser = ClosestGeyser;
		NewParams.HighestBuildUpAlpha = HighestBuildUpAlpha;

		Params.Set(NewParams);

		return Params;
	}

	UCameraShakeBase PlayCameraShakeBasedOnParams(FSummitGeyserBuildUpFeedbackParams Params)
	{
		ASummitGeyser Geyser = Params.ClosestGeyser;
		return Player.PlayWorldCameraShake(Geyser.BuildUpCameraShake
			, this
			, Geyser.ActorLocation
			, 0.0
			, Geyser.BuildUpCameraShakeMaxDistance
			, BuildUpShakeFallOff
			, 0.01);
	}

	void SetRumbleBasedOnParams(FSummitGeyserBuildUpFeedbackParams Params)
	{
		ASummitGeyser Geyser = Params.ClosestGeyser;
		if(Geyser == nullptr)
			return;
		
		FHazeDirectionalForceFeedbackParams Rumble;
		float RumbleIntensity = Math::EaseIn(0.0, 1.0, Geyser.GetEruptionBuildUpAlpha() * Geyser.BuildUpRumbleMaxIntensity, 2.5);
		Rumble.Intensity = RumbleIntensity;
		Rumble.WorldLocation = Geyser.ActorLocation;
		Player.SetFrameDirectionalForceFeedback(Rumble);
	}
};