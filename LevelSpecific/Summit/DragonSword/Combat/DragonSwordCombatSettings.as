namespace DragonSwordAirAttack
{
	const float AirHangDuration = 0.23;

	const float AirGroundExitDuration = 0.86;

	// initial speed in cm/s^2
	const float AirFallInitialSpeed = 1800;

	// acceleration in cm/s^2
	const float AirFallSpeedAcceleration = 900;
}

namespace DragonSwordBoomerang
{
	const float MinThrowDistance = 800;
	const float DistanceModifierUpdateInterval = 0.25;
	const float DistanceModifierMax = DistanceModifierUpdateInterval * 3;
	const float SpinSpeed = 2520;

	const float ThrowMoveDuration = 0.5;
	const float StayInPlaceDuration = 0.5;
	const float RecallMoveDuration = 0.5;

	const uint MaxCrystalsBeforeStopping = 10;
}

namespace DragonSwordChargeAttack
{
	const float HitRangeModifierUpdateInterval = 0.5;
	const float HitRangeModifierMax = HitRangeModifierUpdateInterval * 2;
}

namespace DragonSwordCombat
{
	const FName TargetableCategory = n"DragonSwordCombat";
	const FName Feature = n"DragonSwordCombat";

	const bool bShowCrosshair = true;

	// Input
	const float InputBufferTime = 0.2;

	const float ChargeAttackActivationThreshold = 0.2;

	const float CritterHitStopDuration = 0.025;

	const float PlayerMaxHitStopDuration = 0.055;
	const float PlayerMinHitStopDuration = 0.025;
	const int PlayerNumHitsForMaxStopDuration = 6;

	// How far our reach is when attacking.
	const float SlamHitRange = 100.0;

	const float HitRange = 150.0;
	const float HitInnerRange = 120.0;

	// How distance from an active target we want to be when attacking.
	const float IdealSuctionDistance = HitRange * 0.5;
	// Disregards angle check if within this range and in front.
	const float HitSafeRangeFront = 100.0;
	// Disregards angle check if within this range irregardless of relative location.
	const float HitSafeRange = 80.0;
	// Maximum angle in degrees we're allowed to turn towards an enemy during an attack.
	const float MaxRushAngle = 60.0;
	// Maximum distance of an enemy before we can suction towards them.
	const float MaxRushDistance = HitRange;
	// Maximum distance of an enemy will be targeted from.
	const float MaxVisibleDistance = HitRange;
	// Weighing of distance vs. angle when searching for suction target, < .5 favors angle, > .5 favors distance.
	const float SuctionDistanceAngleWeight = 0.5;
	// Remaps delta movement applied by root movement towards movement input depending on input size.
	const FVector2D RootMovementInputScale = FVector2D(1.0, 1.0);

	// Used to extend window where next attack in sequence will be used (outside of regular combo window)
	const float ComboGraceWindow = 0.5;

	// Additional Movement
	const float AdditionalMovementMaxSpeed = 200;

	// Dash
	const float DashGraceTime = 0.1;

	const float GroundAttackDistanceThreshold = 75;

	// Camera
	const float CombatCameraBlendInTime = 0.5;
	const float CombatCameraBlendOutTime = 2.0;
	const float CombatCameraEndDelay = 0.1;

	// UNUSED CAPABILITY CONFIG
	// DEBUG
	const bool DEBUG_RequestOverrideWithAttackState = false;
	const bool DEBUG_WaitOneFrameBeforeStartingStrafe = true;
	const bool DEBUG_DrawEnforcerDangerMaxRange = false;
	// Default recoil duration used whenever a recoil is requested with no specific duration.
	const float DefaultRecoilDuration = 0.8;
	// Rush
	const float RushSpeed = 1000;
	const float RushDistanceThreshold = 250;
	const float AirRushMaxHeight = 400;
}

enum EDragonSwordRequestAnimationDebug
{
	DontRequestAnimation,
	RequestLocomotionWithMovement,
	RequestOverrideWithMovement
}

enum EDragonSwordChargeAttack
{
	SpinAttack,
	Boomerang
}

namespace DragonSwordTrace
{
	FHazeTraceSettings GetSphereTraceSettings(float Radius, TArray<AActor>&in IgnoreActors, bool bDebugDraw = false)
	{
		auto TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);
		TraceSettings.IgnoreActors(IgnoreActors);
		TraceSettings.UseSphereShape(Radius);

#if EDITOR
		if (bDebugDraw)
		{
			FHazeTraceDebugSettings DebugSettings;
			DebugSettings.Duration = 1;
			DebugSettings.Thickness = 5;
			TraceSettings.DebugDraw(DebugSettings);
		}
#endif

		return TraceSettings;
	}

	FHazeTraceSettings GetStabTraceSettings(TArray<AActor> &in IgnoreActors, bool bDebugDraw = false)
	{
		auto TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);
		TraceSettings.IgnoreActors(IgnoreActors);
		TraceSettings.UseLine();

#if EDITOR
		if (bDebugDraw)
		{
			FHazeTraceDebugSettings DebugSettings;
			DebugSettings.Duration = 1;
			DebugSettings.Thickness = 5;
			TraceSettings.DebugDraw(DebugSettings);
		}
#endif

		return TraceSettings;
	}
}