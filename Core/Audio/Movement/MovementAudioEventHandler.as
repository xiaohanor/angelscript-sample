USTRUCT()
struct FPlayerFootstepParams
{
	UPROPERTY()
	EFootType FootStepType = EFootType::None;

	UPROPERTY()
	FName MovementState = n"";

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;

	UPROPERTY()
	UHazeAudioEvent MaterialEvent = nullptr;

	UPROPERTY()
	float SlopeTilt = 0.0;

	UPROPERTY()
	UHazeAudioEvent AddScuffEvent = nullptr;

	UPROPERTY()
	float AddScuffMakeUpGain = 0.0;

	// Set in trace settings
	UPROPERTY()
	float MakeUpGain = 0.0;

	// Set in trace settings
	UPROPERTY()
	float Pitch = 0.0;

	UPROPERTY()
	EPhysicalSurface PhysicalSurfaceType;

	UPROPERTY()
	FVector ImpactPoint = FVector::ZeroVector;

	UPROPERTY()
	FVector ImpactNormal = FVector::ZeroVector;
}

USTRUCT()
struct FPlayerHandImpactParams
{	
	UPROPERTY()
	EHandTraceAction ActionType = EHandTraceAction::None;

	UPROPERTY()
	FName MovementState = n"";

	UPROPERTY()
	float HandVelo = 0;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;

	UPROPERTY()
	UHazeAudioEvent MaterialEvent = nullptr;

	// Set in trace settings
	UPROPERTY()
	float MakeUpGain = 0.0;

	// Set in trace settings
	UPROPERTY()
	float Pitch = 0.0;
}

USTRUCT()
struct FPlayerHandSlideAudioParams
{
	UPROPERTY(BlueprintReadOnly)
	EHandType Hand = EHandType::None;

	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEvent MaterialEvent = nullptr;

	UPROPERTY(BlueprintReadOnly)
	float LinearSpeed = 0.0;
}

USTRUCT()
struct FPlayerFootSlideStartAudioParams
{
	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEvent MaterialEvent = nullptr;

	UPROPERTY(BlueprintReadOnly)
	float LinearSpeed = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float MakeUpGain = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float Pitch = 0.0;
}

USTRUCT()
struct FPlayerFootSlideStopAudioParams
{
	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEvent MaterialEvent = nullptr;

	UPROPERTY(BlueprintReadOnly)
	float LinearSpeed = 0.0;
}

USTRUCT()
struct FPlayerFootSlideTickParams
{
	UPROPERTY()
	float LinearSpeed = 0.0;

	UPROPERTY()
	float AngularSpeed = 0.0;
}

USTRUCT()
struct FPlayerHandSlideTickParams
{
	UPROPERTY()
	EHandType Hand = EHandType::None;

	UPROPERTY()
	float LinearSpeed = 0.0;

	UPROPERTY()
	float AngularSpeed = 0.0;

	UPROPERTY()
	float SlidePitchMin = 0.0;

	UPROPERTY()
	float SlidePitchMax = 0.0;
}

class UMovementAudioEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Left(FPlayerFootstepParams FootstepParams) {};

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Right(FPlayerFootstepParams FootstepParams) {};

	UFUNCTION(BlueprintEvent)
	void StartFootSlide(FPlayerFootSlideStartAudioParams SlideParams) {};

	UFUNCTION(BlueprintEvent)
	void StopFootSlide(FPlayerFootSlideStopAudioParams SlideParams) {};

	UFUNCTION(BlueprintEvent)
	void StartFootSlideLoop(FPlayerFootSlideStartAudioParams SlideParams) {};

	UFUNCTION(BlueprintEvent)
	void StopFootSlideLoop() {};

	UFUNCTION(BlueprintEvent)
	void TickFootSlide(FPlayerFootSlideTickParams TickParams) {};

	UFUNCTION(BlueprintEvent)
	void OnHandTrace_Left(FPlayerHandImpactParams ImpactParams) {};

	UFUNCTION(BlueprintEvent)
	void OnHandTrace_Right(FPlayerHandImpactParams ImpactParams) {};

	UFUNCTION(BlueprintEvent)
	void StartHandSlide(FPlayerHandSlideAudioParams StartParams) {};
	
	UFUNCTION(BlueprintEvent)
	void StopHandSlide(FPlayerHandSlideAudioParams StopParams) {};

	UFUNCTION(BlueprintEvent)
	void StartHandSlideLoop(FPlayerHandSlideAudioParams SlideParams) {};

	UFUNCTION(BlueprintEvent)
	void StopHandSlideLoop(FPlayerHandSlideAudioParams SlideParams) {};

	UFUNCTION(BlueprintEvent)
	void TickHandSlide(FPlayerHandSlideTickParams TickParams) {};

	UFUNCTION(BlueprintEvent)
	void StartArmswing() {};

	UFUNCTION(BlueprintEvent)
	void StopArmswing() {};
}