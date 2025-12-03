USTRUCT()
struct FFantasyOtterFootstepTraceData
{
	UPROPERTY()
	EFantasyOtterFootType Foot = EFantasyOtterFootType::None;

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

	FFantasyOtterFootstepTraceData(const EFantasyOtterFootType InFootType)
	{
		Foot = InFootType;
	}

	FFantasyOtterFootstepTraceData(const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}

	FFantasyOtterFootstepTraceData(const FName InTag, const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		TraceDataTag = InTag;
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}
}

class UFantasyOtterFootstepTraceAudioComponent : UFootstepTraceComponent
{
	default ComponentTickEnabled = false;		

	private TMap<EFantasyOtterFootType, FFantasyOtterFootstepTraceData> TraceDatas;

	default TraceDatas.Add(EFantasyOtterFootType::LeftFoot, FFantasyOtterFootstepTraceData(EFantasyOtterFootType::LeftFoot));	
	default TraceDatas.Add(EFantasyOtterFootType::RightFoot, FFantasyOtterFootstepTraceData(EFantasyOtterFootType::RightFoot));
	default TraceDatas.Add(EFantasyOtterFootType::LeftHand, FFantasyOtterFootstepTraceData(EFantasyOtterFootType::LeftHand));
	default TraceDatas.Add(EFantasyOtterFootType::RightHand, FFantasyOtterFootstepTraceData(EFantasyOtterFootType::RightHand));

	TMap<EFantasyOtterFootType, FVector> TrackedFootLocations;	
	USkeletalMeshComponent OtterMesh;

	UPROPERTY(EditDefaultsOnly)
	UAudioFantasyOtterFootTraceSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Super::BeginPlay();

		MoveComp = UHazeMovementComponent::Get(PlayerOwner);

		OtterMesh = UTundraPlayerShapeshiftingComponent::Get(PlayerOwner).GetMeshForShapeType(ETundraShapeshiftShape::Small);
	}

	FFantasyOtterFootstepTraceData& GetTraceData(const EFantasyOtterFootType FootType)
	{	
		FFantasyOtterFootstepTraceData& TraceData = TraceDatas.FindOrAdd(FootType);
		TraceData.Settings = Settings.GetTraceSettings(FootType);
		return TraceData;
	}

	FVector GetTraceFrameStartPos(const FFantasyOtterFootstepTraceData& InTraceData)
	{
		return OtterMesh.GetSocketLocation(InTraceData.Settings.SocketName);
	}

	FVector GetTraceFrameEndPos(const FFantasyOtterFootstepTraceData& InTraceData, const float InTraceLength)
	{	
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = OtterMesh.GetSocketRotation(InTraceData.Settings.SocketName);
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start - Direction * -InTraceLength;
	}

	float GetScaledTraceLength(FFantasyOtterFootstepTraceData& InFootstepTraceData)
	{
		const float NormalizedSpeed = MoveComp.GetVelocity().Size() / InFootstepTraceData.Settings.MaxVelo;

		// const float Alpha = Math::Pow(NormalizedSpeed, 2.0);
		const float Alpha = Math::Min(NormalizedSpeed, 1);
		const float ScaledLength = Math::Lerp(InFootstepTraceData.Settings.MinLength, InFootstepTraceData.Settings.MaxLength, Alpha);
		return ScaledLength;
	}

	bool PerformFootTrace_Sphere(FFantasyOtterFootstepTraceData& InTraceData, const float TraceLength, bool bComplex = false, bool bDebug = false)
	{
		FHazeTraceSettings TraceSettings = InitTraceSettings();
		TraceSettings.SetTraceComplex(bComplex);
		TraceSettings.UseSphereShape(TraceLength);
	
		// This trace has already been invalidated this frame, bail
		if(InTraceData.Trace.bPerformed)
			return false;

		InTraceData.Trace.bPerformed = true;	

		if(bDebug)
		{
			FHazeTraceDebugSettings DebugSettings;

			DebugSettings.Thickness = 1.0;
			DebugSettings.ImpactThickness = 1.0;
			DebugSettings.bDrawTraceDirection = true;
			DebugSettings.bDrawImpactNormal = true;		

			DebugSettings.TraceBlockingHitColor = FLinearColor::Blue;
			DebugSettings.TraceAfterHitColor = FLinearColor::DPink;
			DebugSettings.TraceOverlapHitColor = FLinearColor::Red;

			TraceSettings.DebugDraw(DebugSettings);	
		}

		FHitResult Result = TraceSettings.QueryTraceSingle(InTraceData.Start, InTraceData.End);
		if(Result.bBlockingHit)
			InTraceData.PhysMat = AudioTrace::GetPhysMaterialFromHit(Result, TraceSettings);

		InTraceData.Hit = Result;
		return InTraceData.Hit.bBlockingHit;
	}
}