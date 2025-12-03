class USummitRaftPlayerLaunchZoneComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FVector ForwardLocationLaunchVelocity = FVector(1000, 0, 1500);

	UPROPERTY(EditAnywhere)
	FVector BackLocationLaunchVelocity = FVector(1000, 0, 2500);

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bUseHighestPointAsLaunchDuration == false", UIMin = "0.0", ClampMin = "0"))
	float LaunchDuration = 0.5;

	UPROPERTY(EditAnywhere)
	bool bUseHighestPointAsLaunchDuration = true;

	TPerPlayer<bool> LaunchedPlayers;
	TPerPlayer<UPlayerJumpComponent> PlayerJumpComps;
	TPerPlayer<UPlayerSlideJumpComponent> PlayerSlideJumpComps;

	ASummitRaftPlayerLaunchZone LaunchZone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchZone = Cast<ASummitRaftPlayerLaunchZone>(Owner);
		PlayerJumpComps[Game::Mio] = UPlayerJumpComponent::Get(Game::Mio);
		PlayerJumpComps[Game::Zoe] = UPlayerJumpComponent::Get(Game::Zoe);
		PlayerSlideJumpComps[Game::Mio] = UPlayerSlideJumpComponent::Get(Game::Mio);
		PlayerSlideJumpComps[Game::Zoe] = UPlayerSlideJumpComponent::Get(Game::Zoe);

		PlayerJumpComps[Game::Mio].OnJump.AddUFunction(this, n"OnPlayerJump");
		PlayerJumpComps[Game::Zoe].OnJump.AddUFunction(this, n"OnPlayerJump");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Player : Game::Players)
		{
			if (!LaunchZone.PlayersInZone[Player])
				continue;

			// Poll slidejump as we don't have event for when those jumps are activated currently
			auto SlideJumpComp = PlayerSlideJumpComps[Player];
			if (SlideJumpComp.bStartedJump || SlideJumpComp.bJump)
			{
				OnPlayerJump(Player);
			}
		}
	}

	void ForceLaunch(AHazePlayerCharacter Player)
	{
		OnPlayerJump(Player);
	}

	UFUNCTION()
	private void OnPlayerJump(AHazePlayerCharacter Player)
	{
		if (LaunchedPlayers[Player])
			return;

		if (LaunchZone.PlayersInZone[Player])
		{
			// Block slidejump and turn off the bools as the slidejumpstartup sets them to true in ondeactivate
			Player.BlockCapabilities(PlayerSlideTags::SlideJump, this);
			PlayerSlideJumpComps[Player].bJump = false;
			PlayerSlideJumpComps[Player].bStartedJump = false;
			Player.UnblockCapabilities(PlayerSlideTags::SlideJump, this);

			Player.SetActorVelocity(FVector::ZeroVector);
			LaunchedPlayers[Player] = true;
			FPlayerLaunchToParameters LaunchParams;

			FVector Origin = Player.ActorLocation;
			FVector Velocity = GetLaunchVelocity(LaunchZone, Origin);
			float Duration = LaunchDuration;

			if (bUseHighestPointAsLaunchDuration)
			{
				float GravityMagnitude = 2385;
				FVector HighestPoint = Trajectory::TrajectoryHighestPoint(Origin, Velocity, GravityMagnitude);
				Duration = Trajectory::GetTimeToReachTarget(HighestPoint.Z - Player.ActorLocation.Z, Velocity.Z, GravityMagnitude);
			}

			LaunchParams.Duration = Duration;
			LaunchParams.LaunchImpulse = LaunchZone.ActorTransform.TransformVectorNoScale(Velocity);
			LaunchParams.Type = EPlayerLaunchToType::LaunchWithImpulse;
			LaunchParams.NetworkMode = EPlayerLaunchToNetworkMode::Crumbed;
			Player.LaunchPlayerTo(this, LaunchParams);

			LaunchZone.OnPlayerLaunchStarted.Broadcast(Player);

			if (Player == Game::Mio)
				Timer::SetTimer(this, n"OnMioLaunchFinished", LaunchDuration);
			else
				Timer::SetTimer(this, n"OnZoeLaunchFinished", LaunchDuration);
		}
	}

	UFUNCTION()
	private void OnMioLaunchFinished()
	{
		LaunchZone.OnPlayerLaunchFinished.Broadcast(Game::Mio);
		LaunchedPlayers[Game::Mio] = false;
	}

	UFUNCTION()
	private void OnZoeLaunchFinished()
	{
		LaunchZone.OnPlayerLaunchFinished.Broadcast(Game::Zoe);
		LaunchedPlayers[Game::Zoe] = false;
	}

	FVector GetLaunchVelocity(ASummitRaftPlayerLaunchZone Zone, FVector WorldLocation)
	{
		// Get the extent as world locations
		FVector RelativeLocation = Zone.ActorTransform.InverseTransformPosition(WorldLocation);

		float Extent = Zone.GetActorLocalBoundingBox(false).Extent.X;
		float Alpha = Math::Saturate(Math::NormalizeToRange(RelativeLocation.X, -Extent, Extent));
		return Math::Lerp(BackLocationLaunchVelocity, ForwardLocationLaunchVelocity, Alpha);
	}
};

