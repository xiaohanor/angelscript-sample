class USandSharkSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Idle", Meta = (ComposedStruct))
	FSandSharkMovementData IdleMovement;
	default IdleMovement.MovementSpeed = 500.0;
	default IdleMovement.MovementSpeedTurning = 500.0;
	default IdleMovement.MaxTurnAngle = 60;
	default IdleMovement.AccelerationDuration = 0.5;
	default IdleMovement.TurnSpeed = 45.0;

	UPROPERTY(Category = "Idle")
	float IdleSplineFollowSpeed = 500;

	UPROPERTY(Category = "Chase", Meta = (ComposedStruct))
	FSandSharkMovementData ChaseMovement;
	default ChaseMovement.MovementSpeed = 1450.0;
	default ChaseMovement.MovementSpeedTurning = 250.0;
	default ChaseMovement.MaxTurnAngle = 360;
	default ChaseMovement.AccelerationDuration = 0.1;
	default ChaseMovement.TurnSpeed = 720.0;

	UPROPERTY(Category = "Thumper", Meta = (ComposedStruct))
	FSandSharkMovementData ThumperMovement;
	default ThumperMovement.MovementSpeed = 1200.0;
	default ThumperMovement.MovementSpeedTurning = 750.0;
	default ThumperMovement.MaxTurnAngle = 120;
	default ThumperMovement.AccelerationDuration = 0.1;
	default ThumperMovement.TurnSpeed = 120.0;
};

USTRUCT(Meta = (ComposedStruct))
struct FSandSharkMovementData
{
	UPROPERTY(Category = "Movement")
	float MaxTurnAngle = 60.0;

	/** Turning rate in degrees/second. */
	UPROPERTY(Category = "Movement")
	float TurnSpeed = 6.0;

	/** Target MovementSpeed*/
	UPROPERTY(Category = "Movement")
	float MovementSpeed = 750;

	/** Maximum movementspeed when turning and target is above distance threshold. */
	UPROPERTY(Category = "Movement")
	float MovementSpeedTurning = 750;

	/** How long it takes to accelerate to target speed. */
	UPROPERTY(Category = "Movement")
	float AccelerationDuration = 1.0;

}

namespace SandShark
{
	const FHazeDevToggleBool ShouldBeActive = FHazeDevToggleBool(FHazeDevToggleCategory(n"SandShark"), n"ShouldBeActive");

	const float OnSandTraceDefaultMaxDistance = 5000;

	const float OnSandTraceMaxDistance = 2000;

	// distance to playertarget where shark will prefer going to player over thumper
	const float PreferPlayerDistance = 300;

	// distance to playertarget where shark will prefer going to active thumper over player
	const float PreferThumperDistance = 500;

	namespace Animations
	{
		// based on animation sequence length
		const float DiveDuration = 1.0;
		const float AttackFromBelowJumpDuration = 1.6;
		const float LungeDuration = 1.2;
		const float RopeDistractJumpDuration = 2.74;
	}

	namespace Navigation
	{
		const float AgentRadius = 450;
		const float AgentHeight = 144;
	}

	namespace Collision
	{
		const FVector AttackFromBelowExtents = FVector(200, 200, 800);
		const FVector LungeExtents = FVector(800, 200, 400);
	}

	namespace Chase
	{
		const float RetargetDistance = 500;
		const float ChangeTargetDelay = 2;
	}

	namespace TickGroupOrder
	{
		const int AttackFromBelow = 0;
		const int Lunge = 10;
		const int ThumperDistract = 20;
		const int Chase = 30;
		const int SwingDistract = 40;
		const int RopeDistract = 50;
		const int Idle = 60;
	}

	asset PathFollowSettings of UPathfollowingSettings
	{
		AtDestinationRange = 300.0;
		AtWaypointRange = 140.0;

		UpdatePathDistance = 50.0;

		OutsideNavmeshEndRange = 150.0;
		OutsideNavmeshStartRange = 600.0;
		NavmeshMaxProjectionRange = 600.0;
	}

	asset GroundPathFollowSettings of UGroundPathfollowingSettings
	{
		AtPointHeightTolerance = MAX_flt;
		NavmeshMaxProjectionHeight = 400.0;
		AccelerationDuration = 0.5;
	}

	namespace Idle
	{
		const float Height = -15;
		const float HeightDuration = 1;
	}
}

namespace SandSharkTags
{
	// Tags capabilities, allowing them to be blocked/unblocked from other systems
	const FName SandShark = n"SandShark";
	const FName SandSharkIdle = n"SandSharkIdle";
	const FName SandSharkChase = n"SandSharkChase";
	const FName SandSharkTrail = n"SandSharkTrail";
	const FName SandSharkCameraShake = n"SandSharkCameraShake";
	const FName SandSharkSpline = n"SandSharkSpline";
	const FName SandSharkLunge = n"SandSharkLunge";
	const FName SandSharkAttackFromBelow = n"SandSharkAttackFromBelow";

}

namespace SandSharkBlockedWhileIn
{
	const FName Attack = n"BlockedWhileInSandSharkAttack";
	const FName AttackFromBelow = n"BlockedWhileInSandSharkAttackFromBelow";
	const FName AttackLunge = n"BlockedWhileInSandSharkAttackLunge";
	const FName Chase = n"BlockedWhileInSandSharkChase";
	const FName Distract = n"BlockedWhileInSandSharkDistract";
	const FName ThumperDistract = n"BlockedWhileInSandSharkThumperDistract";
}