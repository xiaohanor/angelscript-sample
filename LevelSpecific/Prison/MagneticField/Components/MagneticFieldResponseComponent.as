event void FMagneticFieldEvent();
event void FMagneticFieldBurstEvent(FMagneticFieldData Data);
event void FMagneticFieldPushEvent(FMagneticFieldData Data);
event void FMagneticFieldResponseComponentMagnetizedStatusUpdated(bool bMagnetic);

// Represents one push against a response component
struct FMagneticFieldData
{
	UPROPERTY()
	bool bBurst;

	UPROPERTY()
	FVector ForceOrigin;

	UPROPERTY()
	TArray<FMagneticFieldComponentData> ComponentDatas;

	bool AffectedAnything() const
	{
		return ComponentDatas.Num() > 0;
	}

	// Adds all forces together, then normalizes
	FVector GetAverageForceDirection() const
	{
		FVector ForceDirection;

		for(auto& Affected : ComponentDatas)
		{
			ForceDirection += (Affected.ForceAffectPoint - ForceOrigin).GetSafeNormal();
		}

		return ForceDirection.GetSafeNormal();
	}

	// Adds all forces together while taking proximity into account, then divides by the count
	FVector GetAverageForce() const
	{
		FVector Force;

		for(auto& Affected : ComponentDatas)
		{
			Force += (Affected.ForceAffectPoint - ForceOrigin).GetSafeNormal() * Affected.ProximityFraction;
		}

		Force /= ComponentDatas.Num();

		return Force;
	}

	bool GetForceAndPointForComponent(USceneComponent Component, FVector&out Force, FVector&out Point) const
	{
		for(auto ComponentData : ComponentDatas)
		{
			if(ComponentData.AffectedComp == Component)
			{
				Force = (ComponentData.ForceAffectPoint - ForceOrigin).GetSafeNormal() * ComponentData.ProximityFraction;
				Point = ComponentData.ForceAffectPoint;
				return true;
			}
		}

		return false;
	}
}

// Represents one push against a magnetic component
struct FMagneticFieldComponentData
{
	UPROPERTY()
	USceneComponent AffectedComp;

	UPROPERTY()
	FVector ForceAffectPoint;

	UPROPERTY()
	float ProximityFraction;
}

/**
 * 
 */
 UCLASS(NotBlueprintable)
class UMagneticFieldResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	access Internal = private, UMagneticFieldResponseComponentVisualizer;

	UPROPERTY()
	FMagneticFieldEvent OnStartBeingMagneticallyAffected;

	UPROPERTY()
	FMagneticFieldEvent OnStopBeingMagneticallyAffected;

	UPROPERTY()
	FMagneticFieldBurstEvent OnBurst;

	UPROPERTY()
	FMagneticFieldPushEvent OnPush;

	UPROPERTY()
	FMagneticFieldResponseComponentMagnetizedStatusUpdated OnMagnetizedStatusUpdated;

	UPROPERTY(EditAnywhere, Category = "FauxPhysics")
	bool bAffectFauxPhysics = true;

	UPROPERTY(EditAnywhere, Category = "FauxPhysics", Meta = (EditCondition = "bAffectFauxPhysics"))
	bool bUseProximityScalar = true;

	UPROPERTY(EditAnywhere, Category = "FauxPhysics", Meta = (EditCondition = "bAffectFauxPhysics"))
	float ImpulseStrength = 2500.0;

	UPROPERTY(EditAnywhere, Category = "FauxPhysics", Meta = (EditCondition = "bAffectFauxPhysics"))
	float PushStrength = 5000.0;

	// Enable this to override the direction we apply the forces in
	UPROPERTY(EditAnywhere, Category = "FauxPhysics", Meta = (EditCondition = "bAffectFauxPhysics"))
	bool bOverrideRepelDirection = false;

	UPROPERTY(EditAnywhere, Category = "FauxPhysics", Meta = (EditCondition = "bAffectFauxPhysics && bOverrideRepelDirection"))
	FRotator RepelDirection = FRotator::ZeroRotator;

	bool bMagnetized = true;

	private bool bWasBurst;
	private uint LastMagneticPushFrame = 0;
	private bool bIsMagneticallyAffected = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsMagneticallyAffected)
		{
			if(LastMagneticPushFrame < Time::FrameNumber)
			{
				OnStopBeingMagneticallyAffected.Broadcast();
				bIsMagneticallyAffected = false;
				SetComponentTickEnabled(false);
			}
		}
	}

	void BurstActivated(const FMagneticFieldData& Data)
	{
		check(bMagnetized);

		bWasBurst = true;
		LastMagneticPushFrame = Time::FrameNumber;

		OnBurst.Broadcast(Data);

		if (bAffectFauxPhysics)
			ApplyBurstImpulseToFauxPhysics(Data);

		if(!bIsMagneticallyAffected)
		{
			bIsMagneticallyAffected = true;
			OnStartBeingMagneticallyAffected.Broadcast();
			SetComponentTickEnabled(true);
		}
	}

	void UpdatePush(const FMagneticFieldData& Data)
	{
		check(bMagnetized);

		bWasBurst = false;
		LastMagneticPushFrame = Time::FrameNumber;

		OnPush.Broadcast(Data);

		if (bAffectFauxPhysics)
			ApplyRepelForceToFauxPhysics(Data);

		if(!bIsMagneticallyAffected)
		{
			bIsMagneticallyAffected = true;
			OnStartBeingMagneticallyAffected.Broadcast();
			SetComponentTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetMagnetizedStatus(bool bMagnetic)
	{
		if(bMagnetic == bMagnetized)
			return;

		bMagnetized = bMagnetic;
		OnMagnetizedStatusUpdated.Broadcast(bMagnetized);
	}

	void ApplyBurstImpulseToFauxPhysics(const FMagneticFieldData& Data) const
	{
		for(const auto& AffectedData : Data.ComponentDatas)
		{
			const FVector Impulse = GetBurstImpulse(Data, AffectedData);
			FauxPhysics::ApplyFauxImpulseToParentsAt(AffectedData.AffectedComp, AffectedData.ForceAffectPoint, Impulse);
		}
	}

	void ApplyRepelForceToFauxPhysics(const FMagneticFieldData& Data) const
	{
		for(const auto& AffectedData : Data.ComponentDatas)
		{
			const FVector Force = GetRepelForce(Data, AffectedData);
			FauxPhysics::ApplyFauxForceToParentsAt(AffectedData.AffectedComp, AffectedData.ForceAffectPoint, Force);
		}
	}

	private FVector GetBurstImpulse(FMagneticFieldData Data, FMagneticFieldComponentData AffectedData) const
	{
		const FVector Direction = GetRepelDirection(Data, AffectedData);

		if(bOverrideRepelDirection)
		{
			// Special case for when a big faux physics translate actor does not care what direction the force is coming from.
			// We still check that the origin is on the correct side to push in the ConstantDirection
			FPlane Plane = FPlane(AffectedData.ForceAffectPoint, Direction);
			if(Plane.PlaneDot(Data.ForceOrigin) > 0)
				return FVector::ZeroVector;
		}

		const float Magnitude = ImpulseStrength * (bUseProximityScalar ? AffectedData.ProximityFraction : 1.0);
		return Direction * Magnitude;
	}

	private FVector GetRepelForce(FMagneticFieldData Data, FMagneticFieldComponentData AffectedData) const
	{
		const FVector Direction = GetRepelDirection(Data, AffectedData);

		if(bOverrideRepelDirection)
		{
			// Special case for when a big faux physics translate actor does not care what direction the force is coming from.
			// We still check that the origin is on the correct side to push in the ConstantDirection
			FPlane Plane = FPlane(AffectedData.ForceAffectPoint, Direction);
			if(Plane.PlaneDot(Data.ForceOrigin) > 0)
				return FVector::ZeroVector;
		}

		const float Magnitude = PushStrength * (bUseProximityScalar ? AffectedData.ProximityFraction : 1.0);
		return Direction * Magnitude;
	}

	private FVector GetRepelDirection(FMagneticFieldData Data, FMagneticFieldComponentData AffectedData) const
	{
		if(bOverrideRepelDirection)
		{
			return GetConstantDirection();
		}
		else
		{
			check(!AffectedData.ForceAffectPoint.Equals(Data.ForceOrigin, KINDA_SMALL_NUMBER), "ForceOrigin and ForceAffectPoint were identical!");
			return (AffectedData.ForceAffectPoint - Data.ForceOrigin).GetSafeNormal();
		}
	}

	access:Internal
	FVector GetConstantDirection() const
	{
		return Owner.ActorRotation.Compose(RepelDirection).ForwardVector;
	}

	bool WasBurstThisFrame() const
	{
		if(!bWasBurst)
			return false;

		return LastMagneticPushFrame == Time::FrameNumber;
	}

	bool WasPushedThisFrame() const
	{
		if(bWasBurst)
			return false;

		return LastMagneticPushFrame == Time::FrameNumber;
	}

	bool WasMagneticallyAffectedThisFrame() const
	{
		return LastMagneticPushFrame == Time::FrameNumber;
	}
};

#if EDITOR
class UMagneticFieldResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMagneticFieldResponseComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ResponseComp = Cast<UMagneticFieldResponseComponent>(Component);
		if(ResponseComp == nullptr)
			return;

		if(ResponseComp.bOverrideRepelDirection)
		{
			FVector Direction = ResponseComp.GetConstantDirection();
			DrawArrow(ResponseComp.Owner.ActorLocation, ResponseComp.Owner.ActorLocation + Direction * 500, FLinearColor::Green, 50, 10, true);
			DrawCircle(ResponseComp.Owner.ActorLocation, 200, FLinearColor::Green, 5, Direction);
		}
	}
}
#endif