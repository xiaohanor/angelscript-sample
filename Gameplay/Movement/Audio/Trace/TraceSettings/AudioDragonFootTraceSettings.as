struct FDragonFootstepTraceData
{
	UPROPERTY()
	EDragonFootType Foot;

	UPROPERTY()
	UMeshComponent DragonMesh = nullptr;

	UPROPERTY(BlueprintReadOnly)
	FName TraceDataTag = NAME_None;

	UPROPERTY(BlueprintReadOnly)
	FVector Start;

	UPROPERTY(BlueprintReadOnly)
	FVector End;

	UPROPERTY(BlueprintReadOnly)
	FVector Velo;

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
	UPhysicalMaterial PhysMat = nullptr;

	FDragonFootstepTraceData(const EDragonFootType InFootType)
	{
		Foot = InFootType;
	}

	FDragonFootstepTraceData(const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}

	FDragonFootstepTraceData(const FName InTag, const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		TraceDataTag = InTag;
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}
}

UCLASS(NotBlueprintable)
class UAudioDragonFootTraceSettings : UHazeAudioTraceSettings
{
	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings FrontLeft;
	default FrontLeft.SocketName = MovementAudio::Dragons::FrontLeftFootSocketName;
	default FrontLeft.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings FrontRight;	
	default FrontRight.SocketName = MovementAudio::Dragons::FrontRightFootSocketName;
	default FrontRight.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings BackLeft;	
	default BackLeft.SocketName = MovementAudio::Dragons::BackLeftFootTraceSocketName;
	default BackLeft.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings BackRight;	
	default BackRight.SocketName = MovementAudio::Dragons::BackRightFootTraceSocketName;
	default BackRight.SphereTraceRadius = 15.0;

	FAudioFootTraceSettings GetTraceSettings(const EDragonFootType FootType)
	{
		switch(FootType)
		{
			case(EDragonFootType::FrontLeft): return FrontLeft;
			case(EDragonFootType::FrontRight): return FrontRight;
			case(EDragonFootType::BackLeft): return BackLeft;
			case(EDragonFootType::BackRight): return BackRight;
			default: break;
		}

		return FAudioFootTraceSettings();
	}

	UFUNCTION()
	TArray<FString> GetFootSocketNames() const
	{
		TArray<FString> SocketNames;		
		
		SocketNames.Add(MovementAudio::Dragons::FrontLeftFootSocketName.ToString());
		SocketNames.Add(MovementAudio::Dragons::FrontRightFootSocketName.ToString());
		SocketNames.Add(MovementAudio::Dragons::BackLeftFootTraceSocketName.ToString());
		SocketNames.Add(MovementAudio::Dragons::BackRightFootTraceSocketName.ToString());	

		return SocketNames;
	}
}