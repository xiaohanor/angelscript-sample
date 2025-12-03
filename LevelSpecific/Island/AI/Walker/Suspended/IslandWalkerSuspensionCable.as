UCLASS(Abstract)
class AIslandWalkerSuspensionCable : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RotationBase;

	UPROPERTY(DefaultComponent, Attach = "RotationBase")
	UStaticMeshComponent Winch;

	UPROPERTY(DefaultComponent, Attach = "Winch")
	USceneComponent CableAttach;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	USceneComponent CableEndRoot;

	UPROPERTY(DefaultComponent, Attach = "CableAttach")
	UNiagaraComponent Cable;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueReflectComponent BulletReflectorComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MioMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ZoeMaterial;

	UIslandWalkerSuspendCouplingComponent CouplingComp = nullptr;
	AHazeActor CablesTarget;
	float DeployDuration;

	FSplinePosition SplinePos;
	FHazeAcceleratedFloat AccDistAlongSpline;
	float TargetDistAlongSpline;
	float MoveAlongSplineDuration = 10.0;

	FHazeAcceleratedVector AccNear;
	FHazeAcceleratedVector AccFar;
	FHazeAcceleratedVector AccEnd;

	bool bWasLatchedOn = false;
	float LatchOnFraction;
	FHazeAcceleratedFloat TightenDuration;

	bool bWeakened = false;
	bool bBroken = false;

	TArray<UMeshComponent> EndMeshes;

	FHazeAcceleratedRotator AccBaseRot;

	FVector IdealDirectionFromWalkerLocal = FVector::RightVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cable.AddComponentVisualsBlocker(this);
		Cable.AddComponentTickBlocker(this);

		CableEndRoot.GetChildrenComponentsByClass(UMeshComponent, true, EndMeshes);

		AIslandWalkerArenaLimits Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
		if (IsValid(Arena))
		{
			SplinePos = Arena.CablesRail.GetClosestSplinePositionToWorldLocation(ActorLocation);
			SetActorLocation(SplinePos.WorldLocation);
			AccDistAlongSpline.SnapTo(SplinePos.CurrentSplineDistance);
			TargetDistAlongSpline = SplinePos.CurrentSplineDistance;
		}
	}

	bool IsDeployed() const
	{
		if (CouplingComp == nullptr)
			return false;
		return true;
	}

	void Deploy(AHazeActor Walker, UIslandWalkerSuspendCouplingComponent CouplingComponent, float Duration)
	{
		if (CouplingComp != nullptr)
			return;

		bWasLatchedOn = false;
		CouplingComp = CouplingComponent;
		CablesTarget = Cast<AHazeActor>(CouplingComp.Owner);
		DeployDuration = Duration;
		LatchOnFraction = (DeployDuration > 0.0) ? 0.0 : 1.0;
		TightenDuration.SnapTo(2.0);

		AccBaseRot.SnapTo(RotationBase.WorldRotation);

		CableEndRoot.DetachFromParent(true);
		UMaterialInterface Material = (CouplingComponent.DestroyedByPlayer == EHazePlayer::Mio) ? MioMaterial : ZoeMaterial;
		for (UMeshComponent Mesh : EndMeshes)
		{
			Mesh.SetMaterial(0, Material);
		}
		
		Cable.RemoveComponentVisualsBlocker(this);
		Cable.RemoveComponentTickBlocker(this);

		AccNear.SnapTo(Cable.WorldLocation, Math::GetRandomPointInCircle_XY() * 2000.0);
		AccFar.SnapTo(Cable.WorldLocation, Math::GetRandomPointInCircle_XY() * 2000.0);
		AccEnd.SnapTo(CableEndRoot.WorldLocation, Math::GetRandomPointInCircle_XY() * 1500.0);

		IdealDirectionFromWalkerLocal = Walker.ActorTransform.InverseTransformVector(CableAttach.WorldLocation - CouplingComponent.WorldLocation).GetSafeNormal();

		UIslandWalkerPhaseComponent::Get(Walker).OnPhaseChange.AddUFunction(this, n"OnWalkerPhaseChange");

		UIslandWalkerEffectHandler::Trigger_OnSuspensionCableStartMoving(CablesTarget, FIslandWalkerCableEventData(this));
	}

	UFUNCTION()
	private void OnWalkerPhaseChange(EIslandWalkerPhase NewPhase)
	{
		if ((NewPhase >= EIslandWalkerPhase::Decapitated) && !IsActorDisabled())
			AddActorDisable(this);
	}

	void Break()
	{
		if (bBroken)
			return;
		
		// Weaken, then break (for the sake of effects)
		if (!bWeakened)
			UIslandWalkerEffectHandler::Trigger_OnSuspensionCableWeaken(CablesTarget, FIslandWalkerCableEventData(this));
		bWeakened = true;

		bBroken = true;

		// Hide ourselves and all our mesh children
		CableEndRoot.AddComponentVisualsBlocker(this);
		TArray<UMeshComponent> Meshes;
		CableEndRoot.GetChildrenComponentsByClass(UMeshComponent, true, Meshes);
		for (UMeshComponent Mesh : Meshes)
		{
			Mesh.AddComponentVisualsBlocker(this);
		}
		
		UIslandWalkerEffectHandler::Trigger_OnSuspensionCableBreak(CablesTarget, FIslandWalkerCableEventData(this));
	}

	void Weaken()
	{
		if (bWeakened)
			return;

		bWeakened = true;
		UIslandWalkerEffectHandler::Trigger_OnSuspensionCableWeaken(CablesTarget, FIslandWalkerCableEventData(this));
	}

	void Update(float DeltaTime)
	{
		float PrevDist = AccDistAlongSpline.Value;

		// For now we always move shortest path along looped spline		
		float TargetDelta = TargetDistAlongSpline - PrevDist;
		float SplineLength = SplinePos.CurrentSpline.SplineLength;
		if (Math::Abs(TargetDelta) > SplineLength * 0.5)
		{
			// Other way is shorter
			if (TargetDelta > 0.0)
				TargetDelta -= SplineLength;
			else
				TargetDelta += SplineLength;
		}

		const float MaxAcc = 5000.0;
		float Acceleration = Math::Clamp(TargetDelta, -MaxAcc, MaxAcc);
		AccDistAlongSpline.Value += AccDistAlongSpline.Velocity * DeltaTime + 0.5 * Acceleration * Math::Square(DeltaTime);

		float Friction = Math::GetMappedRangeValueClamped(FVector2D(100.0, 1000.0), FVector2D(2.0, 1.0), Math::Abs(TargetDelta));		
		AccDistAlongSpline.Velocity += Acceleration * DeltaTime;
		AccDistAlongSpline.Velocity *= Math::Pow(Math::Exp(-Friction), DeltaTime);

		SplinePos.Move(AccDistAlongSpline.Value - PrevDist);
	 	SetActorLocation(SplinePos.WorldLocation);

		FVector StartLoc = CableAttach.WorldLocation;
		FVector TargetLoc = CouplingComp.WorldLocation;
		FVector ToTarget = TargetLoc - StartLoc;

		if (bBroken)
		{
			// Sproing up and dangle
			AccNear.SpringTo(StartLoc - FVector(0.0, 0.0, 400.0), 10.0, 0.2, DeltaTime);
			AccFar.SpringTo(StartLoc - FVector(0.0, 0.0, 800.0), 10.0, 0.2, DeltaTime);
			AccEnd.SpringTo(StartLoc - FVector(0.0, 0.0, 1200.0), 10.0, 0.2, DeltaTime);

			CableEndRoot.WorldLocation = AccEnd.Value;
			CableEndRoot.WorldRotation = FRotator::MakeFromZ(AccFar.Value - AccEnd.Value);
		}
		else if (IsLatchedOn())
		{
			// Attached to coupling, tighten cable
			TightenDuration.AccelerateTo(0.2, 5.0, DeltaTime);
			AccNear.AccelerateTo(StartLoc + ToTarget * 0.25, TightenDuration.Value, DeltaTime);
			AccFar.AccelerateTo(StartLoc + ToTarget * 0.5, TightenDuration.Value, DeltaTime);
			AccEnd.AccelerateTo(TargetLoc, 0.1, DeltaTime);

			if (!bWasLatchedOn)
			{
				bWasLatchedOn = true;
				UIslandWalkerEffectHandler::Trigger_OnSuspensionCableLatchOn(CablesTarget, FIslandWalkerCableEventData(this));
			}

			CableEndRoot.WorldLocation = CouplingComp.WorldLocation;
			CableEndRoot.WorldRotation = CouplingComp.WorldRotation;
		}
		else 
		{
			// Reaching out to latch on
			LatchOnFraction = Math::Min(1.0, LatchOnFraction + DeltaTime / DeployDuration);
			float LatchOnAlpha = Math::EaseIn(0.0, 1.0, LatchOnFraction, 3.0);
			float FrictionFactor = Math::Pow(Math::Exp(-0.5), DeltaTime);
			float EndFrictionFactor = Math::Pow(Math::Exp(-0.25), DeltaTime);
			FVector CableEndLoc = AccEnd.Value;
			float CableLength = CableEndLoc.Distance(StartLoc);
			FVector CableDir = ((CableEndLoc - StartLoc) / CableLength);

			const float RestingLength = 1000.0;
			const float StretchForce = 10.0;

			FVector NearCenter = Math::LinePlaneIntersection(StartLoc, CableEndLoc, AccNear.Value, FVector::UpVector);
			if (!AccNear.Value.IsWithinDist(NearCenter, 10.0))
				AccNear.Velocity += (NearCenter - AccNear.Value) * StretchForce * DeltaTime;
			float NearStretchHeight = CableEndLoc.Z * 0.25 + StartLoc.Z * 0.75;
			if (AccNear.Value.Z < NearStretchHeight)
				AccNear.Velocity += FVector::UpVector * (NearStretchHeight - AccNear.Value.Z) * StretchForce * DeltaTime;
			AccNear.Velocity += FVector::DownVector * 982.0 * 1.0 * DeltaTime; 
			AccNear.Velocity *= FrictionFactor;
			AccNear.Value += AccNear.Velocity * DeltaTime;

			FVector FarCenter = Math::LinePlaneIntersection(StartLoc, CableEndLoc, AccFar.Value, FVector::UpVector);
			if (!AccFar.Value.IsWithinDist(FarCenter, 10.0))
				AccFar.Velocity += (FarCenter - AccFar.Value) * StretchForce * DeltaTime;
			float FarStretchHeight = CableEndLoc.Z * 0.5 + StartLoc.Z * 0.5;
			if (AccFar.Value.Z < FarStretchHeight)
				AccFar.Velocity += FVector::UpVector * (FarStretchHeight - AccFar.Value.Z) * StretchForce * DeltaTime;
			AccFar.Velocity += FVector::DownVector * 982.0 * 1.0 * DeltaTime; 
			AccFar.Velocity *= FrictionFactor;
			AccFar.Value += AccFar.Velocity * DeltaTime;

			if (CableLength > RestingLength)
				AccEnd.Velocity -= CableDir * (CableLength - RestingLength) * StretchForce * DeltaTime; 
			AccEnd.Velocity += FVector::DownVector * 982.0 * 3.0 * DeltaTime; 
			AccEnd.Velocity *= EndFrictionFactor;
			AccEnd.Value += AccEnd.Velocity * DeltaTime;
			AccEnd.Value = Math::Lerp(AccEnd.Value, TargetLoc, LatchOnAlpha);

			CableEndRoot.WorldLocation = AccEnd.Value;
			CableEndRoot.WorldRotation = FRotator(FQuat::Slerp(FQuat::MakeFromZ(AccFar.Value - AccEnd.Value), CouplingComp.WorldTransform.Rotation, LatchOnFraction));
		}

		Cable.SetVectorParameter(n"P0", StartLoc); 
		Cable.SetVectorParameter(n"P1", AccNear.Value); 
		Cable.SetVectorParameter(n"P2", AccFar.Value); 
		Cable.SetVectorParameter(n"P3", AccEnd.Value); 

		// Winch rotates to face cable end
		if (!CableEndRoot.WorldLocation.IsWithinDist2D(RotationBase.WorldLocation, 1.0))
		{
			FRotator TargetRot = FRotator::MakeFromZY(RotationBase.UpVector, (CableEndRoot.WorldLocation - RotationBase.WorldLocation));
			AccBaseRot.SpringTo(TargetRot, 4.0, 0.6, DeltaTime);
			RotationBase.SetWorldRotation(AccBaseRot.Value);
		}
	}

	bool IsLatchedOn() const
	{
		return (LatchOnFraction > 0.999);
	}
}
