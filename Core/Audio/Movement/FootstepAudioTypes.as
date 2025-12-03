// PLayer

enum EFootstepBasicType
{
	Unspecified,
	Left,
	Right
}

enum EFootType
{
	None = -1,
	Left = 0,
	Right = 1,
	Release = 2
}

enum EHandType
{
	None = -1,
	Left = 0,
	Right = 1
}

enum EHandTraceAction
{
	None = -1,
	Plant = 0,
	Release = 1,
	StartSlide = 2,
	StopSlide = 3
}

enum EFootstepTraceType
{
	Line,
	Sphere,
	Box
}


// Dragons

UENUM()
enum EDragonFootType
{
	None = -1,
	FrontLeft = 0,
	FrontRight = 1,
	BackLeft = 2,
	BackRight = 3,
	Release = 4,
	LandFront = 5,
	LandBack = 6,
	MAX
}

// TundraMonkey

UENUM()
enum ETundraMonkeyFootType
{
	None = -1,
	LeftFoot = 0,
	RightFoot = 1,
	LeftHand = 2,
	RightHand = 3,
	Jump = 4,
	Land = 5,
	Roll = 6,
	GroundSlamUp = 7,
	GroundSlamDown = 8,
	HangClimbGrab = 9,
	PoleClimbGrab = 10,
	PoleClimbEnter = 11,
	MAX
}

UENUM()
enum ETundraMonkeyFootstepType
{
	Foot = 0,
	Hand = 1,
	Release = 2
}

// TundraTreeGuardian
UENUM()
enum ETundraTreeGuardianFootType
{
	None = -1,
	LeftFoot = 0,
	RightFoot = 1,
	LeftHand = 2,
	RightHand = 3,
	MAX
}

// Tundra FantasyOtter
UENUM()
enum EFantasyOtterFootType
{
	None = -1,
	LeftFoot = 0,
	RightFoot = 1,
	LeftHand = 2,
	RightHand = 3,
	MAX
}

// Pigworld Pigs
UENUM()
enum EPigFootType
{
	None = -1,
	FrontLeft = 0,
	FrontRight = 1,
	BackLeft = 2,
	BackRight = 3,
	Release = 4,
	Jump = 5,
	Land = 6,
	MAX
}

// Settings

USTRUCT(Meta = (ComposedStruct))
struct FAudioFootTraceSettings
{	
	// The shape of the trace
	UPROPERTY()
	EFootstepTraceType TraceType = EFootstepTraceType::Sphere;

	// The socket of the hand to trace from
	UPROPERTY(Meta = (GetOptions = "GetFootSocketNames"))
	FName SocketName = NAME_None;

	UPROPERTY(Meta = (ForceUnits = "cm"))
	float SphereTraceRadius = 5.0;

	// The length of the trace at the lowest velocity as set by MaxVelo
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MinLength = 1.5;

	// The length of the trace at the highest velocity as set by MaxVelo
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MaxLength = 5.0;

	UPROPERTY()
	FRotator TraceRotationOffset;

	// The minimum velocity delta (change in cm) required for tracing to be considered valid
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MinRequiredVelo = 0.5;

	// if true, don't filter out traces that are not downwards in velocity (i.e for climbing etc)
	UPROPERTY()
	bool bAllowStepUp = false;

	// The maximum change in velocity delta (change in position between two frames, in cm) we consider for velocity comparisons 
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MaxVelo = 600.0;
	
	// The amount of time that needs to pass before triggering again, tracked seperately for plant/release
	UPROPERTY(Meta = (ForceUnits = "s"))
	float TriggerCooldown = 0.25;

	// Make-Up gain modifier, set directly
	UPROPERTY(Meta = (ClampMin = -96, ClampMax = 12, UIMin = -96, UIMax = 12, SliderExponent = 1, ForceUnits = "db"))
	int32 MakeUpGain = 0;
	
	// Pitch modifier, set directly
	UPROPERTY(Meta = (ClampMin = -2400, ClampMax = 2400, UIMin = -2400, UIMax = 2400, ForceUnits = "cent"))
	int32 Pitch = 0;

	// Override target for direction of trace
	UPROPERTY(NotVisible)
	USceneComponent WorldTarget = nullptr;

	// If true, all Plants/Releases will share cooldown between Left/Right feet no matter what movement type 
	UPROPERTY()
	bool bForceSharedCooldowns = false;

	// If true, all Plants/Releases will evaluate to valid hits instead of being filtered out on component tags
	UPROPERTY()
	bool bForceHits = false;
};