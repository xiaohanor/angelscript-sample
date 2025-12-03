namespace MedallionConstants
{
	namespace Tags
	{
		const FName StrangleBlockHeadPivot = n"StrangleBlockHeadPivot";
		const FName StrangleBlockRotation = n"StrangleBlockRotation";
		const FName StrangleBlockPlayerFalling = n"StrangleBlockPlayerFalling";
	}

	namespace SideScrollerCamera
	{
		const float InterpHorizontalDuration = 0.0;
		const float HorizontalDist = 300.0;
		const float LerpSplineHeightFactor = 0.7;
		const float OffsetProjectionAddedHorizontalDist = 1500.0;
		const float MergeScreenSettleDuration = 0.5;
	}

	namespace Merge
	{
		const float MergeRespawnDistanceFromOtherPlayer = 3000;

		const float MergePhaseDistance = 5200.0;
		const float MergeScreenDistance = 4200.0;
		const float DeMergeScreenBufferDistance = 200.0;
		const float ProjectionOffsetBlendDistance = 2000.0;
	}

	namespace Highfive
	{
		const float StartOscillatingCompanionDistance = 5000.0;
		const float StopOscillatingCompanionBufferDistance = 200.0;
		const float OscillatingCompanionsSpeed = 5000.0;
		const float OscillatingCompanionsCircleTiltDegrees = 10.0;
		const float OscillatingCompanionsUpwardsOffset = 200.0;
		const float OscillatingCompanionsAddedUpwardsOffset = 300.0;
		const float OscillatingCompanionsBehindPlayersOffset = 200.0;

		const float FOVStartApplyDistance = 3500.0;
		const float FOVFinishApplyDistance = FOVStartApplyDistance * 0.2;
		const float FOVOverride = 10.0;
		const float FailHighfiveFOVOverride = 30.0;
		const float OffsetProjectionAddedHorizontalDist = -10.0;

		const FName HighfiveButton = ActionNames::WeaponFire;
		const float TriggerHighfiveJumpDistance = 700;
		const float HighfiveOffsetOutwards = 1500;
		const float HighfiveOffsetUpwards = 200;
		const bool bHighfiveHeightBasedOnPlayers = true;
		const float HighfiveJumpArcHeight = 200;		
		const float HighfivePlayerSidewaysOffset = 0.0;//50.0;
		const float HighfiveJumpDuration = 1.5; // without the timedilation
		const float HighfiveHoldDuration = 0.3; // without the timedilation

		const float HighfiveTimedilation = 0.2;

		const float HighfiveCameraOffsetInwards = 2000;
		const float HighfiveCameraOffsetUpwards = 300;

		const float HighPingNetworkExtraJumpDistance = 300;
		const float HighPingNetworkMaxSeconds = 0.4;
	}

	namespace Flying
	{
		const FVector2D HydraLookAtPlayerMaxMinSplineDistance = FVector2D(6000, 2000);

		const FVector2D MioStartFlyingOffset = FVector2D(-1000, 0);
		const FVector2D ZoeStartFlyingOffset = MioStartFlyingOffset * -1.0;
		const float LerpDurationFlyingOffset = 1.0;

		const float MoveSpeedMultiplier = 0.8;
		const float MoveSpeedHorizontal = 3000.0 * MoveSpeedMultiplier;
		const float MoveSpeedVertical = 2500.0 * MoveSpeedMultiplier;

		const float DashExtraSpeedHorizontal = 5000;
		const float DashExtraSpeedVertical = 5000;

		const float BarrelRollDuration = 0.8;
		const float DashCooldown = BarrelRollDuration * 0.9;
		const float DashDuration = 0.25;

		const float VerticalCurrentDistance = 1000.0;
		const float HorizontalCurrentDistance = 1000.0;

		const float RubberbandPlayersMinDistance = 2500.0;
		const float RubberbandPlayersMaxDistance = 3500.0;
		const float RubberbandMaxForce = MoveSpeedHorizontal;
		const float CameraYawMaxAngle = 5.0;

		const float ForwardsFlyingSpeed = 3000.0;

		const float KnockRotationDuration = 2.0;
		const float GetKnockedCooldown = 0.9;
		const float KnockedDuration = 0.35;
		const float KnockedSpeed = 5000;
		const float KnockedRangeInFrontOfHydra = 1000;
		const float KnockedRangeSidewaysOfHydra = 700;
	}

	namespace SelectHydra
	{
		const float SplineDistanceStartTryKill = 1000;
		const float SplineDistanceEndTryKill = SplineDistanceStartTryKill + 10;

		const float PlaneDistanceStartTryKill = 900;
	}

	namespace GloryKill
	{
		const float CameraBackwardsOffset = 0;
		const float CameraBlendInTime = 0.0;
		const float CameraBlendOutTime = 0.5;
	}

	namespace ReturnAndLand
	{
		const float ReturnDuration = 4.0;
		const float ReturnCameraLerpDuration = 4.0;
		const float KeepReturnCameraAfterLandingDuration = 0.0;

		const float CameraBlendInTime = 0.0;
		const float CameraBlendOutTime = 3.0;
		const float CameraExitLocationOutwardsOffset = 5000.0;
		const float CameraExitLocationSidewaysOffset = 500.0;
		const float CameraExitLocationUpwardsOffset = 200.0;

		const float LandingUpwardsAngle = 30;
		const float LandingOutwardsAngle = 90;
		const float CameraAddedHorizontalDist = 500.0;
		const float LandingImpulseStrength = 800;
	}

	namespace Ballista
	{
		const float MinPlatformSpeed = 200.0;
		const float MaxPlatformSpeed = 7000.0;
		const float PlatformSinkHeight = -2000;

		const float TriggerNearBallistaPhaseDistanceToPlayer = 4000;
	}

}