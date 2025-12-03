class USanctuaryBossZoeStatueFragmentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryBossZoeStatueFragmentVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto Fragment = Cast<ASanctuaryBossZoeStatueFragment>(InComponent.Owner);
	}
}

class USanctuaryBossZoeStatueFragmentVisualizerComponent : UHazeEditorRenderedComponent
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MarkRenderStateDirty();		
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		auto Fragment = Cast<ASanctuaryBossZoeStatueFragment>(Owner);
		if (Fragment == nullptr)
			return;

		float Thickness = 5.0;
		FLinearColor Color = FLinearColor::Green;

		if (Fragment.UseFragmentStartTransform == nullptr)
			return;

		DrawArrow(Fragment.ActorLocation, Fragment.UseFragmentStartTransform.ActorLocation, Color, 10.0, Thickness);
#endif
	}
}

event void FSanctuaryBossZoeStatueFragmentSignature();
class ASanctuaryBossZoeStatueFragment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingSceneComp;

	UPROPERTY(DefaultComponent, Attach = FloatingSceneComp)
	UDarkPortalTargetComponent DarkPortalTargetComp;
	default DarkPortalTargetComp.MaximumDistance = 10000.0; 

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;
//	default DarkPortalResponseComp.bAllowMultiComponentGrab = true;

	UPROPERTY(DefaultComponent)
	USanctuaryBossZoeStatueFragmentVisualizerComponent VisualizerComp;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossZoeStatueFragment UseFragmentStartTransform;

	FTransform StartRelativeTransform;
	FTransform EndRelativeTransform;
	FHazeAcceleratedTransform AcceleratedTransform;
	FHazeAcceleratedFloat AcceleratedFloat;

	UPROPERTY(EditAnywhere)
	UMaterialInterface EmissiveMaterial;

	UPROPERTY(EditAnywhere)
	FName MaterialParameter = n"Emissive";

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UPROPERTY(EditAnywhere)
	float Duration = 8.0;

	UPROPERTY(EditAnywhere)
	float ThrustAcceleration = 1.0;

	UPROPERTY(EditAnywhere)
	float ThrustAccelerationMultiplier = 0.5;

	bool bEndReached = false;

	bool bGrabbed = false;

	ADarkPortalActor GrabbingPortal;

	UPROPERTY()
	FSanctuaryBossZoeStatueFragmentSignature OnEndReached;

	UPROPERTY()
	FSanctuaryBossZoeStatueFragmentSignature OnReverseFromEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = Material::CreateDynamicMaterialInstance(this, EmissiveMaterial);

		if (UseFragmentStartTransform != nullptr)
		{
			UseFragmentStartTransform.AddActorDisable(this);
			StartRelativeTransform = UseFragmentStartTransform.ActorTransform.GetRelativeTransform(ActorTransform);
		}

		EndRelativeTransform = ActorRelativeTransform;
		StartRelativeTransform *= EndRelativeTransform;
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");

		ActorRelativeTransform = StartRelativeTransform;
		AcceleratedTransform.SnapTo(StartRelativeTransform);

		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTransform TargetTransform = (bGrabbed ? EndRelativeTransform : StartRelativeTransform);
	
		if (bGrabbed || bEndReached)
			AcceleratedFloat.ThrustTo(1.0, ThrustAcceleration * ThrustAccelerationMultiplier, DeltaSeconds, 1.0);
		else
			AcceleratedFloat.AccelerateTo(0.0, Duration, DeltaSeconds);

		if (!bEndReached && Math::IsNearlyEqual(AcceleratedFloat.Value, 1.0) && HasControl())
		{
			CrumbReachedEnd();
		}

		if (bEndReached && !Math::IsNearlyEqual(AcceleratedFloat.Value, 1.0) && HasControl())
		{
			CrumbReverseFromEnd();
		}

//		AcceleratedTransform.AccelerateTo(TargetTransform, Duration, DeltaSeconds);
//		ActorRelativeTransform = AcceleratedTransform.Value;

		ActorRelativeTransform = LerpTransform(StartRelativeTransform, EndRelativeTransform, AcceleratedFloat.Value);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReachedEnd()
	{
		bEndReached = true;

		OnEndReached.Broadcast();
		BP_OnEndReached();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReverseFromEnd()
	{
		bEndReached = false;			

		OnReverseFromEnd.Broadcast();
		BP_OnReverseFromEnd();
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		GrabbingPortal = Portal;
//		Debug::DrawDebugSphere(ActorLocation, 200.0, 12, FLinearColor::Green, 5.0, 1.0);
	}

	void SnapAndFreezeAtEnd()
	{
		SetActorTickEnabled(false);
		ActorRelativeTransform = EndRelativeTransform;
		FloatingSceneComp.ComponentTickEnabled = false;
		FloatingSceneComp.WorldTransform = ActorTransform;
		DarkPortalTargetComp.Disable(this);

		// Force Release Grabs - Should be enough disabling the target comp?
		auto Grabs = GrabbingPortal.Grabs;
		for (auto Grab : Grabs)
		{
			auto TargetComponents = Grab.TargetComponents;
			for (auto TargetComponent: TargetComponents)
				GrabbingPortal.Release(TargetComponent);
		}
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform Transform;
		Transform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		Transform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		Transform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);
		
		return Transform;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnEndReached() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnReverseFromEnd() {}
}

