struct FFootstepTrace
{
	UPROPERTY()
	bool bPerformed = false;

	UPROPERTY()
	bool bGrounded = false;
		
	UPROPERTY()
	FVector LastBlockingHitNormal = FVector();
};

USTRUCT()
struct FFootstepTraceData
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
	UPhysicalMaterial LastPhysMat = nullptr;

	FFootstepTraceData(const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}

	FFootstepTraceData(const FName InTag, const FVector InStart, const FVector InEnd, FFootstepTrace& InTrace)
	{
		TraceDataTag = InTag;
		Start = InStart;
		End = InEnd;
		Trace = InTrace;
	}
}

USTRUCT()
struct FHandTraceData
{
	UPROPERTY()
	EHandType Hand;

	UPROPERTY(BlueprintReadOnly)
	FName TraceDataTag = NAME_None;

	UPROPERTY(BlueprintReadOnly)
	FVector Start;

	UPROPERTY(BlueprintReadOnly)
	FVector End;

	UPROPERTY(BlueprintReadOnly)
	FVector Velo;

	UPROPERTY(BlueprintReadOnly)
	float VeloSpeed = 0.0;

	UPROPERTY(BlueprintReadOnly)
	FHandTrace Trace;

	UPROPERTY(BlueprintReadOnly)
	FHitResult Hit;

	UPROPERTY(BlueprintReadOnly)
	FHandTraceSettings Settings;

	UPROPERTY(BlueprintReadOnly)
	float ScaledTraceLength = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float PlantTriggerTimeStamp = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float ReleaseTriggerTimeStamp = 0.0;

	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial GroundedPhysMat = nullptr;

	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial LastPhysMat = nullptr;

	UPROPERTY(BlueprintReadOnly)
	AActor ContactActor = nullptr;

	UPROPERTY(BlueprintReadOnly)
	FVector ContactActorVelocity;

	bool bValidFrameVelo = false;
}

USTRUCT()
struct FHandTrace
{
	UPROPERTY()
	bool bPerformed = false;

	UPROPERTY()
	bool bGrounded = false;

	UPROPERTY()
	float GroundedTimestamp = 0;

	UPROPERTY()
	bool bIsSliding = false;
		
	UPROPERTY()
	FVector LastBlockingHitNormal = FVector();

#if EDITOR
	FVector DEBUG_SlideStartLocation;
#endif
}

class UFootstepTraceComponent : UHazeAudioTraceComponent
{
	default ComponentTickEnabled = false;
	
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter PlayerOwner;

	UPhysicalMaterialAudioAsset FoliageMaterialOverride;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		MoveComp = UHazeMovementComponent::Get(Owner);	
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	void OnFoliageMaterialOverride(UPhysicalMaterialAudioAsset MaterialOverride)
	{
		FoliageMaterialOverride = MaterialOverride;
	}

	FHazeTraceSettings InitTraceSettings()
	{
		if(!devEnsure(PlayerOwner != nullptr, f"No PlayerOwner when tracing audio with TraceComponent: {GetName()}"))
			return FHazeTraceSettings();

		FHazeTraceSettings TraceSettings = FHazeTraceSettings();
		TraceSettings.TraceWithChannel(ECollisionChannel::AudioTrace);

		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);
		TraceSettings.IgnoreActor(Owner);

