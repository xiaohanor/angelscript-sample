class USkylineBallBossFocusPlayerComponent : UActorComponent
{
	// flip flop receive the valid player target
	private EHazeSelectPlayer LastFocusedPlayer = EHazeSelectPlayer::Mio;
	private AHazePlayerCharacter Mio;
	private AHazePlayerCharacter Zoe;


	private ASkylineBallBoss BallBoss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mio = Game::Mio;
		Zoe = Game::Zoe;
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	AHazePlayerCharacter GetFlipFlopFocusPlayer()
	{
		EHazeSelectPlayer DesiredPlayer = EHazeSelectPlayer::None;
		if (LastFocusedPlayer == EHazeSelectPlayer::Mio)
			DesiredPlayer = EHazeSelectPlayer::Zoe;
		if (LastFocusedPlayer == EHazeSelectPlayer::Zoe)
			DesiredPlayer = EHazeSelectPlayer::Mio;

		AHazePlayerCharacter ChosenPlayer = GetViableFocusPlayer(SelectedPlayerCharacter(DesiredPlayer));
		if (ChosenPlayer.IsMio())
			LastFocusedPlayer = EHazeSelectPlayer::Mio;
		if (ChosenPlayer.IsZoe())
			LastFocusedPlayer = EHazeSelectPlayer::Zoe;
		return ChosenPlayer;
	}

	AHazePlayerCharacter GetViableFocusPlayer(AHazePlayerCharacter DesiredPlayer)
	{
		if (CanFocusPlayer(DesiredPlayer))
			return DesiredPlayer;
		if (CanFocusPlayer(DesiredPlayer.OtherPlayer))
			return DesiredPlayer.OtherPlayer;
		return Zoe;
	}

	private AHazePlayerCharacter SelectedPlayerCharacter(EHazeSelectPlayer SelectedPlayer)
	{
		if (SelectedPlayer == EHazeSelectPlayer::Mio)
			return Mio;
		return Zoe;
	}

	bool CanFocusPlayer(AHazePlayerCharacter Player)
	{
		if (Player.IsPlayerDead())
			return false;

		bool DontFocusMioPhase = 
			BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn1 || 
			BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn2 || 
			BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioIn || 
			BallBoss.GetPhase() == ESkylineBallBossPhase::TopAlignMioToStage || 
			BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOnEyeBroken || 
			BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioInKillWeakpoint || 
			BallBoss.GetPhase() == ESkylineBallBossPhase::TopShieldShockwave;
		if (Player.IsMio() && DontFocusMioPhase)
			return false;
		
		return true;
	}

	FVector GetConstrainedFocusLocation(AHazePlayerCharacter Player, FVector AimerLocation)
	{
		if (BallBoss.OnStageActor != nullptr)
		{
			if (BallBoss.OnStageActor.bConstrainToFront)
			{
				FVector2D AimLineStart = FVector2D(AimerLocation.X, AimerLocation.Y);
				FVector2D AimLineEnd = FVector2D(Player.ActorLocation.X, Player.ActorLocation.Y);
				FVector2D FrontExtentOffset = FVector2D(BallBoss.OnStageActor.FrontStageBounds.ForwardVector.X * BallBoss.OnStageActor.FrontStageBounds.BoxExtent.X, BallBoss.OnStageActor.FrontStageBounds.ForwardVector.Y * BallBoss.OnStageActor.FrontStageBounds.BoxExtent.X);
				FVector2D FrontLocation = FVector2D(BallBoss.OnStageActor.FrontStageBounds.WorldLocation.X, BallBoss.OnStageActor.FrontStageBounds.WorldLocation.Y);
				FVector2D FrontLineStart = FrontLocation + FrontExtentOffset;
				FVector2D FrontLineEnd = FrontLocation - FrontExtentOffset;
				FVector2D IntersectingPoint;

				bool bIntersecting = Math::IsLineSegmentIntersectingLineSegment2D(AimLineStart, AimLineEnd, FrontLineStart, FrontLineEnd, IntersectingPoint);

				if (SkylineBallBossDevToggles::DrawStageFocusPlayer.IsEnabled())
				{
					Debug::DrawDebugLine(As3D(AimLineStart), As3D(AimLineEnd), ColorDebug::Cerulean, 3.0, 0.0, true);
					Debug::DrawDebugLine(As3D(FrontLineStart), As3D(FrontLineEnd), bIntersecting ? Player.GetPlayerUIColor() : ColorDebug::Ruby, 3.0, 0.0, true);
				}

				if (bIntersecting)
				{
					return FVector(IntersectingPoint.X, IntersectingPoint.Y, BallBoss.OnStageActor.FrontStageBounds.WorldLocation.Z);
				}
				else
				{
					FVector PointInComponentSpace = BallBoss.OnStageActor.FrontStageBounds.WorldTransform.InverseTransformPosition(AimerLocation);
					PointInComponentSpace = BallBoss.OnStageActor.FrontBox.GetClosestPointTo(PointInComponentSpace);
					FVector ClosestLocation = BallBoss.OnStageActor.FrontStageBounds.WorldTransform.TransformPosition(PointInComponentSpace);
					ClosestLocation.Z = BallBoss.OnStageActor.FrontStageBounds.WorldLocation.Z;
					return ClosestLocation;
				}
			}
			else
			{
				FVector PointInComponentSpace = BallBoss.OnStageActor.StageBounds.WorldTransform.InverseTransformPosition(Player.ActorLocation);
				PointInComponentSpace = BallBoss.OnStageActor.StageBox.GetClosestPointTo(PointInComponentSpace);
				FVector ClosestLocation = BallBoss.OnStageActor.StageBounds.WorldTransform.TransformPosition(PointInComponentSpace);
				ClosestLocation.Z = BallBoss.OnStageActor.StageBounds.WorldLocation.Z;
				return ClosestLocation;
			}
		}
		return Player.ActorLocation;
	}

	private FVector As3D(FVector2D Location)
	{
		return FVector(Location.X, Location.Y, BallBoss.OnStageActor.FrontStageBounds.WorldLocation.Z);
	}
}