class UJetskiDriverDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Death);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UJetskiDriverComponent DriverComp;
	UPlayerRespawnComponent RespawnComp;

	TOptional<FVector> RequestedRespawnLocation;
	TOptional<float> WaveHeightAtRespawnLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
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
		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"GetRespawnLocation");
		RespawnComp.ApplyRespawnOverrideDelegate(this, RespawnOverride, EInstigatePriority::High);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnComp.ClearRespawnOverride(this);
		RespawnComp.OnPlayerRespawned.UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		auto Jetski = DriverComp.Jetski;

		if(RespawnComp.bIsRespawning)
		{
			// We are respawning, update the wave height at our requested respawn location
			if(RequestedRespawnLocation.IsSet())
			{
				OceanWaves::RequestWaveData(this, RequestedRespawnLocation.Value);
				
				if(OceanWaves::IsWaveDataReady(this))
				{
					WaveHeightAtRespawnLocation = OceanWaves::GetLatestWaveData(this).PointOnWave.Z;
				}
			}
		}
		else
		{
#if !RELEASE
			if(DevTogglesJetski::AutoKill.IsEnabled(Player))
			{
				Player.KillPlayer();
				return;
			}
#endif

			if(Jetski.DeathImpactThisFrame())
			{
				// The resolver has decided that we should die, and we don't really want to refuse to do what the resolver
				// tells us to because the resolver is old and wise, and the jetski is young and impressionable.
				Player.KillPlayer();
				return;
			}

			if(Jetski.MoveComp.HasImpactedWall() || Jetski.MoveComp.HasImpactedCeiling())
			{
				// Any hits kill us if we are facing backwards
				// This may be wacky, needs testing
				float JetskiDirectionDot = Jetski.ActorForwardVector.DotProduct(Jetski.GetSplineForward());
				bool bJetskiFacingBackwards = JetskiDirectionDot < 0;
				if(bJetskiFacingBackwards)
				{
					Player.KillPlayer();
					return;
				}
			}
		}
	}

	UFUNCTION()
	private bool GetRespawnLocation(AHazePlayerCharacter RespawnPlayer, FRespawnLocation& OutLocation)
	{
		FTransform RespawnTransform;
		if(!RespawnPlayer.OtherPlayer.IsPlayerDead())
		{
			const AHazePlayerCharacter OtherPlayer = RespawnPlayer.OtherPlayer;
			RespawnTransform = Jetski::GetClosestRespawnSpline(OtherPlayer.ActorLocation).Spline.GetClosestSplineWorldTransformToWorldLocation(OtherPlayer.ActorLocation);
		}
		else
		{
			const AJetskiFollowingDeath FollowingDeath = AJetskiFollowingDeath::Get();
			const AJetskiRespawnSpline RespawnSpline = Jetski::GetClosestRespawnSpline(FollowingDeath.ActorLocation);
			
			const float FollowingDeathDistanceAlongRespawnSpline = RespawnSpline.Spline.GetClosestSplineDistanceToWorldLocation(FollowingDeath.ActorLocation);
			const float LeadDistance = Math::Lerp(FollowingDeath.MinSpeedMargin, FollowingDeath.MaxSpeedMargin, 0.5);
			RespawnTransform = DriverComp.Jetski.JetskiSpline.Spline.GetWorldTransformAtSplineDistance(FollowingDeathDistanceAlongRespawnSpline + LeadDistance);
		}

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(DriverComp.Jetski.MoveComp);

		bool bRespawnOnWater = false;
		if(WaveHeightAtRespawnLocation.IsSet())
		{
			if(Math::Abs(RespawnTransform.Location.Z - WaveHeightAtRespawnLocation.Value) < Jetski::Radius * 2)
			{
				// We are close enough that our respawn is almost touching water, so respawn on it!
				FVector RespawnLocation = RespawnTransform.Location;
				RespawnLocation.Z = WaveHeightAtRespawnLocation.Value;
				RespawnTransform.SetLocation(RespawnLocation);
				bRespawnOnWater = true;
			}
		}

		// Sweep down to find valid ground
		const FHitResult Hit = TraceSettings.QueryTraceSingle(
			RespawnTransform.Location + (FVector::UpVector * Jetski::Radius * 2),
			RespawnTransform.Location - (FVector::UpVector * Jetski::Radius * 2)
		);

		if(Hit.IsValidBlockingHit())
		{
			// We found ground!
			if(bRespawnOnWater && WaveHeightAtRespawnLocation.Value > Hit.Location.Z)
			{
				// If we respawned on the water, and the water is above the hit, ignore it
			}
			else
			{
				RespawnTransform.SetLocation(Hit.Location + Hit.Normal);
			}
		}

		// Respawn on the respawn spline
		FRespawnLocation RespawnLocation;
		RespawnLocation.RespawnTransform = RespawnTransform;
		RespawnLocation.bRecalculateOnRespawnTriggered = true;
		OutLocation = RespawnLocation;

		RequestedRespawnLocation = RespawnTransform.Location;

#if !RELEASE
		TEMPORAL_LOG(this, Player, "Jetski")
			.Event("GetRespawnLocation")
			.Transform("RespawnTransform", RespawnTransform)
			.HitResults("Validation Sweep", Hit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset)
			.Transform("Player Transform", Player.ActorTransform)
			.Value("Player Attachment", Player.RootComponent.AttachParent)
			.Value("Jetski Transform", DriverComp.Jetski.ActorTransform)
		;
#endif

		return true;
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
#if !RELEASE
		TEMPORAL_LOG(this, Player, "Jetski")
			.Event("OnPlayerRespawned")
			.Transform("Player Transform", RespawnedPlayer.ActorTransform)
			.Value("Player Attachment", Player.RootComponent.AttachParent)
			.Value("Jetski Transform", DriverComp.Jetski.ActorTransform)
		;
#endif

		DriverComp.Jetski.SetActorTransform(RespawnedPlayer.ActorTransform);
		RespawnedPlayer.SetActorRelativeTransform(FTransform::Identity);

		DriverComp.Jetski.SetActorVelocity(DriverComp.Jetski.GetHorizontalForward(EJetskiUp::Global) * DriverComp.Jetski.MoveComp.MovementSettings.MaxSpeed);
		DriverComp.Jetski.SnapAcceleratedUp(RespawnedPlayer.ActorQuat);

		RequestedRespawnLocation.Reset();
		WaveHeightAtRespawnLocation.Reset();
		OceanWaves::RemoveWaveDataInstigator(this);
	}
};