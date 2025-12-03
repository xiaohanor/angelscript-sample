namespace SkylineBallBossDevToggles
{
	const FHazeDevToggleCategory BallBossCategory = FHazeDevToggleCategory(n"BallBoss");

	const FHazeDevToggleBool IsTrailer = FHazeDevToggleBool(BallBossCategory, n"Trailer Camera Laser Behavior");

	const FName Cheating = n"Cheating :)";
	const FHazeDevToggleBool NoThrowsImpacts = FHazeDevToggleBool(BallBossCategory, Cheating, n"No car throws & bike impacts");
	const FHazeDevToggleBool LongerGrabScrewWindow = FHazeDevToggleBool(BallBossCategory, Cheating, n"Longer window to grab screw");
	const FHazeDevToggleBool DontLookAway = FHazeDevToggleBool(BallBossCategory, Cheating, n"Don't look away while Zoe aims");
	const FHazeDevToggleBool InsideWeakpointAutoplay = FHazeDevToggleBool(BallBossCategory, Cheating, n"Inside weakpoint autoplay");
	const FHazeDevToggleBool PretendThereAreDetonators = FHazeDevToggleBool(BallBossCategory, Cheating, n"Pretend There are Detonators");
	const FHazeDevToggleBool ChargeLasersComeOff = FHazeDevToggleBool(BallBossCategory, Cheating, n"Charge Lasers Come Off");
	const FHazeDevToggleBool ChargeLasersAutoExtrude = FHazeDevToggleBool(BallBossCategory, Cheating, n"Charge Lasers Auto Extrude");

	const FName DebugDraw = n"DebugDraw";
	const FHazeDevToggleBool DrawRotationTarget = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Rotation Target");
	const FHazeDevToggleBool DrawLocationTarget = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Location Target");
	const FHazeDevToggleBool DebugPrintData = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Print Data");
	const FHazeDevToggleBool DrawChaseCamera = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Chase Camera");
	const FHazeDevToggleBool DrawChaseEvents = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Chase Events");
	const FHazeDevToggleBool DrawChaseSpline = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Chase Spline");
	const FHazeDevToggleBool DrawLaser = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Laser");
	const FHazeDevToggleBool DrawCarThings = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Car Things");
	const FHazeDevToggleBool DrawStageFocusPlayer = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Stage Focus Player");
	const FHazeDevToggleBool DrawTractorBeam = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Tractor Beam");
	const FHazeDevToggleBool DrawOffset = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Offset Things");
	const FHazeDevToggleBool DrawBlinks = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Blink State");
	const FHazeDevToggleBool DrawMioInteractTPLocations = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Mio interact TP locations");

	const FHazeDevToggleBool DrawSmallBoss = FHazeDevToggleBool(BallBossCategory, DebugDraw, n"Small Boss");

	const FHazeDevToggleGroup AttackPattern = FHazeDevToggleGroup(BallBossCategory, n"Attack Pattern", "Only from Dev Progress points!");
	const FHazeDevToggleOption AttackNormal = FHazeDevToggleOption(AttackPattern, n"None", true);
	const FHazeDevToggleOption AttackSlidingCars = FHazeDevToggleOption(AttackPattern, n"Sliding Cars");
	const FHazeDevToggleOption AttackLobbingCars = FHazeDevToggleOption(AttackPattern, n"Lobbing Cars");
	const FHazeDevToggleOption AttackSmashingCars = FHazeDevToggleOption(AttackPattern, n"Smashing Cars");
	const FHazeDevToggleOption AttackMeteorCars = FHazeDevToggleOption(AttackPattern, n"Meteor Cars");
	const FHazeDevToggleOption AttackThrowMotorcycle = FHazeDevToggleOption(AttackPattern, n"Throw Motorcycle");
	const FHazeDevToggleOption AttackMotorcycle = FHazeDevToggleOption(AttackPattern, n"Motorcycle");
	const FHazeDevToggleOption AttackLaser1 = FHazeDevToggleOption(AttackPattern, n"Laser1");
	const FHazeDevToggleOption AttackLaser2 = FHazeDevToggleOption(AttackPattern, n"Laser2");
}
