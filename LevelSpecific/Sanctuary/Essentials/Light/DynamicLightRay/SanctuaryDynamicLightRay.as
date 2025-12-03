class USanctuaryDynamicLightRayVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryDynamicLightRayVisualizerComponent;

	private TArray<FSanctuaryLightRayPart> VisualizedParts;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		VisualizedParts.Reset();

		auto DynamicLightRay = Cast<ASanctuaryDynamicLightRay>(InComponent.Owner);

		QueryVisualizedLightRay(DynamicLightRay);

		for (int i = 0; i < VisualizedParts.Num(); ++i)
		{
			const auto& Part = VisualizedParts[i];

			DrawLine(Part.StartLocation, Part.EndLocation, FLinearColor::Yellow, 10.0, false);
		}

	//	DrawLine(DynamicLightRay.SourceComponent.WorldLocation, DynamicLightRay.SourceComponent.WorldLocation + DynamicLightRay.SourceComponent.ForwardVector * 1000.0, FLinearColor::Yellow, 10.0, false);
	}

	private void QueryVisualizedLightRay(ASanctuaryDynamicLightRay DynamicLightRay)
	{
		float RemainingLength = DynamicLightRay.RayLength;

		TArray<AActor> HitActors;
		FVector Location = DynamicLightRay.SourceComponent.WorldLocation;
		FVector Direction = DynamicLightRay.SourceComponent.ForwardVector;
		for (int i = 0; i < DynamicLightRay.MaximumBounces; ++i)
		{
			auto Part = QueryVisualizedLightRayPart(
				Location,
				Direction,
				RemainingLength,
				HitActors,
				DynamicLightRay
			);

			VisualizedParts.Add(Part);

			// No more bouncing allowed
			if (RemainingLength <= DynamicLightRay.MinimumPartLength)
				break;
			if (Part.ReflectComponent == nullptr)
				break;
		}
	}

	private FSanctuaryLightRayPart QueryVisualizedLightRayPart(FVector& Location, FVector& Direction, float& Length, TArray<AActor>& HitActors, ASanctuaryDynamicLightRay DynamicLightRay)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(DynamicLightRay);
		Trace.IgnoreActors(HitActors);

		FVector EndLocation = Location + (Direction * Length);
		auto HitResult = Trace.QueryTraceSingle(Location, EndLocation);

		FSanctuaryLightRayPart Part;
		Part.StartLocation = Location;
		Part.EndLocation = EndLocation;
		Part.Normal = (EndLocation - Location).GetSafeNormal();

		if (HitResult.bBlockingHit)
		{
			Length *= (1.0 - HitResult.Time);
			Part.EndLocation = HitResult.ImpactPoint - Part.Normal * 0.125;

			auto ResponseComp = USanctuaryDynamicLightRayResponseComponent::Get(HitResult.Actor);
			if (ResponseComp != nullptr)
			{
				if (HitResult.Component != nullptr)
				{
					TArray<UPrimitiveComponent> RespondingPrimitives;

					for(FComponentReference ComponentRef : ResponseComp.RespondingComponents)
					{
						UActorComponent Comp = ComponentRef.GetComponent(ResponseComp.Owner);
						if(Comp == nullptr)
							continue;

						UPrimitiveComponent PrimitiveComp = Cast<UPrimitiveComponent>(Comp);
						if(PrimitiveComp == nullptr)
							continue;

						RespondingPrimitives.Add(PrimitiveComp);
					}

					if (ResponseComp.bReflect && RespondingPrimitives.Contains(HitResult.Component))
					{
						Part.Normal = HitResult.ImpactNormal;
						Part.ReflectComponent = HitResult.Component;
						Part.LastComponentTransform = HitResult.Component.WorldTransform;

						Direction = Direction.GetReflectionVector(Part.Normal);
					}
				}
			}

			HitActors.Add(HitResult.Actor);
		}

		Location = Part.EndLocation;

		return Part;
	}
}

