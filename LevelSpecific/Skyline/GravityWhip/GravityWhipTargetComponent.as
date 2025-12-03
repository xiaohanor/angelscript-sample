struct FGravityWhipPointArray
{
	TArray<FVector> Points;
}

enum EGravityWhipParentSelect
{
	None,
	Parent,
	AllParents
}

struct FGravityWhipTargetAudioData
{
	const FString GravityWhipTargetMakeUpGainRtpc = "Rtpc_World_Skyline_Shared_Interactable_GravityWhip_Target_MakeUpGain"; 
	const FString GravityWhipTargetVoiceVolumeRtpc = "Rtpc_World_Skyline_Shared_Interactable_GravityWhip_Target_VoiceVolume";
	const FString GravityWhipTargetPitchRtpc = "Rtpc_World_Skyline_Shared_Interactable_GravityWhip_Target_Pitch";

	// Is this a whip target that is tracked as an audio object?
	UPROPERTY(EditAnywhere)
	bool bAudioObject = false;

	UPROPERTY(Meta = (EditCondition = bAudioObject))
	UHazeAudioEvent StartGrabEvent = nullptr;

	UPROPERTY(Meta = (EditCondition = bAudioObject))
	UHazeAudioEvent StopGrabEvent = nullptr;

	UPROPERTY(Meta = (EditCondition = bAudioObject))
	UHazeAudioEvent ThrowEvent = nullptr;

	UPROPERTY(Meta = (EditCondition = bAudioObject))
	UHazeAudioEvent ImpactEvent = nullptr;

	UPROPERTY(Meta = (EditCondition = bAudioObject))
	float AttenuationScaling = 1000.0;

	UPROPERTY(Meta = (DisplayName = "Rtpc_World_Skyline_Shared_Interactable_GravityWhip_Target_MakeUpGain", EditCondition = bAudioObject))
	float MakeUpGain = 1.0;

	UPROPERTY(Meta = (DisplayName = "Rtpc_World_Skyline_Shared_Interactable_GravityWhip_Target_VoiceVolume", EditCondition = bAudioObject))
	float VoiceVolume = 1.0;

	UPROPERTY(Meta = (DisplayName = "Rtpc_World_Skyline_Shared_Interactable_GravityWhip_Target_Pitch", EditCondition = bAudioObject))
	float Pitch = 1.0;	
}

class UGravityWhipTargetComponent : UTargetableComponent
{
	default TargetableCategory = GravityWhip::Grab::TargetableCategory;
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	
	// Maximum distance from which we consider this targetable.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	float MaximumDistance = 2000.0;

	// Maximum angular bend from aim from which we consider this targetable.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	float MaximumAngle = 25.0;

	// Multiplies the scoring by factor, making this more or less likely to be selected.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	float ScoreMultiplier = 1.0;

	// How far to draw the visible widget and outlines from.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	float VisibleDistance = 4000.0;

	// Shape of the auto-targeted area
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	FHazeShapeSettings TargetShape;

	// Shape of the auto-targeted area
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	FVector TargetShapeOffset;

	// If set, the target is invisible, and will not show any widget or outline for targeting
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Targetable")
	bool bInvisibleTarget = false;

	UPROPERTY(EditInstanceOnly, Category = "Targetable")
	bool bCombatTarget = false;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FGravityWhipTargetAudioData AudioData;

	FVector PendingForce;
	FVector PrevPendingForce;