		return TraceSettings;
	}

	bool PerformTrace_Simple(FPlayerFootstepTraceData& InTraceData)
	{	
		// Try scaling length of trace based on movement speed. 
		// The idea is to catch smaller feet  movements easier when standing still.
		// The trace needs to be shorter to account for these small changes.

		FHazeTraceSettings TraceSettings = InitTraceSettings();
		
		InTraceData.Hit = TraceSettings.QueryTraceSingle(InTraceData.Start, InTraceData.End);
		InTraceData.Trace.bPerformed = true;
		
		if (InTraceData.Hit.bBlockingHit && !InTraceData.Trace.bGrounded)
		{
			// New hit was blocking while last wasn't - perform footstep
			InTraceData.Trace.bGrounded = true;
			InTraceData.Trace.LastBlockingHitNormal = InTraceData.Hit.Normal;

			return true;
		}
		else if(!InTraceData.Hit.bBlockingHit)
		{			
			// Non-blocking hit - allow for new footstep to be performed on next hit
			InTraceData.Trace.bGrounded = false;
			return false;
		}		

		return false;
	}

	bool PerformTrace_Sphere(FVector Start, FVector End, FHitResult& OutHitResults, bool bComplex = false)
	{
		FHazeTraceSettings TraceSettings = InitTraceSettings();

		TraceSettings.SetTraceComplex(bComplex);
		TraceSettings.UseSphereShape(7);

		OutHitResults = TraceSettings.QueryTraceSingle(Start, End);
		return OutHitResults.bBlockingHit;
	}

	bool PerformTrace_Box(FPlayerFootstepTraceData& InTraceData, FQuat Orientation = FQuat::Identity, bool bComplex = false, bool bDebug = false)
	{		
		FHazeTraceSettings TraceSettings = InitTraceSettings();
		TraceSettings.SetTraceComplex(bComplex);
		TraceSettings.UseBoxShape(InTraceData.ScaledBoxExtends, Orientation);
		TraceSettings.SetReturnPhysMaterial(true);

		InTraceData.Trace.bPerformed = true;

		if(bDebug)
		{
			FHazeTraceDebugSettings DebugSettings;

			DebugSettings.Thickness = 5.0;
			DebugSettings.ImpactThickness = 10.0;
			DebugSettings.bDrawTraceDirection = true;
			DebugSettings.bDrawImpactNormal = true;

			DebugSettings.TraceBlockingHitColor = FLinearColor::Red;
			DebugSettings.TraceAfterHitColor = FLinearColor::Yellow;
			DebugSettings.TraceOverlapHitColor = FLinearColor::Blue;

			TraceSettings.DebugDraw(DebugSettings);	
		}

		FHitResult WantedHitResult;
		FHitResultArray HitResultsArray = TraceSettings.QueryTraceMulti(InTraceData.Start, InTraceData.End);

		for(auto HitResult : HitResultsArray.HitResults)
		{
			if(!HitResult.bBlockingHit)
				continue;

			FVector ToImpact = (HitResult.ImpactPoint - InTraceData.Start).GetSafeNormal();
			FVector FootDir = (InTraceData.End - InTraceData.Start).GetSafeNormal();

			const float HitDot = FootDir.DotProduct(ToImpact);

			// if(HitDot < SMALL_NUMBER)
			// 	continue;

			WantedHitResult = HitResult;
			break;
		}	

		InTraceData.Hit = WantedHitResult;

		if(!InTraceData.Hit.bBlockingHit)
		{
			// Non-blocking hit - allow for new footstep to be performed on next hit
			const bool bWasGrounded = InTraceData.Trace.bGrounded;
			InTraceData.Trace.bGrounded = false;

			// Last check was grounded, perform Release
			if(bWasGrounded)
				return true;

			return false;
		}
		else if(!InTraceData.Trace.bGrounded)
		{
			// New hit was blocking while last wasn't - perform Plant
			InTraceData.Trace.bGrounded = true;
			return true;
		}	

		return false;
	}

	bool PerformFootTrace_Sphere(FPlayerFootstepTraceData& InTraceData, const float TraceLength, bool bComplex = false, bool bDebug = false)
	{
		FHazeTraceSettings TraceSettings = InitTraceSettings();
		TraceSettings.SetTraceComplex(bComplex);
		TraceSettings.UseSphereShape(TraceLength);

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

		// This trace has already been invalidated this frame, bail
		if(InTraceData.Trace.bPerformed)
		{
			#if EDITOR
				InTraceData.bInvalidated = true;
			#endif

			return false;
		}

		InTraceData.Trace.bPerformed = true;	


		FHitResult Result = TraceSettings.QueryTraceSingle(InTraceData.Start, InTraceData.End);

		InTraceData.Hit = Result;

		if(!InTraceData.Hit.bBlockingHit)
		{
			// Non-blocking hit - allow for new footstep to be performed on next hit
			const bool bWasGrounded = InTraceData.Trace.bGrounded;
			InTraceData.Trace.bGrounded = false;

			// Last check was grounded, perform Release
			if(bWasGrounded)
				return true;

			return false;
		}
		else if(!InTraceData.Trace.bGrounded)
		{
			// Make sure hit wasn't from behind foot
			if(!InTraceData.Hit.bStartPenetrating)
			{
				const FVector ToHit = (InTraceData.Hit.ImpactPoint - InTraceData.Start).GetSafeNormal();
				const FVector TraceDir = (InTraceData.Hit.TraceEnd - InTraceData.Hit.TraceStart).GetSafeNormal();

				const float Dot = ToHit.DotProduct(TraceDir);
				if(Dot < KINDA_SMALL_NUMBER)
					return false;
			}

			// If we get a hit while not on walkable ground we need check if it's still a valid hit
			// The idea is to filter out hits that might happen on surfaces that pushes the player away
			if(!MoveComp.IsOnWalkableGround())
			{				
				if (!InTraceData.Settings.bForceHits)
				{						
					auto HitComponent = InTraceData.Hit.Component;
					const bool bValidNonWalkableHit = HitComponent.HasTag(ComponentTags::WallRunnable)
					 					|| HitComponent.HasTag(ComponentTags::WallScrambleable)
										|| HitComponent.HasTag(ComponentTags::Walkable);

					// Bail if non-valid hit
					if(!bValidNonWalkableHit)
						return false;
					
					// Let's double check it's a valid trace for walkables.
					if(HitComponent.HasTag(ComponentTags::Walkable))
					{
						// Uses the same logic as in the player movement component
						auto WorldUp = MoveComp.GetWorldUp();
						const float ImpactAngle = WorldUp.GetAngleDegreesTo(InTraceData.Hit.ImpactNormal);
						const float HitResultWalkableSlopeAngle = HitComponent.GetWalkableSlopeAngle(MoveComp.GetWalkableSlopeAngle());

						if((HitResultWalkableSlopeAngle >= 0 && ImpactAngle < HitResultWalkableSlopeAngle) == false)
							return false;
					}
				}
			}

			// Get physmat from hit
			InTraceData.GroundedPhysMat = AudioTrace::GetPhysMaterialFromHit(InTraceData.Hit, TraceSettings);

			// New hit was blocking while last wasn't - perform Plant
			InTraceData.Trace.bGrounded = true;

			return true;
		}	

		return false;
	}

	bool PerformHandTrace_Sphere(FHandTraceData& InHandTraceData, const float SphereRadius, bool bComplex = false, bool bDebug = false)
	{
		FHazeTraceSettings TraceSettings = InitTraceSettings();
		TraceSettings.SetTraceComplex(bComplex);

		TraceSettings.UseSphereShape(SphereRadius);	

		InHandTraceData.Trace.bPerformed = true;	

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
	
		FHitResult Result = TraceSettings.QueryTraceSingle(InHandTraceData.Start, InHandTraceData.End);
		InHandTraceData.Hit = Result;		
		
		// FVector ToImpact = (Result.ImpactPoint - InHandTraceData.Start).GetSafeNormal();
		// FVector HandDir = (InHandTraceData.End - InHandTraceData.Start).GetSafeNormal();

		// const float HitDot = HandDir.DotProduct(ToImpact);	

		// //Was hit within wanted direction of trace?
		// if(!Result.bStartPenetrating && HitDot < SMALL_NUMBER)
		// 	return false;			

		// // Was direction of hit within margin of error compared to direction of hand movement?
		// const float VeloDot = InHandTraceData.Velo.GetSafeNormal().DotProduct(ToImpact);
		// if(VeloDot < SMALL_NUMBER)
		// 	return false;

		if(Result.bBlockingHit)		
		{
			InHandTraceData.GroundedPhysMat = AudioTrace::GetPhysMaterialFromHit(Result, TraceSettings);	
			InHandTraceData.LastPhysMat = InHandTraceData.GroundedPhysMat;	
			InHandTraceData.ContactActor = Result.Actor;
		}
		else	
			InHandTraceData.GroundedPhysMat = nullptr;		

		return Result.bBlockingHit;
	}
}