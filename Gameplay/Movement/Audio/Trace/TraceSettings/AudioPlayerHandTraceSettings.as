USTRUCT(Meta = (ComposedStruct))
struct FHandTraceSettings
{	
	// The shape of the trace
	UPROPERTY()
	EFootstepTraceType TraceType = EFootstepTraceType::Sphere;

	// The socket of the hand to trace from
	UPROPERTY(Meta = (GetOptions = "GetHandSocketNames"))
	FName SocketName = NAME_None;

	// The radius of the sphere shape
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float SphereRadius = 5.0;

	// The length of the trace at the lowest velocity as set by MaxVelo
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MinLength = 1.0;

	// The length of the trace at the highest velocity as set by MaxVelo
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MaxLength = 5.0;

	// The minimum velocity delta (change in cm) required for tracing to be considered valid
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MinRequiredVelo = 5.0;

	// The maximum change in velocity delta (change in position between two frames, in cm) we consider for velocity comparisons 
	UPROPERTY(Meta = (ForceUnits = "cm"))
	float MaxVelo = 30.0;
	
	// The amount of time that needs to pass before triggering again, tracked seperately for plant/release
	UPROPERTY(Meta = (ForceUnits = "s"))
	float TriggerCooldown = 0.25;

	UPROPERTY()
	bool bCanSlide = false;

	UPROPERTY(Meta = (EditCondition = "bCanSlide"))
	bool bLimitSlidingDownwards = false;

	UPROPERTY(Meta = (EditCondition = "bCanSlide"))
	bool bPerHandSliding = false;

	// The amount of time that hand needs to be moving along surface before we start sliding loop
	UPROPERTY(Meta = (ForceUnits = "s", EditCondition = "bCanSlide"))
	float SlidingDelay = 0.0;

	// Make-Up gain modifier, set directly
	UPROPERTY(Meta = (ClampMin = -96, ClampMax = 12, UIMin = -96, UIMax = 12, SliderExponent = 1, ForceUnits = "db"))
	int32 MakeUpGain = 0;

	// Pitch modifier, set directly
	UPROPERTY(Meta = (ClampMin = -2400, ClampMax = 2400, UIMin = -2400, UIMax = 2400, ForceUnits = "cent"))
	int32 Pitch = 0;

	// Override target for direction of trace
	UPROPERTY(NotVisible)
	USceneComponent WorldTarget = nullptr;
};

UCLASS(NotBlueprintable)
class UAudioPlayerHandTraceSettings : UHazeAudioTraceSettings
{
	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FHandTraceSettings Left;
	default Left.SocketName = MovementAudio::Player::LeftHandTraceSocketName;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FHandTraceSettings Right;	
	default Right.SocketName = MovementAudio::Player::RightHandTraceSocketName;

	UFUNCTION()
	TArray<FString> GetHandSocketNames() const
	{
		TArray<FString> SocketNames;		
		
		SocketNames.Add("LeftHandAudioAttach");
		SocketNames.Add("LeftHandAudioTrace");
		SocketNames.Add("RightHandAudioAttach");
		SocketNames.Add("RightHandAudioTrace");	

		return SocketNames;
	}
}