event void FSanctuaryBossZoeStatueSignature();

class ASanctuaryBossZoeStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalPlacementArea;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(BlueprintReadOnly)
	ADarkPortalActor AttachedPortal;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector MaskLocation;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryBossZoeStatueFragment> Fragments;

	UPROPERTY()
	FSanctuaryBossZoeStatueSignature OnStatueBeginAssemble();

	UPROPERTY()
	FSanctuaryBossZoeStatueSignature OnStatueCompleted();

	UPROPERTY(EditAnywhere)
	UMaterialParameterCollection GlobalParametersVFX;

	UPROPERTY(EditInstanceOnly)
	AActor GrabActorWhenCompleted;

	bool bIsCompleted = false;
	bool bAssebleStarted = false;

	UPROPERTY()
	bool bInterruptedAssemble = false;

	FHazeAcceleratedFloat SphereMaskRadius;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MaskLocation = ActorTransform.TransformPositionNoScale(MaskLocation);

		DarkPortalResponseComp.OnAttached.AddUFunction(this, n"HandleDarkPortalAttached");
		DarkPortalResponseComp.OnDetached.AddUFunction(this, n"HandleDarkPortalDetached");

		for (auto Fragment : Fragments)
		{
			Fragment.OnEndReached.AddUFunction(this, n"HandleFragmentInPlace");
			Fragment.DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleFragmentGrabbed");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (AttachedPortal != nullptr)
		{
			PrintToScreen("Grabs: " + AttachedPortal.Grabs.Num(), 0.0, FLinearColor::Green);
		}

		if (bIsCompleted)
		{
			SphereMaskRadius.AccelerateTo(1500.0, 4.0, DeltaSeconds);
//			Debug::DrawDebugSphere(MaskLocation, SphereMaskRadius.Value, 24, FLinearColor::Red, 10.0, 0.0);
			Material::SetVectorParameterValue(GlobalParametersVFX, n"SphereMaskDarkness", FLinearColor(MaskLocation.X, MaskLocation.Y, MaskLocation.Z, 1.0));
			Material::SetScalarParameterValue(GlobalParametersVFX, n"RadiusDarkness", SphereMaskRadius.Value);
		}
	}	

	UFUNCTION()
	private void HandleFragmentGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (!bInterruptedAssemble)
			return;

		if (bAssebleStarted)
			return;

		Timer::SetTimer(this, n"DetachPortal", 2.0);

		OnStatueBeginAssemble.Broadcast();

		bAssebleStarted = true;
	}

	UFUNCTION()
	private void HandleFragmentInPlace()
	{
		if (!bIsCompleted && IsStatueCompleted())
		{
			bIsCompleted = true;
			OnStatueCompleted.Broadcast();

			for (auto Fragment : Fragments)
				Fragment.SnapAndFreezeAtEnd();

//			AttachedPortal.DetachPortal();
//			PortalPlacementArea.RemoveTag(ComponentTags::DarkPortalPlaceable);

			/*
			if (GrabActorWhenCompleted != nullptr)
			{
				auto TargetComp = UDarkPortalTargetComponent::Get(GrabActorWhenCompleted);
				if (TargetComp != nullptr)
					AttachedPortal.Grab(TargetComp);
			}
			*/
		}
	}

	UFUNCTION()
	private void DetachPortal()
	{
		if (IsValid(AttachedPortal))
			AttachedPortal.DetachPortal();
	}

	UFUNCTION()
	private void HandleDarkPortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		AttachedPortal = Portal;
		AttachedPortal.bForcedGrabs = true;
	}

	UFUNCTION()
	private void HandleDarkPortalDetached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		AttachedPortal.bForcedGrabs = false;
		AttachedPortal = nullptr;
	}

	bool IsStatueCompleted()
	{
		for (auto Fragment : Fragments)
		{
			if (!Fragment.bEndReached)
				return false;
		}
	
		return true;
	}
};