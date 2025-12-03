USTRUCT()
struct FTundraMonkeyFootstepTraceData
{
	UPROPERTY()
	ETundraMonkeyFootType Foot;

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

	FTundraMonkeyFootstepTraceData(const ETundraMonkeyFootType InFootType)
	{
		Foot = InFootType;
	}

	FTundraMonkeyFootstepTraceData(const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}

	FTundraMonkeyFootstepTraceData(const FName InTag, const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		TraceDataTag = InTag;
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}
}

struct FTundraMonkeyFootstepParams
{
	UPROPERTY()
	ETundraMonkeyFootType Foot = ETundraMonkeyFootType::None;

	UPROPERTY()
	ETundraMonkeyFootstepType FootstepType = ETundraMonkeyFootstepType::Foot;

	UPROPERTY()
	EHazeAudioPhysicalMaterialHardnessType SurfaceType = EHazeAudioPhysicalMaterialHardnessType::Soft;

	UPROPERTY()
	UHazeAudioEvent SurfaceAddEvent = nullptr;

	UPROPERTY()
	float SlopeTilt = 0.0;

	UPROPERTY()
	float Pitch = 0.0;
}

struct FTundraMonkeyJumpLandParams
{
	UPROPERTY()
	UHazeAudioEvent SurfaceEvent = nullptr;

	UPROPERTY()
	float Intensity = 0.0;
}

class UTundraMonkeyFootstepTraceAudioComponent : UFootstepTraceComponent
{
	default ComponentTickEnabled = false;	
	
	private UAudioTundraMonkeyFootTraceSettings FootTraceSettings;
	private TMap<ETundraMonkeyFootType, FTundraMonkeyFootstepTraceData> TraceDatas;

	default TraceDatas.Add(ETundraMonkeyFootType::LeftFoot, FTundraMonkeyFootstepTraceData(ETundraMonkeyFootType::LeftFoot));	
	default TraceDatas.Add(ETundraMonkeyFootType::RightFoot, FTundraMonkeyFootstepTraceData(ETundraMonkeyFootType::RightFoot));
	default TraceDatas.Add(ETundraMonkeyFootType::LeftHand, FTundraMonkeyFootstepTraceData(ETundraMonkeyFootType::LeftHand));
	default TraceDatas.Add(ETundraMonkeyFootType::RightHand, FTundraMonkeyFootstepTraceData(ETundraMonkeyFootType::RightHand));

	UTundraMonkeyMovementAudioComponent TundraMonkeyMoveComp;

	TMap<ETundraMonkeyFootType, FVector> TrackedFootLocations;	
	FVector CachedDragonLocation;

	USkeletalMeshComponent MonkeyMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Super::BeginPlay();

		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
		TundraMonkeyMoveComp = UTundraMonkeyMovementAudioComponent::Get(PlayerOwner);	

		MonkeyMesh = UTundraPlayerShapeshiftingComponent::Get(PlayerOwner).GetMeshForShapeType(ETundraShapeshiftShape::Big);

		FootTraceSettings = UAudioTundraMonkeyFootTraceSettings::GetSettings(PlayerOwner);
	}

	FTundraMonkeyFootstepTraceData& GetTraceData(const ETundraMonkeyFootType FootType)
	{
		// Handle Jumping data
		ETundraMonkeyFootType WantedFootType = FootType;
		if(FootType == ETundraMonkeyFootType::Land)// || FootType == ETundraMonkeyFootType::Jump)
			WantedFootType = ETundraMonkeyFootType::Jump;

		FTundraMonkeyFootstepTraceData& TraceData = TraceDatas.FindOrAdd(WantedFootType);
		TraceData.Settings = FootTraceSettings.GetTraceSettings(WantedFootType);
		return TraceData;
	}

	FVector GetTraceFrameStartPos(const FTundraMonkeyFootstepTraceData& InTraceData)
	{
		return MonkeyMesh.GetSocketLocation(InTraceData.Settings.SocketName);
	}

	FVector GetTraceFrameEndPos(const FTundraMonkeyFootstepTraceData& InTraceData, const float InTraceLength)
	{	
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = MonkeyMesh.GetSocketRotation(InTraceData.Settings.SocketName);
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start - Direction * -InTraceLength;
	}

	float GetScaledTraceLength(FTundraMonkeyFootstepTraceData& InFootstepTraceData)
	{
		const float NormalizedSpeed = MoveComp.GetVelocity().Size() / InFootstepTraceData.Settings.MaxVelo;

		// const float Alpha = Math::Pow(NormalizedSpeed, 2.0);
		const float Alpha = Math::Min(NormalizedSpeed, 1);
		const float ScaledLength = Math::Lerp(InFootstepTraceData.Settings.MinLength, InFootstepTraceData.Settings.MaxLength, Alpha);
		return ScaledLength;
	}

	bool ValidateFootFrameVelo(FTundraMonkeyFootstepTraceData& InFootstepTraceData)
	{
		FVector CachedLocation;
		if(!TrackedFootLocations.Find(InFootstepTraceData.Foot, CachedLocation))
			return false;

		const float VerticalDelta = InFootstepTraceData.Start.Z - CachedLocation.Z;

		const FVector DragonVelo = Owner.GetActorLocation() - CachedDragonLocation;
		InFootstepTraceData.Velo = (InFootstepTraceData.Start - CachedLocation) - DragonVelo;

		// Has the foot moved enough?
		if(Math::IsNearlyZero(VerticalDelta, InFootstepTraceData.Settings.MinRequiredVelo))
			return false;
		
		// Has the foot to much upwards velocity to invalidate a new footstep?
		float WorldUpDot = MoveComp.WorldUp.GetSafeNormal().DotProduct(InFootstepTraceData.Velo.GetSafeNormal());

		if(WorldUpDot > 0.5)		
		{
			if(!InFootstepTraceData.Trace.bGrounded)
				InFootstepTraceData.Trace.bPerformed = true;
		}

		return true;		
	}

	bool PerformFootTrace_Sphere(FTundraMonkeyFootstepTraceData& InTraceData, const float TraceLength, bool bComplex = false, bool bDebug = false)
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