#if EDITOR
class USummitRaftPlayerLaunchZoneVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRaftPlayerLaunchZoneComponent;

	void VisualizeTrajectory(ASummitRaftPlayerLaunchZone LaunchZone, USummitRaftPlayerLaunchZoneComponent Comp, FVector Origin, FLinearColor TrajectoryColor, FString TrajectoryName)
	{
		// Rotate the velocity to match transform
		FVector LaunchVelocity = LaunchZone.ActorTransform.TransformVectorNoScale(Comp.GetLaunchVelocity(LaunchZone, Origin));
		float GravityMagnitude = 2385;
		float TerminalSpeed = 2500;

		Trajectory::FTrajectoryPoints Points = Trajectory::CalculateTrajectory(Origin, LaunchZone.VisualizedTrajectoryLength, LaunchVelocity, GravityMagnitude, 12, TerminalSpeed);
		DrawWorldString(f"{TrajectoryName}", Points.Positions[0], FLinearColor(0.00, 0.80, 1.00), 1, -1, false, true);

		for (int i = 0; i < Points.Positions.Num() - 1; ++i)
		{
			FVector CenterStart = Points.Positions[i];
			FVector CenterEnd = Points.Positions[i + 1];
			DrawLine(CenterStart, CenterEnd, TrajectoryColor, 5, true);
		}

		FVector PlayerResumeControlLocation;
		if (Comp.bUseHighestPointAsLaunchDuration)
			PlayerResumeControlLocation = Trajectory::TrajectoryHighestPoint(Origin, LaunchVelocity, GravityMagnitude);
		else
			PlayerResumeControlLocation = Trajectory::TrajectoryPositionAfterTime(Origin, LaunchVelocity, GravityMagnitude, Comp.LaunchDuration, TerminalSpeed);

		DrawWireSphere(PlayerResumeControlLocation, 100, FLinearColor::Yellow, 5, 12);
		DrawWorldString(f"Player Resume Control Location", PlayerResumeControlLocation, FLinearColor(1.00, 0.55, 0.00), 1, -1, false, true);
	}

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitRaftPlayerLaunchZoneComponent>(Component);
		if (Comp == nullptr)
			return;

		auto LaunchZone = Cast<ASummitRaftPlayerLaunchZone>(Comp.Owner);

		FTransform LaunchTransform = LaunchZone.ActorTransform;
		FVector BackLocation = LaunchTransform.TransformPosition(FVector(-LaunchZone.BrushComponent.GetComponentLocalBoundingBox().Extent.X, 0, 0));
		FVector ForwardLocation = LaunchTransform.TransformPosition(FVector(+LaunchZone.BrushComponent.GetComponentLocalBoundingBox().Extent.X, 0, 0));
		VisualizeTrajectory(LaunchZone, Comp, BackLocation, FLinearColor::Blue, "BackLocation");
		VisualizeTrajectory(LaunchZone, Comp, LaunchZone.ActorLocation, FLinearColor::LucBlue, "Origin");
		VisualizeTrajectory(LaunchZone, Comp, ForwardLocation, FLinearColor::Green, "ForwardLocation");
	}
}

#endif