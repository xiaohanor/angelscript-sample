USTRUCT()
struct FPlayerFootstepTraceData
{
	UPROPERTY()
	EFootType Foot;

	UPROPERTY(BlueprintReadOnly)
	FName TraceDataTag = NAME_None;

	UPROPERTY(BlueprintReadOnly)
	FTransform FootTraceTransformOffset = FTransform();

	UPROPERTY(BlueprintReadOnly)
	FVector Start;

	UPROPERTY(BlueprintReadOnly)
	FVector End;

	UPROPERTY(BlueprintReadOnly)
	FVector Velo;
	
	UPROPERTY(BlueprintReadOnly)
	FVector ScaledBoxExtends;

	UPROPERTY(BlueprintReadOnly)
	FFootstepTrace Trace;

	UPROPERTY(BlueprintReadOnly)
	FHitResult Hit;

	UPROPERTY(BlueprintReadOnly)
	FAudioFootTraceSettings Settings;

	UPROPERTY(BlueprintReadOnly)
	float PlantTriggerTimeStamp = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float ReleaseTriggerTimeStamp = 0.0;

	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial GroundedPhysMat = nullptr;

	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial LastPhysMat = nullptr;

	// Debugging
	#if EDITOR
	bool bValidFrameVelo = true;
	bool bCooldownReady = true;
	bool bInvalidated = false;
	#endif

	FPlayerFootstepTraceData(const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}

	FPlayerFootstepTraceData(const FName InTag, const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		TraceDataTag = InTag;
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}
}


class UPlayerFootstepTraceComponent : UFootstepTraceComponent
{
	private UAudioPlayerHandTraceSettings HandTraceSettings;
	private UAudioPlayerFootTraceSettings FootTraceSettings;

	private FHandTraceData LeftHandTraceData;
	private FHandTraceData RightHandTraceData;

	private FPlayerFootstepTraceData LeftFootTraceData;
	private FPlayerFootstepTraceData RightFootTraceData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Super::BeginPlay();

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		HandTraceSettings = UAudioPlayerHandTraceSettings::GetSettings(Player);

		FootTraceSettings = UAudioPlayerFootTraceSettings::GetSettings(Player);
	}	

	FHandTraceData& GetTraceData(const EHandType HandType)
	{
		if(HandType == EHandType::Left)
		{
			LeftHandTraceData.Settings = HandTraceSettings.Left;
			return LeftHandTraceData;
		}

		RightHandTraceData.Settings = HandTraceSettings.Right;
		return RightHandTraceData;
	}

	FPlayerFootstepTraceData& GetTraceData(const EFootType FootType)
	{
		if(FootType == EFootType::Left)
		{
			LeftFootTraceData.Settings = FootTraceSettings.Left;
			return LeftFootTraceData;
		}

		RightFootTraceData.Settings = FootTraceSettings.Right;
		return RightFootTraceData;
	}

	UFUNCTION(BlueprintPure)
	bool GetFootContactMaterial(const EFootType Foot, UPhysicalMaterial&out Physmat)
	{
		FPlayerFootstepTraceData& TraceData = GetTraceData(Foot);
		if(TraceData.GroundedPhysMat != nullptr)
		{
			Physmat = TraceData.GroundedPhysMat;
			return true;
		}

		return false;
	}
}