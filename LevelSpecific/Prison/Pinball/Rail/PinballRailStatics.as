namespace Pinball
{
	namespace Rail
	{
		void TriggerEnterEvent(UPinballBallComponent BallComp, APinballRail Rail, EPinballRailHeadOrTail EnterSide)
		{
			FPinballBallRailOnEnterRailEventData BallEventData;
			BallEventData.Rail = Rail;
			BallEventData.Side = EnterSide;
			UPinballBallRailEventHandler::Trigger_OnEnterRail(BallComp.HazeOwner, BallEventData);

			Rail.OnBallEnter(BallComp, EnterSide);
		}

		void TriggerExitEvent(UPinballBallComponent BallComp, APinballRail Rail, EPinballRailHeadOrTail ExitSide)
		{
			FPinballBallRailOnExitRailEventData BallEventData;
			BallEventData.Rail = Rail;
			BallEventData.Side = ExitSide;
			UPinballBallRailEventHandler::Trigger_OnExitRail(BallComp.HazeOwner, BallEventData);

			Rail.OnBallExit(BallComp, ExitSide);
		}

		void TriggerLaunchEvent(UPinballBallComponent BallComp, APinballRail Rail, EPinballRailHeadOrTail Side, EPinballRailEnterOrExit EnterOrExit)
		{
			FPinballBallRailOnLaunchedEventData BallEventData;
			BallEventData.Side = Side;
			BallEventData.EnterOrExit = EnterOrExit;
			UPinballBallRailEventHandler::Trigger_OnLaunchedByRail(BallComp.HazeOwner, BallEventData);

			FPinballRailOnLaunchedEventData RailEventData;
			RailEventData.Side = Side;
			RailEventData.EnterOrExit = EnterOrExit;
			UPinballRailEventHandler::Trigger_OnLaunchBall(Rail, RailEventData);
		}

		void TriggerEnterSyncPointEvent(UPinballBallComponent BallComp, APinballRail Rail, UPinballRailSyncPoint EnterSyncPoint, EPinballRailHeadOrTail EnterSide)
		{
			FPinballBallRailSyncPointEventData BallEventData;
			BallEventData.Rail = Rail;
			BallEventData.SyncPoint = EnterSyncPoint;
			BallEventData.HeadOrTail = EnterSide;
			UPinballBallRailEventHandler::Trigger_OnEnterSyncPoint(BallComp.HazeOwner, BallEventData);

			FPinballRailSyncPointEventData RailEventData;
			RailEventData.BallComp = BallComp;
			RailEventData.SyncPoint = EnterSyncPoint;
			RailEventData.HeadOrTail = EnterSide;
			if(BallComp.HasControl() || !BallComp.IsPlayer())
				UPinballRailEventHandler::Trigger_OnBallEnteredSyncPoint(Rail, RailEventData);
			else
				UPinballRailEventHandler::Trigger_OnPredictionEnteredSyncPoint(Rail, RailEventData);
		}

		void TriggerPredictionReceivedLaunchTimeSyncPointEvent(APinballRail Rail, UPinballRailSyncPoint EnterSyncPoint, float TimeUntilLaunch)
		{
			FPinballRailPredictionReceivedLaunchTimeSyncPointEventData EventData;
			EventData.SyncPoint = EnterSyncPoint;
			EventData.TimeUntilLaunch = Math::Max(TimeUntilLaunch, 0.01);
			UPinballRailEventHandler::Trigger_OnPredictionReceivedLaunchTimeSyncPoint(Rail, EventData);
		}

		void TriggerExitSyncPointEvent(UPinballBallComponent BallComp, APinballRail Rail, UPinballRailSyncPoint ExitSyncPoint, EPinballRailHeadOrTail ExitSide)
		{
			FPinballBallRailSyncPointEventData BallEventData;
			BallEventData.Rail = Rail;
			BallEventData.SyncPoint = ExitSyncPoint;
			BallEventData.HeadOrTail = ExitSide;
			UPinballBallRailEventHandler::Trigger_OnExitSyncPoint(BallComp.HazeOwner, BallEventData);

			FPinballRailSyncPointEventData RailEventData;
			RailEventData.BallComp = BallComp;
			RailEventData.SyncPoint = ExitSyncPoint;
			RailEventData.HeadOrTail = ExitSide;
			UPinballRailEventHandler::Trigger_OnBallExitedSyncPoint(Rail, RailEventData);
		}

		void TriggerPredictionCancelledSyncPointEvent(UPinballBallComponent BallComp, APinballRail Rail, UPinballRailSyncPoint SyncPoint)
		{
			FPinballBallRailPredictionCancelledSyncPointEventData BallEventData;
			BallEventData.Rail = Rail;
			BallEventData.SyncPoint = SyncPoint;
			UPinballBallRailEventHandler::Trigger_OnPredictionCancelledSyncPoint(BallComp.HazeOwner, BallEventData);

			FPinballRailPredictionCancelledSyncPointEventData RailEventData;
			RailEventData.SyncPoint = SyncPoint;
			UPinballRailEventHandler::Trigger_OnPredictionCancelledSyncPoint(Rail, RailEventData);
		}
	}
}