	private TMap<UPrimitiveComponent, FGravityWhipPointArray> PrimitivePoints;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// TEMP (probably): Whippable primitives cannot block WeaponTraceZoe, literally all whippable meshes which will be painful to do individually
/*
		TArray<UPrimitiveComponent> Primitives;
		CollectChildPrimitives(Primitives, Owner, Owner.RootComponent);
		CollectParentPrimitives(Primitives, Owner, true);

		for (auto Primitive : Primitives)
		{
			if (Primitive.IsCollisionEnabled())
			{
				Primitive.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Ignore);
			}
		}
*/
	}

	FVector ConsumeForce()
	{
		FVector Force = PendingForce;
		PrevPendingForce = PendingForce;
		PendingForce = FVector::ZeroVector;
		return Force;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		return true;
	}

	private bool GetRelativePointFromTrace(UPrimitiveComponent Primitive, FVector& Point, int TraceAttempts = 32, bool TraceComplex = true)
	{
		if (Primitive == nullptr || TraceAttempts <= 0)
			return false;

		for (int j = 0; j < TraceAttempts; ++j)
		{
			FVector Offset = Math::GetRandomPointInSphere() * Primitive.BoundsRadius * 2.0;

			FName BoneName;
			FVector ImpactPoint, ImpactNormal;
			FHitResult HitResult;
			Primitive.LineTraceComponent(
				Primitive.BoundsOrigin + Offset,
				Primitive.BoundsOrigin - Offset,
				TraceComplex,
				false,
				false,
				ImpactPoint,
				ImpactNormal,
				BoneName,
				HitResult
			);

			if (HitResult.Time > KINDA_SMALL_NUMBER && HitResult.Time < 1.0 - KINDA_SMALL_NUMBER)
			{
				Point = Primitive.WorldTransform.InverseTransformPosition(HitResult.ImpactPoint);
				return true;
			}
		}

		return false;
	}

	private void CollectParentPrimitives(TArray<UPrimitiveComponent>& Primitives, AActor FromActor, bool bIncludeAscendants)
	{
		if (FromActor == nullptr)
			return;

		auto Parent = FromActor.AttachParentActor;
		if (Parent == nullptr)
			return;

		if (!bIncludeAscendants)
		{
			CollectChildPrimitives(Primitives, Parent, Parent.RootComponent);
			return;
		}

		while (Parent != nullptr)
		{
			CollectChildPrimitives(Primitives, Parent, Parent.RootComponent);
			Parent = Parent.AttachParentActor;
		}
	}

	private void CollectChildPrimitives(TArray<UPrimitiveComponent>& Primitives, AActor Actor, USceneComponent FromComponent)
	{
		if (Actor == nullptr)
			return;

		auto Parent = FromComponent;
		if (FromComponent == nullptr)
			Parent = Actor.RootComponent;

		TArray<USceneComponent> Children;
		Parent.GetChildrenComponents(true, Children);

		for (int i = 0; i < Children.Num(); ++i)
		{
			auto Primitive = Cast<UPrimitiveComponent>(Children[i]);
			if (Primitive == nullptr)
				continue;
			
			Primitives.AddUnique(Primitive);
		}
	}

	private void CollectReferencedComponents(TArray<UPrimitiveComponent>& Primitives, TArray<FComponentReference> ComponentReferences)
	{
		for (const auto& ComponentReference : ComponentReferences)
		{
			auto Component = ComponentReference.GetComponent(Owner);
			if (Component == nullptr)
				continue;

			auto Primitive = Cast<UPrimitiveComponent>(Component);
			if (Primitive == nullptr)
				continue;

			Primitives.AddUnique(Primitive);
		}
	}
}

#if EDITOR
class UGravityWhipTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityWhipTargetComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto Component = Cast<UGravityWhipTargetComponent>(InComponent);
		if (Component == nullptr)
			return;

		if (!Component.TargetShape.IsZeroSize())
		{
			switch (Component.TargetShape.Type)
			{
				case EHazeShapeType::Box:
					DrawWireBox(
						Component.WorldTransform.TransformPosition(Component.TargetShapeOffset),
						Component.TargetShape.BoxExtents,
						Component.ComponentQuat,
						FLinearColor::Green,
						2.0
					);
				break;
				case EHazeShapeType::Sphere:
					DrawWireSphere(
						Component.WorldTransform.TransformPosition(Component.TargetShapeOffset),
						Component.TargetShape.SphereRadius,
						FLinearColor::Green,
					);
				break;
				case EHazeShapeType::Capsule:
					DrawWireCapsule(
						Component.WorldTransform.TransformPosition(Component.TargetShapeOffset),
						Component.WorldRotation,
						FLinearColor::Green,
						Component.TargetShape.CapsuleRadius,
						Component.TargetShape.CapsuleHalfHeight,
						16, 2.0
					);
				break;
				case EHazeShapeType::None:
				break;
			}
		}
	}
}
#endif