class USanctuaryDynamicLightRayVisualizerComponent : UActorComponent
{

}

struct FSanctuaryLightRayPart
{
	FVector StartLocation = FVector::ZeroVector;
	FVector EndLocation = FVector::ZeroVector;
	FVector Normal = FVector::ForwardVector;
	USceneComponent ReflectComponent = nullptr;
	FTransform LastComponentTransform = FTransform::Identity;

	FVector GetDirection() const property
	{
		return (EndLocation - StartLocation).GetSafeNormal();
	}

	float GetLength() const property
	{
		return (EndLocation - StartLocation).Size();
	}

	bool HasComponentMoved() const
	{
		if (ReflectComponent == nullptr)
			return false;

		return !ReflectComponent.WorldTransform.Equals(LastComponentTransform);
	}
}

class ASanctuaryDynamicLightRay : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent)
	UArrowComponent SourceComponent;
	default SourceComponent.ArrowColor = FLinearColor::Yellow;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryDynamicLightRayVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent)
	USanctuaryDynamicLightRayMeshAudioComponent AudioMeshComp;

	UPROPERTY(EditAnywhere, EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	bool bStartEnabled;

	/**
	 * Whether any parts of this ray will require recalculation, only enable if this actor moves or anything can occlude it.
	 * This is probably going to be very buggy, as we might be moving the contextual move actors and scaling them.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	bool bAllowRecalculation = true;

	// How many times the light ray is allowed to bounce.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	int MaximumBounces = 4;

	// Maximum travel distance of the ray in it's entirety.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	float RayLength = 10000.0;

	// Minimum length a part has to be to create an actor for it.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	float MinimumPartLength = 250.0;

	// Maximum angle deviation from world up the ray should spawn poles for, anything else will be perch splines.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	float MaximumPoleAngle = 60.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	bool bOverridePerchSplineActivationRange = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray", Meta = (EditCondition = "bOverridePerchSplineActivationRange"))
	float PerchSplineActivationRange = 450.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	bool bOverridePerchSplineMaximumVerticalJumpToAngle = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray", Meta = (EditCondition = "bOverridePerchSplineMaximumVerticalJumpToAngle"))
	float PerchSplineMaximumVerticalJumpToAngle = 30.0;

	// Subclass of the perch spline actor to spawn when one parts direction is pointing upwards.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	TSubclassOf<ASanctuaryDynamicLightRayPerchSpline> PerchSplineClass = nullptr;

	// Subclass of the pole actor to spawn when one parts direction is pointing forwards.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	TSubclassOf<APoleClimbActor> PoleActorClass = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird Response")
	bool bListenToParentLightBirdResponse = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Ray")
	float DefaultPoleTwistAngle = 0.0;

	UPROPERTY(EditAnywhere, Category = "Network", AdvancedDisplay)
	bool bCrumbPerchRelativeToPerchSpline = false;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> AdditionalIgnoreActors;

	private FTransform LastSourceTransform;
	private TArray<FSanctuaryLightRayPart> Parts;
	private TArray<ASanctuaryDynamicLightRayPole> Poles;
	private TArray<ASanctuaryDynamicLightRayPerchSpline> PerchSplines;

	private TArray<USanctuaryDynamicLightRayResponseComponent> HitResponseComponents;
	private TArray<USanctuaryDynamicLightRayResponseComponent> ActiveResponseComponents;

	bool bIsActivated = false;

	UPROPERTY()
	float ActivatedRotationSpeed = 180.0;

	UPROPERTY()
	float BaseRotationSpeed = 10.0;

	UPROPERTY()
	float AccelerationDuration = 1.0;

	FHazeAcceleratedFloat AcceleratedRotationSpeed;

	int IdentifierInt;

	void GetLightRayParts(TArray<FSanctuaryLightRayPart>& outParts) const { outParts = Parts; }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bListenToParentLightBirdResponse && AttachParentActor != nullptr)
			LightBirdResponseComponent.AddListenToResponseActor(AttachParentActor);

		Poles.SetNumZeroed(MaximumBounces);
		PerchSplines.SetNumZeroed(MaximumBounces);

		for (int i = 0; i < MaximumBounces; ++i)
		{
			auto Pole = SpawnPole(ActorLocation, ActorRotation);
			Pole.Disable(this);
			Poles[i] = Pole;

			auto PerchSpline = SpawnPerchSpline(ActorLocation, ActorRotation);
			PerchSpline.Disable(this);
			PerchSplines[i] = PerchSpline;
		}

		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

		if (bStartEnabled)
			bIsActivated = true;
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		auto UserComp = ULightBirdUserComponent::Get(Game::Mio);

		for (auto Pole : Poles)
			Pole.RemoveDisable(UserComp);
		for (auto PerchSpline : PerchSplines)
			PerchSpline.RemoveDisable(UserComp);
	
		for (auto ActiveResponseComponent : ActiveResponseComponents)
			ActiveResponseComponent.Illuminate(this);

		bIsActivated = true;
		USanctuaryDynamicLightRayEventHandler::Trigger_LightRayActivated(this);
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		auto UserComp = ULightBirdUserComponent::Get(Game::Mio);

		for (auto Pole : Poles)
			Pole.Disable(UserComp);
		for (auto PerchSpline : PerchSplines)
			PerchSpline.Disable(UserComp);

		for (auto ActiveResponseComponent : ActiveResponseComponents)
			ActiveResponseComponent.Unilluminate(this);
	
		bIsActivated = false;
		USanctuaryDynamicLightRayEventHandler::Trigger_LightRayDeactivated(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AcceleratedRotationSpeed.AccelerateTo((bIsActivated ? ActivatedRotationSpeed : BaseRotationSpeed), AccelerationDuration, DeltaTime);
		RotationPivot.AddRelativeRotation(FRotator(0.0, 0.0, AcceleratedRotationSpeed.Value * DeltaTime));

		if (!bIsActivated)
			return;

		// TEMP FIX
//		if (!NeedsRecalculation())
//			return;

		// Reset hit respons components this tick to compare with active
		HitResponseComponents.Reset(MaximumBounces);

		// Query all parts of the light ray again, we could recalculate only
		//  the parts that will move, which we know from which reflected transform
		//  has moved (or in it's entirety if it's the source component that has moved)
		QueryLightRay();

		// Build the pole/perch actors along the ray according to each parts direction
		//  in relation to world up
		for (int i = 0; i < Parts.Num(); ++i)
		{
			const auto& Part = Parts[i];

			if (Part.Length < MinimumPartLength)
			{
				Poles[i].Disable(this);
				PerchSplines[i].Disable(this);

				continue;
			}

			FVector Direction = Part.Direction;
			float Angle = Math::RadiansToDegrees(
				Direction.AngularDistanceForNormals(FVector::UpVector)
			);

			if (Angle < MaximumPoleAngle)
			{
				auto Pole = Poles[i];
				Pole.SetActorLocationAndRotation(
					Part.StartLocation,
					FRotator::MakeFromZX(Part.Direction, AttachParentActor.ActorRightVector.RotateAngleAxis(DefaultPoleTwistAngle, FVector::UpVector)) // Illegal hax to fix the pole rotation in the mirror room in towers - UXR TEMP
					//FRotator::MakeFromZ(Part.Direction)
				);
				Pole.SetNewHeight(Part.Length);
				Pole.UpdateHeight();

				Pole.RemoveDisable(this);
				PerchSplines[i].Disable(this);
			}
			else
			{
				auto PerchSpline = PerchSplines[i];
				PerchSpline.SetActorLocationAndRotation(
					Part.StartLocation,
					FRotator::MakeFromZ(Part.Direction)
				);
				PerchSpline.UpdateHeight(Part.Length);

				TArray<FHazeSplinePoint> Points;

				FHazeSplinePoint StartPoint;
				StartPoint.RelativeLocation = FVector::ZeroVector;
				StartPoint.bOverrideTangent = true;
				StartPoint.bDiscontinuousTangent = true;
				StartPoint.ArriveTangent = FVector::UpVector;
				StartPoint.LeaveTangent = FVector::UpVector;
				Points.Add(StartPoint);

				FHazeSplinePoint EndPoint;
				EndPoint.RelativeLocation = PerchSpline.ActorTransform.InverseTransformPosition(Part.EndLocation);
				EndPoint.bOverrideTangent = true;
				EndPoint.bDiscontinuousTangent = true;
				EndPoint.ArriveTangent = FVector::UpVector;
				EndPoint.LeaveTangent = FVector::UpVector;
				Points.Add(EndPoint);

				PerchSpline.Spline.SplinePoints = Points;
				PerchSpline.Spline.UpdateSpline();
				PerchSpline.UpdateEnterZones();

				PerchSpline.RemoveDisable(this);
				Poles[i].Disable(this);
			}
		}

		if (!bAllowRecalculation)
			SetActorTickEnabled(false);
	
		// Compare this ticks hit respons with currently active respons components
		UpdateResponseComponents();
	}

	private void UpdateResponseComponents()
	{
		for (auto ActiveResponseComponent : ActiveResponseComponents)
		{
			if (!HitResponseComponents.Contains(ActiveResponseComponent))
				ActiveResponseComponent.Unilluminate(this);
		}

		ActiveResponseComponents = HitResponseComponents;
	}

	private void QueryLightRay()
	{
		int NumOfPrevParts = Parts.Num();

		Parts.Empty();

		float RemainingLength = RayLength;

		TArray<AActor> HitActors;
		FVector Location = SourceComponent.WorldLocation;
		FVector Direction = SourceComponent.ForwardVector;
		for (int i = 0; i < MaximumBounces; ++i)
		{
			auto Part = QueryLightRayPart(
				Location,
				Direction,
				RemainingLength,
				HitActors
			);

			Parts.Add(Part);

			// No more bouncing allowed
			if (RemainingLength <= MinimumPartLength)
				break;
			if (Part.ReflectComponent == nullptr)
				break;
		}

		LastSourceTransform = SourceComponent.WorldTransform;
	
		for (int i = Parts.Num(); i < MaximumBounces; i++)
		{
			Poles[i].Disable(this);
			PerchSplines[i].Disable(this);
		}
	}

	private FSanctuaryLightRayPart QueryLightRayPart(FVector& Location, FVector& Direction, float& Length, TArray<AActor>& HitActors)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		Trace.IgnoreActors(HitActors);
		Trace.IgnoreActors(AdditionalIgnoreActors);

		for (auto Pole : Poles)
			Trace.IgnoreActor(Pole);
		for (auto PerchSpline : PerchSplines)
			Trace.IgnoreActor(PerchSpline);

		FVector EndLocation = Location + (Direction * Length);
		auto HitResult = Trace.QueryTraceSingle(Location, EndLocation);

		FSanctuaryLightRayPart Part;
		Part.StartLocation = Location;
		Part.EndLocation = EndLocation;
		Part.Normal = (EndLocation - Location).GetSafeNormal();

		if (HitResult.bBlockingHit)
		{
			Length *= (1.0 - HitResult.Time);
			Part.EndLocation = HitResult.ImpactPoint - Part.Normal * 0.125;

			auto ResponseComp = USanctuaryDynamicLightRayResponseComponent::Get(HitResult.Actor);
			if (ResponseComp != nullptr)
			{
				if (HitResult.Component != nullptr && ResponseComp.IsRespondingComponent(HitResult.Component))
				{
					HitResponseComponents.Add(ResponseComp);
					if (!ActiveResponseComponents.Contains(ResponseComp))
						ResponseComp.Illuminate(this);

					if (ResponseComp.bReflect)
					{
						Part.Normal = HitResult.ImpactNormal;
						Part.ReflectComponent = HitResult.Component;
						Part.LastComponentTransform = HitResult.Component.WorldTransform;

						Direction = Direction.GetReflectionVector(Part.Normal);
					}
				}
			}

			HitActors.Add(HitResult.Actor);
		}

		Location = Part.EndLocation;

		return Part;
	}

	private ASanctuaryDynamicLightRayPole SpawnPole(FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
	{
		if (!PoleActorClass.IsValid())
			return nullptr;

		auto PoleActor = Cast<ASanctuaryDynamicLightRayPole>(
			SpawnActor(PoleActorClass, Location, Rotation, bDeferredSpawn = true)
		);

		PoleActor.MakeNetworked(this, n"PoleActor", IdentifierInt);
		IdentifierInt++;
		FinishSpawningActor(PoleActor);

		return PoleActor;
	}

	private ASanctuaryDynamicLightRayPerchSpline SpawnPerchSpline(FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator)
	{
		if (!PerchSplineClass.IsValid())
			return nullptr;

		auto PerchSpline = Cast<ASanctuaryDynamicLightRayPerchSpline>(
			SpawnActor(PerchSplineClass, Location, Rotation, bDeferredSpawn = true)
		);

		if (bOverridePerchSplineActivationRange)
			PerchSpline.ActivationRange = PerchSplineActivationRange;

		if (bCrumbPerchRelativeToPerchSpline)
			PerchSpline.bCrumbRelativeToSpline = true;

		if (bOverridePerchSplineMaximumVerticalJumpToAngle)
		{
			PerchSpline.PerchSplineMio.MaximumVerticalJumpToAngle = PerchSplineMaximumVerticalJumpToAngle;
			PerchSpline.PerchSplineZoe.MaximumVerticalJumpToAngle = PerchSplineMaximumVerticalJumpToAngle;
		}

		PerchSpline.MakeNetworked(this, n"PerchSpline", IdentifierInt);
		IdentifierInt++;
		FinishSpawningActor(PerchSpline);

		return PerchSpline;
	}

	private bool NeedsRecalculation() const
	{
		if (Parts.Num() == 0)
			return true;

		if (!SourceComponent.WorldTransform.EqualsNoScale(LastSourceTransform))
			return true;

		for (int i = 0; i < Parts.Num(); ++i)
		{
			const auto& Part = Parts[i];
			if (Part.HasComponentMoved())
				return true;
		}

		return false;
	}
}

class USanctuaryDynamicLightRayMeshAudioComponent : USanctuaryLightMeshAudioComponent
{
	ASanctuaryDynamicLightRay LightRay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightRay = Cast<ASanctuaryDynamicLightRay>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void GetLightMeshAudioPositions(TArray<FAkSoundPosition>& outPositions)
	{
		outPositions.Empty();

		TArray<FSanctuaryLightRayPart> Parts;
		LightRay.GetLightRayParts(Parts);

		if(Parts.Num() == 0)
			return;

		for(auto Player : Game::GetPlayers())
		{
			if(!TrackPlayer[Player])
				continue;

			FVector ClosestPlayerPos;
			float ClosestPlayerDistSqrd = MAX_flt;

			for(auto Part : Parts)
			{				
				FVector LinePos = Math::ClosestPointOnLine(Part.StartLocation, Part.EndLocation, Player.ActorLocation);
				auto PartDistSqrd = LinePos.DistSquared(Player.ActorLocation);

				if(PartDistSqrd < ClosestPlayerDistSqrd)
				{
					ClosestPlayerDistSqrd = PartDistSqrd;
					ClosestPlayerPos = LinePos;
				}
			}

			outPositions.Add(FAkSoundPosition(ClosestPlayerPos));
		}		
	}
}