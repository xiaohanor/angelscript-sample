

event void FOnEnterCoins();
event void FOnExitCoins();

USTRUCT()
struct FDragonFootstepParams
{
	UPROPERTY()
	EDragonFootType FootStepType = EDragonFootType::None;

	UPROPERTY()
	FName MovementState = n"";

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;

	UPROPERTY()
	float SlopeTilt = 0.0;

	// Set in trace settings
	UPROPERTY()
	float MakeUpGain = 0.0;

	// Set in trace settings
	UPROPERTY()
	float Pitch = 0.0;
}

class UDragonFootstepTraceComponent : UFootstepTraceComponent
{
	private UAudioDragonFootTraceSettings FootTraceSettings;

	private TMap<EDragonFootType, FDragonFootstepTraceData> TraceDatas;
	default TraceDatas.Add(EDragonFootType::FrontLeft, FDragonFootstepTraceData(EDragonFootType::FrontLeft));	
	default TraceDatas.Add(EDragonFootType::FrontRight, FDragonFootstepTraceData(EDragonFootType::FrontRight));
	default TraceDatas.Add(EDragonFootType::BackLeft, FDragonFootstepTraceData(EDragonFootType::BackLeft));
	default TraceDatas.Add(EDragonFootType::BackRight, FDragonFootstepTraceData(EDragonFootType::BackRight));

	UPlayerTeenDragonComponent DragonComp;
	UDragonMovementAudioComponent DragonMoveComp;
	
	AHazeActor Dragon;

	TMap<EDragonFootType, FVector> TrackedFootLocations;	
	FVector CachedDragonLocation;
	const FName MOVEMENT_GROUP_NAME = n"Dragon_Foot";

	bool bWasOnCoins = false;

	FOnEnterCoins OnEnterCoins;
	FOnExitCoins OnExitCoins;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Super::BeginPlay();

		MoveComp = UHazeMovementComponent::Get(Owner);
		DragonComp = UPlayerTeenDragonComponent::Get(Owner);
		DragonMoveComp = UDragonMovementAudioComponent::Get(Owner);	

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		FootTraceSettings = UAudioDragonFootTraceSettings::GetSettings(Player);
	}	

	FDragonFootstepTraceData& GetTraceData(const EDragonFootType FootType)
	{
		// Handle Landing data
		EDragonFootType WantedFootType = FootType;
		if(FootType == EDragonFootType::LandFront)
			WantedFootType = EDragonFootType::FrontLeft;
		else if(FootType == EDragonFootType::LandBack)
			WantedFootType = EDragonFootType::BackLeft;

		FDragonFootstepTraceData& TraceData = TraceDatas.FindOrAdd(WantedFootType);
		TraceData.Settings = FootTraceSettings.GetTraceSettings(WantedFootType);
		return TraceData;
	}

	FVector GetTraceFrameStartPos(const FDragonFootstepTraceData& InTraceData)
	{
		return InTraceData.DragonMesh.GetSocketLocation(InTraceData.Settings.SocketName);
	}

	FVector GetTraceFrameEndPos(const FDragonFootstepTraceData& InTraceData, const float InTraceLength)
	{	
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = InTraceData.DragonMesh.GetSocketRotation(InTraceData.Settings.SocketName);
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start - Direction * -InTraceLength;
	}

	float GetScaledTraceLength(FDragonFootstepTraceData& InFootstepTraceData)
	{
		const float NormalizedSpeed = MoveComp.GetVelocity().Size() / InFootstepTraceData.Settings.MaxVelo;

		// const float Alpha = Math::Pow(NormalizedSpeed, 2.0);
		const float Alpha = Math::Min(NormalizedSpeed, 1);
		const float ScaledLength = Math::Lerp(InFootstepTraceData.Settings.MinLength, InFootstepTraceData.Settings.MaxLength, Alpha);
		return ScaledLength;
	}

	bool ValidateFootFrameVelo(FDragonFootstepTraceData& InFootstepTraceData)
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

	bool PerformFootTrace_Sphere(FDragonFootstepTraceData& InTraceData, const float TraceLength, bool bComplex = false, bool bDebug = false)
	{
		FHazeTraceSettings TraceSettings = InitTraceSettings();
		TraceSettings.SetTraceComplex(bComplex);
		TraceSettings.UseSphereShape(TraceLength);	

		// // This trace has already been invalidated this frame, bail
		// if(InTraceData.Trace.bPerformed)
		// 	return false;

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