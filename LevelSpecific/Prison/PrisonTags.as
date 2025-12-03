namespace Drone
{
	const FName DebugCategory = n"Prison";
}

namespace PrisonTags 
{
	const FName Prison = n"Prison";
	const FName Drones = n"Drones";

	const FName ExoSuit = n"ExoSuit";
}

namespace DroneCommonTags
{
	const FName BaseDroneMovement = n"BaseDroneMovement";
	const FName BaseDroneGroundMovement = n"BaseDroneGroundMovement";
	const FName BaseDroneAirMovement = n"BaseDroneAirMovement";
	const FName DroneDashCapability = n"DroneDashCapability";
	const FName DroneMeshRotationCapability = n"DroneMeshRotationCapability";
}

namespace MagnetDroneTags
{
	const FName MagnetDrone = n"MagnetDrone";
	const FName MagnetDroneTarget = n"MagnetDroneTarget";

	// Jump
	const FName MagnetDroneJump = n"MagnetDroneJump";
	const FName MagnetDroneSocketJump = n"MagnetDroneSocketJump";

	// Socket
	const FName MagnetDroneAttachToSocket = n"MagnetDroneAttachToSocket";
	const FName MagnetDroneMeshRotationSocket = n"MagnetDroneMeshRotationSocket";
	const FName MagnetDroneSocketMovement = n"MagnetDroneSocketMovement";

	// Surface
	const FName MagnetDroneAttachToSurface = n"MagnetDroneAttachToSurface";
	const FName MagnetDroneMeshRotationSurface = n"MagnetDroneMeshRotationSurface";
	const FName MagnetDroneSurfaceMovement = n"MagnetDroneSurfaceMovement";
	const FName MagnetDroneSurfaceDash = n"MagnetDroneSurfaceDash";
	const FName MagnetDroneSurfaceJump = n"MagnetDroneSurfaceJump";

	// Misc
	const FName MagnetDroneAim = n"MagnetDroneAim";
	const FName MagnetDroneAttraction = n"MagnetDroneAttraction";
	const FName MagnetDroneCamera = n"MagnetDroneCamera";
	const FName MagnetDroneCameraAttachedWallClamps = n"MagnetDroneCameraAttachedWallClamps";
	const FName MagnetDroneNoMagneticSurfaceFound = n"MagnetDroneNoMagneticSurfaceFound";
	const FName MagnetDroneProcAnim = n"MagnetDroneProcAnim";
	const FName MagnetDroneSprint = n"MagnetDroneSprint";
	const FName MagnetDroneUpdateMeshRotation = n"MagnetDroneUpdateMeshRotation";
}

namespace SwarmDroneTags
{
	const FName SwarmDrone = n"SwarmDrone";

	const FName SwarmDroneActionMovement = n"SwarmDroneActionMovement";

	const FName SwarmTransitionCapability = n"SwarmTransitionCapability";
	const FName SwarmMovementCapability = n"SwarmMovementCapability";
	const FName SwarmedCapability = n"SwarmedCapability";
	const FName SwarmAirMovementCapability = n"SwarmAirMovementCapability";
	const FName SwarmDroneJumpCapability = n"SwarmDroneJumpCapability";

	const FName SwarmDroneHackCapability = n"SwarmDroneHackCapability";
	const FName SwarmDroneHackAimCapability = n"SwarmDroneHackAimCapability";

	const FName SwarmHoverCapability = n"SwarmHoverCapability";
	const FName SwarmHoverDashCapability = n"SwarmHoverDashCapability";
	const FName SwarmGliderCapability = n"SwarmGliderCapability";

	const FName BoatCapability = n"BoatCapability";
	const FName BoatMovementCapability = n"BoatMovementCapability";
	const FName BoatAirMovementCapability = n"BoatAirMovementCapability";

	const FName BoatRapidsEnterCapability = n"BoatRapidsEnterCapability";
	const FName BoatRapidsMovementCapability = n"BoatRapidsMovementCapability";

	const FName SwarmAirductCapability = n"SwarmAirductCapability";
	const FName SwarmAirductIntakeCapability = n"SwarmAirductIntakeCapability";
	const FName SwarmAirductTravelCapability = n"SwarmAirductTravelCapability";
	const FName SwarmAirductExhaustCapability = n"SwarmAirductExhaustCapability";

	const FName SwarmDroneHijackTargetableCategory = n"SwarmDroneHijackTargetableCategory";
	const FName SwarmDroneHijackCapability = n"SwarmDroneHijackCapability";
	const FName SwarmDroneHijackExitCapability = n"SwarmDroneHijackExitCapability";

	const FName SwarmDroneCongaLineCapability = n"SwarmDroneCongaLineCapability";

	const FName SwarmDroneRespawnBotMarkerCapability = n"SwarmDroneRespawnBotMarkerCapability";
}

namespace PrisonStealthTags
{
	const FName StealthGuard = n"StealthGuard";
	const FName StealthGuardMove = n"StealthGuardMove";

	const FName StealthCamera = n"StealthCamera";
	const FName StealthCameraStunned = n"StealthCameraStunned";

	const FName StealthVision = n"StealthVision";
	const FName StealthDetection = n"StealthDetection";
	const FName BlockedWhileStunned = n"BlockedWhileStunned";
	const FName BlockedWhileSearching = n"BlockedWhileSearching";
};

namespace ExoSuitTags
{
	const FName MagneticField = n"MagneticField";
	const FName SwarmMagnetism = n"SwarmMagnetism";
	const FName RemoteHacking = n"RemoteHacking";
}