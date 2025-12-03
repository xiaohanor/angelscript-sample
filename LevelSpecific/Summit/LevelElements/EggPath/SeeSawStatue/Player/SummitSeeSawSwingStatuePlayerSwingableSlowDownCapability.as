struct FSummitSeeSawSwingStatuePlayerSwingableSlowDownActivationParams
{
	ASummitSeeSawSwingStatue Statue;
	bool bActivatedForLeftSide = false;
}

struct FSummitSeeSawSwingStatuePlayerSwingableSlowDownDeactivationParams
{
	bool bWentOutOfRange = false;
}

class USummitSeeSawSwingStatuePlayerSwingableSlowDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitSeeSawSwingStatuePlayerComponent StatueComp;
	USwingPointComponent SwingPointWithinRange;
	ASummitSeeSawSwingStatue CurrentStatue;

	UPlayerMovementComponent MoveComp;

	bool bActivatedForLeftSide = false;
	bool bActivatedBigSlowDown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StatueComp = USummitSeeSawSwingStatuePlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitSeeSawSwingStatuePlayerSwingableSlowDownActivationParams& Params) const
	{
		if(DeactiveDuration < 2.0)
			return false;

		if(!Network::IsGameNetworked())
			return false;

		if(StatueComp.Statue.IsSet())
		{
			if(StatueComp.Statue.Value.PlayerSwingingFromLeft == Player
			|| StatueComp.Statue.Value.PlayerSwingingFromRight == Player)
				return false;
		}

		TArray<ASummitSeeSawSwingStatue> Statues = TListedActors<ASummitSeeSawSwingStatue>().Array;
		for(auto Statue : Statues)
		{
			float TimeSinceLastStoppedSwinging = Time::GetGameTimeSince(Statue.LastTimeStoppedSwinging[Player]);
			if(TimeSinceLastStoppedSwinging < 2.0)
				continue;
			
			FVector DirToPlayer = (Player.ActorLocation - Statue.ActorLocation).GetSafeNormal();
			float DirDotForward = DirToPlayer.DotProduct(Statue.ActorRightVector);
			// BEHIND STATUE
			if(DirDotForward < 0)
				continue;

			float DistSqrdToLeftSwingPoint = Player.ActorLocation.DistSquared(Statue.LeftSwingPointComp.WorldLocation);
			if(DistSqrdToLeftSwingPoint < Math::Square(Statue.LeftSwingPointComp.ActivationRange)
			&& !Statue.LeftSwingPointComp.IsDisabledForPlayer(Player))
			{
				Params.Statue = Statue;
				Params.bActivatedForLeftSide = true;
				return true;
			}
			float DistSqrdToRightSwingPoint = Player.ActorLocation.DistSquared(Statue.RightSwingPointComp.WorldLocation);
			if(DistSqrdToRightSwingPoint < Math::Square(Statue.RightSwingPointComp.ActivationRange)
			&& !Statue.RightSwingPointComp.IsDisabledForPlayer(Player))
			{
				Params.Statue = Statue;
				Params.bActivatedForLeftSide = false;
				return true;
			}
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSummitSeeSawSwingStatuePlayerSwingableSlowDownDeactivationParams& Params) const
	{
		if(bActivatedForLeftSide)
		{
			float DistSqrdToLeftSwingPoint = Player.ActorLocation.DistSquared(CurrentStatue.LeftSwingPointComp.WorldLocation);
			if(DistSqrdToLeftSwingPoint > Math::Square(CurrentStatue.LeftSwingPointComp.ActivationRange + CurrentStatue.LeftSwingPointComp.ActivationBufferRange))
			{
				Params.bWentOutOfRange = true;
				return true;
			}

			if(CurrentStatue.PlayerSwingingFromLeft == Player)
			{
				Params.bWentOutOfRange = false;
				return true;
			}
		}
		else
		{
			float DistSqrdToRightSwingPoint = Player.ActorLocation.DistSquared(CurrentStatue.RightSwingPointComp.WorldLocation);
			if(DistSqrdToRightSwingPoint > Math::Square(CurrentStatue.RightSwingPointComp.ActivationRange + CurrentStatue.RightSwingPointComp.ActivationBufferRange))
			{
				Params.bWentOutOfRange = true;
				return true;
			}
			
			if(CurrentStatue.PlayerSwingingFromRight == Player)
			{
				Params.bWentOutOfRange = false;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitSeeSawSwingStatuePlayerSwingableSlowDownActivationParams Params)
	{
		CurrentStatue = Params.Statue;
		USwingPointComponent SwingPointInRangeOf = Params.bActivatedForLeftSide ? 
			CurrentStatue.RightSwingPointComp : 
			CurrentStatue.LeftSwingPointComp;
		SwingPointWithinRange = SwingPointInRangeOf;

		bActivatedForLeftSide = Params.bActivatedForLeftSide;
		bActivatedBigSlowDown = false;

		float PingAlpha = GetPingAlpha();
		if(PingAlpha > SMALL_NUMBER)
		{
			FTimeDilationEffect SlowMoParams = CurrentStatue.SwingableTimeDilationEffect;
			if(CurrentStatue.bBaseTimeDilationOnPing)
				SlowMoParams.TimeDilation = SlowMoParams.TimeDilation * (1 - PingAlpha);
			Player.StartActorTimeDilationEffect(SlowMoParams, CurrentStatue);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSummitSeeSawSwingStatuePlayerSwingableSlowDownDeactivationParams Params)
	{
		if(Params.bWentOutOfRange)
		{
			Player.StopActorTimeDilationEffect(CurrentStatue);
		}
		else
		{
			float PingAlpha = GetPingAlpha();
			if(PingAlpha > SMALL_NUMBER)
			{
				FTimeDilationEffect SlowMoParams = CurrentStatue.SwingStartedTimeDilationEffect;
				if(CurrentStatue.bBaseTimeDilationOnPing)
					SlowMoParams.TimeDilation = SlowMoParams.TimeDilation * (1 - PingAlpha);

				Player.StartActorTimeDilationEffect(SlowMoParams, this);
			}
			bActivatedBigSlowDown = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bActivatedBigSlowDown)
			return;

		TEMPORAL_LOG(Player, "See Saw Swing Time dilation")
			.Value("Ping Alpha", GetPingAlpha())
		;

		if(ShouldDeactivateBigSlowDown())
		{
			Player.StopActorTimeDilationEffect(this);
			Player.StopActorTimeDilationEffect(CurrentStatue);
			bActivatedBigSlowDown = false;
		}
	}

	bool ShouldDeactivateBigSlowDown() const
	{
		if(bActivatedForLeftSide)
		{
			if(CurrentStatue.PlayerSwingingFromRight == Player.OtherPlayer)
				return true;
			if(CurrentStatue.PlayerSwingingFromLeft == nullptr)
				return true;
			if(CurrentStatue.PlayerSwingingFromLeft != Player)
				return true;
		}
		else if(!bActivatedForLeftSide)
		{
			if(CurrentStatue.PlayerSwingingFromLeft == Player.OtherPlayer)
				return true;
			if(CurrentStatue.PlayerSwingingFromRight == nullptr)
				return true;
			if(CurrentStatue.PlayerSwingingFromRight != Player)
				return true;
		}

		return false;
	}

	float GetPingAlpha() const
	{
		return Math::Clamp(Network::PingRoundtripSeconds / CurrentStatue.PingForMaxTimeDilation, 0.0, 1.0);
	}
};